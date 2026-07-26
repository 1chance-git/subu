//
//  DashboardView.swift
//  SubZero
//
//  The primary dashboard: Keep/Review/Cancel status summary and chart,
//  smart suggestions, and subscriptions grouped by status. Tapping a status
//  summary card scrolls to that group. Also offers CSV/PDF export of the
//  full subscription list for tracking in Numbers or Pages.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRemoveAds = false

    private var suggestions: [SmartSuggestion] {
        SmartSuggestionEngine.generate(from: subscriptions, context: modelContext, useRiskScore: storeManager.isAdsRemoved)
    }

    private func subscriptions(for status: SubscriptionStatus) -> [Subscription] {
        subscriptions.filter { $0.status == status }
    }

    private var statusCounts: [(status: SubscriptionStatus, count: Int)] {
        SubscriptionStatus.allCases.map { ($0, subscriptions(for: $0).count) }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        statusSummaryRow(proxy: proxy)
                        if storeManager.isAdsRemoved {
                            if let insight = topAIInsight {
                                aiInsightShowcaseCard(insight)
                            }
                        } else {
                            aiInsightsUpgradeCard
                        }
                        if !subscriptions.isEmpty {
                            overviewChartSection
                        }
                        if !suggestions.isEmpty {
                            smartSuggestionsSection
                        }
                        groupedSubscriptionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("My Subscriptions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    exportMenu
                }
            }
            .sheet(isPresented: $showRemoveAds) {
                RemoveAdsView(storeManager: storeManager)
            }
        }
    }

    // MARK: AI Insights Upgrade

    private var aiInsightsUpgradeCard: some View {
        Button {
            showRemoveAds = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock AI Insights")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("See predicted cancel-risk scores and remove ads — one-time purchase.")
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
            .cardBackground(cornerRadius: 16)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unlock AI Insights. See predicted cancel-risk scores and remove ads. One-time purchase.")
    }

    /// The single most-worth-your-attention subscription, by predicted
    /// cancel risk. This is the paid feature's showcase moment — a
    /// dedicated card, not just the per-row badges.
    private var topAIInsight: (subscription: Subscription, insight: CancelRiskPredictor.CancelRiskInsight)? {
        subscriptions
            .compactMap { subscription in
                CancelRiskPredictor.insight(for: subscription, using: modelContext).map { (subscription, $0) }
            }
            .max { $0.insight.score < $1.insight.score }
    }

    private func aiInsightShowcaseCard(_ item: (subscription: Subscription, insight: CancelRiskPredictor.CancelRiskInsight)) -> some View {
        NavigationLink {
            SubscriptionDetailView(subscription: item.subscription)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Label("AI Insight", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .labelStyle(.titleOnly)
                    Text(item.subscription.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(item.insight.summary)
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
            .cardBackground(cornerRadius: 16)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Insight. \(item.subscription.name): \(item.insight.summary)")
    }

    // MARK: Export

    @ViewBuilder
    private var exportMenu: some View {
        Menu {
            if let csvURL = try? SubscriptionReportExporter.writeCSVToTempFile(for: subscriptions) {
                ShareLink(item: csvURL) {
                    Label("Export CSV for Numbers", systemImage: "tablecells")
                }
            }
            if let pdfURL = try? SubscriptionReportExporter.writePDFToTempFile(for: subscriptions) {
                ShareLink(item: pdfURL) {
                    Label("Export PDF Report for Pages", systemImage: "doc.richtext")
                }
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(subscriptions.isEmpty)
    }

    // MARK: Overview Chart

    private var overviewChartSummary: String {
        statusCounts
            .map { "\($0.count) \($0.status.rawValue)" }
            .joined(separator: ", ")
    }

    private var overviewChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Chart(statusCounts, id: \.status) { entry in
                SectorMark(
                    angle: .value("Count", entry.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(entry.status.tintColor)
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .frame(height: 180)
            .overlay {
                VStack(spacing: 2) {
                    Text("\(subscriptions.count)")
                        .font(.title2.weight(.bold))
                    Text("Subscriptions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(subscriptions.count) subscriptions total: \(overviewChartSummary)")

            HStack(spacing: 16) {
                ForEach(statusCounts, id: \.status) { entry in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.status.tintColor)
                            .frame(width: 8, height: 8)
                        Text("\(entry.status.rawValue) \(entry.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .accessibilityHidden(true)
        }
        .padding(16)
        .cardBackground(cornerRadius: 18)
    }

    // MARK: Status Summary

    private func statusSummaryRow(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 12) {
            ForEach(SubscriptionStatus.allCases) { status in
                let count = subscriptions(for: status).count
                StatusSummaryCard(status: status, count: count) {
                    guard count > 0 else { return }
                    withAnimation(.snappy) {
                        proxy.scrollTo(status, anchor: .top)
                    }
                }
            }
        }
    }

    // MARK: Smart Suggestions

    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Smart Suggestions", systemImage: "sparkles")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 10) {
                ForEach(suggestions) { suggestion in
                    NavigationLink {
                        destinationView(for: suggestion.action)
                    } label: {
                        SmartSuggestionRow(suggestion: suggestion)
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private func destinationView(for action: SmartSuggestion.Action) -> some View {
        switch action {
        case .openCancelAssistant(let subscription):
            CancelAssistantView(preselectedSubscription: subscription)
        case .viewDetail(let subscription):
            SubscriptionDetailView(subscription: subscription)
        case .openDiscover:
            DiscoverSubscriptionsView()
        }
    }

    // MARK: Grouped Subscription List

    private var groupedSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if subscriptions.isEmpty {
                emptyState
            } else {
                ForEach(SubscriptionStatus.allCases) { status in
                    let items = subscriptions(for: status)
                    if !items.isEmpty {
                        statusGroup(status: status, items: items)
                            .id(status)
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(.snappy, value: subscriptions.map(\.status))
    }

    private func statusGroup(status: SubscriptionStatus, items: [Subscription]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(status.tintColor)
                    .frame(width: 8, height: 8)
                Text(status.rawValue.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text("\(items.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(items) { subscription in
                    NavigationLink {
                        SubscriptionDetailView(subscription: subscription)
                    } label: {
                        SubscriptionRow(subscription: subscription)
                    }
                    .buttonStyle(CardPressStyle())
                    .contextMenu {
                        statusMenu(for: subscription)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statusMenu(for subscription: Subscription) -> some View {
        ForEach(SubscriptionStatus.allCases) { status in
            Button {
                withAnimation(.snappy) {
                    subscription.status = status
                }
            } label: {
                Label("Mark as \(status.rawValue)", systemImage: status.symbolName)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Nothing here yet")
                .font(.headline)
            Text("Head to Discover to find and organize your subscriptions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - StatusSummaryCard

private struct StatusSummaryCard: View {
    let status: SubscriptionStatus
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(status.tintColor)
                        .frame(width: 10, height: 10)
                    Text(status.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(count)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: count)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .cardBackground(cornerRadius: 18)
        }
        .buttonStyle(CardPressStyle())
        .opacity(count == 0 ? 0.55 : 1)
        .animation(.snappy, value: count == 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.rawValue): \(count) subscriptions")
        .accessibilityHint(count > 0 ? "Scrolls to this group" : "")
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
        .cardBackground(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(suggestion.title). \(suggestion.message)")
    }
}

// MARK: - SubscriptionRow

private struct SubscriptionRow: View {
    let subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager

    /// On-device cancel-risk prediction (0...1), gated behind the AI
    /// Insights unlock (bundled with Remove Ads), or nil if unavailable.
    private var risk: Double? {
        guard storeManager.isAdsRemoved else { return nil }
        return CancelRiskPredictor.risk(for: subscription, using: modelContext)
    }

    private func riskColor(_ risk: Double) -> Color {
        switch risk {
        case 0.66...: return .red
        case 0.33..<0.66: return .orange
        default: return .green
        }
    }

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

            if let risk {
                Text("\(Int(risk * 100))%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(riskColor(risk))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(riskColor(risk).opacity(0.15), in: Capsule())
            }

            Image(systemName: subscription.cancellationDifficulty.symbolName)
                .foregroundStyle(subscription.cancellationDifficulty.tintColor)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .cardBackground(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(subscription.name), \(subscription.provider), cancellation difficulty \(subscription.cancellationDifficulty.rawValue)"
            + (risk.map { ", \(Int($0 * 100)) percent cancel risk" } ?? "")
        )
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewSampleData.container)
        .environment(StoreManager())
}

#Preview("Empty State") {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .environment(StoreManager())
}
