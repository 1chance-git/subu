//
//  SmartSuggestionEngine.swift
//  Subu
//
//  Rule-based "smart suggestions" derived from data the user has already
//  entered (category, cancellation difficulty, status), refined within each
//  rule's tier by CancelRiskPredictor's on-device cancel-risk score where
//  applicable. No network calls, no third-party frameworks — everything
//  runs on-device over the existing SwiftData model.
//

import SwiftUI
import SwiftData

// MARK: - SmartSuggestion

struct SmartSuggestion: Identifiable {
    enum Action {
        case openCancelAssistant(Subscription)
        case viewDetail(Subscription)
        case openDiscover
    }

    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let message: String
    let action: Action

    /// Lower sorts first. Whole numbers are broad tiers (most actionable
    /// rule types first); the fractional part is the predicted cancel-risk
    /// score nudging order within a tier, when available.
    let priority: Double
}

// MARK: - SmartSuggestionEngine

enum SmartSuggestionEngine {
    /// Generates suggestions from the current subscription list, sorted by
    /// priority (most actionable first) and capped to a reasonable count so
    /// the dashboard never feels noisy.
    /// `useRiskScore` gates the CoreML cancel-risk refinement behind the AI
    /// Insights unlock (bundled with Remove Ads) — when `false`, suggestions
    /// still work, just ordered by the plain rule tiers rather than a
    /// personalized risk score.
    static func generate(from subscriptions: [Subscription], context: ModelContext, useRiskScore: Bool = true, limit: Int = 4) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []

        if !subscriptions.isEmpty {
            suggestions += markedForCancellation(subscriptions, context: context, useRiskScore: useRiskScore)
            suggestions += hardToCancel(subscriptions, context: context, useRiskScore: useRiskScore)
            suggestions += overlappingCategories(subscriptions)
            suggestions += longUnreviewed(subscriptions)
        }
        suggestions += popularNotYetAdded(subscriptions)

        return Array(suggestions.sorted { $0.priority < $1.priority }.prefix(limit))
    }

    // MARK: Rules

    /// Within a tier, higher predicted cancel-risk sorts first. Falls back
    /// to the plain tier value if no prediction is available or the caller
    /// hasn't unlocked AI Insights.
    private static func riskAdjustedPriority(tier: Double, subscription: Subscription, context: ModelContext, useRiskScore: Bool) -> Double {
        guard useRiskScore, let risk = CancelRiskPredictor.risk(for: subscription, using: context) else { return tier }
        return tier - risk * 0.9
    }

    /// Subscriptions the user has already decided to cancel — the most
    /// directly actionable suggestion, since the decision is already made.
    private static func markedForCancellation(_ subscriptions: [Subscription], context: ModelContext, useRiskScore: Bool) -> [SmartSuggestion] {
        subscriptions
            .filter { $0.status == .cancel }
            .map { subscription in
                SmartSuggestion(
                    icon: "xmark.circle.fill",
                    tint: .red,
                    title: "You marked \(subscription.name) to cancel",
                    message: "Ready to go through with it? The Cancel Assistant can walk you through it.",
                    action: .openCancelAssistant(subscription),
                    priority: riskAdjustedPriority(tier: -1, subscription: subscription, context: context, useRiskScore: useRiskScore)
                )
            }
    }

    /// Subscriptions the user has flagged as hard to cancel — worth starting
    /// the process early rather than putting it off.
    private static func hardToCancel(_ subscriptions: [Subscription], context: ModelContext, useRiskScore: Bool) -> [SmartSuggestion] {
        subscriptions
            .filter { $0.cancellationDifficulty == .hard && $0.status != .cancel }
            .map { subscription in
                SmartSuggestion(
                    icon: "exclamationmark.triangle.fill",
                    tint: .red,
                    title: "\(subscription.name) is hard to cancel",
                    message: "If you're thinking about dropping it, it's worth starting the process early.",
                    action: .openCancelAssistant(subscription),
                    priority: riskAdjustedPriority(tier: 0, subscription: subscription, context: context, useRiskScore: useRiskScore)
                )
            }
    }

    /// Two or more active subscriptions in the same category (e.g. multiple
    /// streaming services) — a common place to trim overlap.
    private static func overlappingCategories(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        let grouped = Dictionary(grouping: subscriptions, by: { $0.category })
        return grouped.compactMap { category, items -> SmartSuggestion? in
            guard category != .other, items.count > 1 else { return nil }
            let names = items.map(\.name).joined(separator: ", ")
            return SmartSuggestion(
                icon: category.symbolName,
                tint: category.tintColor,
                title: "\(items.count) \(category.rawValue.lowercased()) subscriptions",
                message: "\(names). Worth consolidating?",
                action: .viewDetail(items[0]),
                priority: 2
            )
        }
    }

    /// Subscriptions added a long time ago — a gentle nudge to reconsider
    /// something that's likely been running on autopilot.
    private static func longUnreviewed(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -180, to: Date()) ?? .distantPast

        return subscriptions
            .filter { $0.createdDate < cutoff }
            .sorted { $0.createdDate < $1.createdDate }
            .prefix(1)
            .map { subscription in
                let months = calendar.dateComponents([.month], from: subscription.createdDate, to: Date()).month ?? 6
                return SmartSuggestion(
                    icon: "clock.arrow.circlepath",
                    tint: .gray,
                    title: "\(subscription.name) has been running for \(months) months",
                    message: "You added this on \(subscription.createdDate.formatted(date: .abbreviated, time: .omitted)). Still using it?",
                    action: .viewDetail(subscription),
                    priority: 4
                )
            }
    }

    /// Popular/trending catalog items the user hasn't added yet, based on a
    /// static curated ranking (`SubscriptionCatalogItem.popularityRank`) —
    /// not usage telemetry, Subu collects none. Independent of the
    /// cancel-risk score since it's about subscriptions the user doesn't
    /// have; kept at a low-urgency tier so it never crowds out actionable
    /// cancel-risk suggestions.
    private static func popularNotYetAdded(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        let addedNames = Set(subscriptions.map { $0.name.lowercased() })
        guard let item = SubscriptionCatalog.popular.first(where: { !addedNames.contains($0.name.lowercased()) }) else {
            return []
        }
        return [
            SmartSuggestion(
                icon: "star.fill",
                tint: .yellow,
                title: "\(item.name) is popular",
                message: "It's one of the most commonly tracked \(item.section.rawValue.lowercased()) subscriptions — worth a look in Discover?",
                action: .openDiscover,
                priority: 5
            )
        ]
    }
}
