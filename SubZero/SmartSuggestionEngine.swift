//
//  SmartSuggestionEngine.swift
//  SubZero
//
//  Rule-based "smart suggestions" derived entirely from data the user has
//  already entered (cost, category, renewal date, cancellation difficulty).
//  No usage tracking, network calls, or third-party frameworks — everything
//  runs on-device over the existing SwiftData model.
//

import SwiftUI

// MARK: - SmartSuggestion

struct SmartSuggestion: Identifiable {
    enum Action {
        case openCancelAssistant(Subscription)
        case viewDetail(Subscription)
    }

    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let message: String
    let action: Action

    /// Lower sorts first — used to surface the most actionable suggestions.
    let priority: Int
}

// MARK: - SmartSuggestionEngine

enum SmartSuggestionEngine {
    /// Generates suggestions from the current subscription list, sorted by
    /// priority (most actionable first) and capped to a reasonable count so
    /// the dashboard never feels noisy.
    static func generate(from subscriptions: [Subscription], limit: Int = 4) -> [SmartSuggestion] {
        guard !subscriptions.isEmpty else { return [] }

        var suggestions: [SmartSuggestion] = []

        suggestions += hardToCancelRenewingSoon(subscriptions)
        suggestions += yearlyRenewingSoon(subscriptions)
        suggestions += overlappingCategories(subscriptions)
        suggestions += costOutlier(subscriptions)
        suggestions += longUnreviewed(subscriptions)

        return Array(suggestions.sorted { $0.priority < $1.priority }.prefix(limit))
    }

    // MARK: Rules

    /// Hard-to-cancel subscriptions renewing within a week — the window to
    /// act before being charged again is closing fast.
    private static func hardToCancelRenewingSoon(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        subscriptions
            .filter { $0.cancellationDifficulty == .hard && $0.daysUntilRenewal <= 7 }
            .map { subscription in
                SmartSuggestion(
                    icon: "exclamationmark.triangle.fill",
                    tint: .red,
                    title: "\(subscription.name) renews soon and is hard to cancel",
                    message: "Renews in \(dayPhrase(subscription.daysUntilRenewal)). Start the cancellation now if you don't plan to keep it.",
                    action: .openCancelAssistant(subscription),
                    priority: 0
                )
            }
    }

    /// Yearly subscriptions renewing soon — a bigger lump sum than a monthly
    /// charge, so worth a reminder before it happens.
    private static func yearlyRenewingSoon(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        subscriptions
            .filter { $0.billingCycle == .yearly && $0.daysUntilRenewal <= 14 }
            .map { subscription in
                SmartSuggestion(
                    icon: "calendar.badge.exclamationmark",
                    tint: .orange,
                    title: "\(subscription.name) renews in \(dayPhrase(subscription.daysUntilRenewal))",
                    message: "This is a yearly plan at \(formattedAmount(subscription.monthlyCost)) — decide before you're charged.",
                    action: .viewDetail(subscription),
                    priority: 1
                )
            }
    }

    /// Two or more active subscriptions in the same category (e.g. multiple
    /// streaming services) — a common place to trim overlap.
    private static func overlappingCategories(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        let grouped = Dictionary(grouping: subscriptions, by: { $0.category })
        return grouped.compactMap { category, items -> SmartSuggestion? in
            guard category != .other, items.count > 1 else { return nil }
            let total = items.reduce(0) { $0 + $1.normalizedMonthlyCost }
            let names = items.map(\.name).joined(separator: ", ")
            return SmartSuggestion(
                icon: category.symbolName,
                tint: category.tintColor,
                title: "\(items.count) \(category.rawValue.lowercased()) subscriptions",
                message: "\(names) together cost \(formattedAmount(total))/mo. Worth consolidating?",
                action: .viewDetail(items.max { $0.normalizedMonthlyCost < $1.normalizedMonthlyCost } ?? items[0]),
                priority: 2
            )
        }
    }

    /// The subscription costing noticeably more than the average — only
    /// surfaced once there's enough data for "average" to mean something.
    private static func costOutlier(_ subscriptions: [Subscription]) -> [SmartSuggestion] {
        guard subscriptions.count >= 3 else { return [] }
        let average = subscriptions.reduce(0) { $0 + $1.normalizedMonthlyCost } / Double(subscriptions.count)
        guard average > 0,
              let priciest = subscriptions.max(by: { $0.normalizedMonthlyCost < $1.normalizedMonthlyCost }),
              priciest.normalizedMonthlyCost > average * 1.5
        else { return [] }

        return [
            SmartSuggestion(
                icon: "arrow.up.circle.fill",
                tint: .purple,
                title: "\(priciest.name) is your priciest subscription",
                message: "\(formattedAmount(priciest.normalizedMonthlyCost))/mo is well above your \(formattedAmount(average))/mo average. Worth a review?",
                action: .viewDetail(priciest),
                priority: 3
            )
        ]
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

    // MARK: Formatting

    private static func dayPhrase(_ days: Int) -> String {
        switch days {
        case ...0: return "today"
        case 1: return "1 day"
        default: return "\(days) days"
        }
    }

    private static func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
