//
//  SubscriptionDetailView.swift
//  SubZero
//
//  Read-only detail screen for a tracked subscription.
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    let subscription: Subscription

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                billingSection
                cancellationSection
                notesSection
            }
            .padding()
        }
        .navigationTitle(subscription.name)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var billingSection: some View {
        DetailSection(title: "Billing") {
            DetailRow(label: "Cost", value: formattedAmount(subscription.monthlyCost))
            DetailRow(label: "Billing Cycle", value: subscription.billingCycle.rawValue)
            DetailRow(label: "Monthly Equivalent", value: formattedAmount(subscription.normalizedMonthlyCost))
            DetailRow(label: "Next Renewal", value: subscription.nextRenewalDate.formatted(date: .abbreviated, time: .omitted))
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

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
}
