//
//  DashboardView.swift
//  SubZero
//
//  The primary dashboard: monthly cash burn hero card, summary metrics,
//  and the full subscription list.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    private var monthlyCashBurn: Double {
        subscriptions.reduce(0) { $0 + $1.normalizedMonthlyCost }
    }

    private var mostExpensiveSubscription: Subscription? {
        subscriptions.max { $0.normalizedMonthlyCost < $1.normalizedMonthlyCost }
    }

    private var nextRenewal: Subscription? {
        subscriptions.min { $0.nextRenewalDate < $1.nextRenewalDate }
    }

    private var suggestions: [SmartSuggestion] {
        SmartSuggestionEngine.generate(from: subscriptions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    cashBurnCard
                    summaryMetricsGrid
                    if !suggestions.isEmpty {
                        smartSuggestionsSection
                    }
                    subscriptionListSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    // MARK: Smart Suggestions

    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Smart Suggestions", systemImage: "sparkles")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(suggestions) { suggestion in
                    NavigationLink {
                        destinationView(for: suggestion.action)
                    } label: {
                        SmartSuggestionRow(suggestion: suggestion)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for action: SmartSuggestion.Action) -> some View {
        switch action {
        case .openCancelAssistant(let subscription):
            CancelAssistantView(preselectedSubscription: subscription)
        case .viewDetail(let subscription):
            SubscriptionDetailView(subscription: subscription)
        }
    }

    // MARK: Cash Burn Card

    private var cashBurnCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Monthly Cash Burn", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(formattedAmount(monthlyCashBurn))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.snappy, value: monthlyCashBurn)

            Text("You spend this every month")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly cash burn, \(formattedAmount(monthlyCashBurn)). You spend this every month.")
    }

    // MARK: Summary Metrics

    private var summaryMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCard(
                title: "Subscriptions",
                value: "\(subscriptions.count)",
                systemImage: "square.stack.3d.up.fill",
                tint: .blue
            )
            MetricCard(
                title: "Monthly Total",
                value: formattedAmount(monthlyCashBurn),
                systemImage: "dollarsign.circle.fill",
                tint: .green
            )
            MetricCard(
                title: "Most Expensive",
                value: mostExpensiveSubscription?.name ?? "None",
                subtitle: mostExpensiveSubscription.map { formattedAmount($0.normalizedMonthlyCost) },
                systemImage: "arrow.up.circle.fill",
                tint: .orange
            )
            MetricCard(
                title: "Next Renewal",
                value: nextRenewal?.name ?? "None",
                subtitle: nextRenewal.map(renewalSubtitle),
                systemImage: "calendar.circle.fill",
                tint: .purple
            )
        }
    }

    private func renewalSubtitle(for subscription: Subscription) -> String {
        let days = subscription.daysUntilRenewal
        switch days {
        case ...0: return "Due today"
        case 1: return "In 1 day"
        default: return "In \(days) days"
        }
    }

    // MARK: Subscription List

    private var subscriptionListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Subscriptions")
                .font(.headline)

            if subscriptions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(subscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            SubscriptionRow(subscription: subscription)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No subscriptions yet")
                .font(.headline)
            Text("Add your first subscription to start tracking your monthly spend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - MetricCard

private struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(subtitle.map { ", \($0)" } ?? "")")
    }
}

// MARK: - SmartSuggestionRow

private struct SmartSuggestionRow: View {
    let suggestion: SmartSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(suggestion.tint.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: suggestion.icon)
                    .foregroundStyle(suggestion.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(suggestion.title). \(suggestion.message)")
    }
}

// MARK: - SubscriptionRow

private struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(subscription.category.tintColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: subscription.category.symbolName)
                    .foregroundStyle(subscription.category.tintColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(subscription.provider) · \(subscription.category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedCost + "/mo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(renewalText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subscription.name), \(subscription.provider), \(formattedCost) per month, renews \(renewalText)")
    }

    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: subscription.normalizedMonthlyCost)) ?? "$0.00"
    }

    private var renewalText: String {
        subscription.nextRenewalDate.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Empty State") {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
