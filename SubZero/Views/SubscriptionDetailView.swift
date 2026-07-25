//
//  SubscriptionDetailView.swift
//  SubZero
//
//  Detail screen for a tracked subscription: status, category, cancellation,
//  and notes.
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager

    private var aiInsight: CancelRiskPredictor.CancelRiskInsight? {
        guard storeManager.isAdsRemoved else { return nil }
        return CancelRiskPredictor.insight(for: subscription, using: modelContext)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let aiInsight {
                    aiInsightSection(aiInsight)
                }
                statusSection
                detailsSection
                cancellationSection
                notesSection
            }
            .padding()
        }
        .navigationTitle(subscription.name)
    }

    private func aiInsightSection(_ insight: CancelRiskPredictor.CancelRiskInsight) -> some View {
        DetailSection(title: "AI Insight") {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.accentColor)
                Text("\(Int(insight.score * 100))% cancel risk")
                    .font(.subheadline.weight(.semibold))
            }
            if !insight.reasons.isEmpty {
                let reasonText = insight.reasons.joined(separator: ", ")
                Text(reasonText.prefix(1).uppercased() + reasonText.dropFirst())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(subscription.category.tintColor.opacity(0.16))
                    .frame(width: 52, height: 52)
                Image(systemName: subscription.category.symbolName)
                    .font(.title3)
                    .foregroundStyle(subscription.category.tintColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.title3.weight(.bold))
                Text(subscription.provider)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .cardBackground(cornerRadius: 18)
    }

    private var statusSection: some View {
        DetailSection(title: "Status") {
            Picker("Status", selection: $subscription.status) {
                ForEach(SubscriptionStatus.allCases) { status in
                    Label(status.rawValue, systemImage: status.symbolName).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var detailsSection: some View {
        DetailSection(title: "Details") {
            DetailRow(label: "Category", value: subscription.category.rawValue)
        }
    }

    private var cancellationSection: some View {
        DetailSection(title: "Cancellation") {
            HStack {
                Label(subscription.cancellationDifficulty.rawValue, systemImage: subscription.cancellationDifficulty.symbolName)
                    .foregroundStyle(subscription.cancellationDifficulty.tintColor)
                Spacer()
            }

            if !subscription.cancellationInstructions.isEmpty {
                Text(subscription.cancellationInstructions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink {
                CancelAssistantView(preselectedSubscription: subscription)
            } label: {
                Label("Open Cancel Assistant", systemImage: "trash.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var notesSection: some View {
        DetailSection(title: "Notes") {
            Text(subscription.notes.isEmpty ? "No notes" : subscription.notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardBackground(cornerRadius: 18)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        SubscriptionDetailView(subscription: PreviewSampleData.netflix)
    }
    .modelContainer(PreviewSampleData.container)
    .environment(StoreManager())
}

#Preview("Adobe") {
    NavigationStack {
        SubscriptionDetailView(subscription: PreviewSampleData.adobe)
    }
    .modelContainer(PreviewSampleData.container)
    .environment(StoreManager())
}
