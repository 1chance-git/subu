///
//  AddSubscriptionView.swift
//  SubZero
//
//  A validated form for creating a new subscription, writing directly
//  into SwiftData. Auto-fills cancellation notes when the provider
//  matches a known entry in CancellationGuideLibrary.
//

import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var provider: String = ""
    @State private var costText: String = ""
    @State private var category: SubscriptionCategory = .streaming
    @State private var renewalDate: Date = Date()
    @State private var billingCycle: BillingCycle = .monthly
    @State private var cancellationNotes: String = ""

    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showSavedConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription Details") {
                    TextField("Subscription Name", text: $name)
                        .accessibilityLabel("Subscription name")

                    TextField("Provider", text: $provider)
                        .onChange(of: provider) { _, newValue in
                            applyKnownGuideIfNeeded(for: newValue)
                        }
                        .accessibilityLabel("Provider")

                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("0.00", text: $costText)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Cost")
                    }
                }

                Section("Category & Billing") {
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }

                    Picker("Billing Cycle", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Renewal Date", selection: $renewalDate, displayedComponents: .date)
                }

                Section("Cancellation Notes") {
                    TextField(
                        "Optional notes about cancelling this subscription",
                        text: $cancellationNotes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section {
                    HStack {
                        Text("Monthly Equivalent")
                        Spacer()
                        Text(normalizedCostPreview)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Subscription")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubscription()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Missing Information", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .alert("Subscription Added", isPresented: $showSavedConfirmation) {
                Button("OK", role: .cancel) {
                    resetForm()
                }
            } message: {
                Text("\(name) has been added to your subscriptions.")
            }
        }
    }

    private var normalizedCostPreview: String {
        guard let cost = Double(costText) else { return "—" }
        let normalized = billingCycle == .yearly ? cost / 12.0 : cost
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return (formatter.string(from: NSNumber(value: normalized)) ?? "$0.00") + "/mo"
    }

    private func applyKnownGuideIfNeeded(for providerName: String) {
        guard cancellationNotes.isEmpty else { return }
        guard let guide = CancellationGuideLibrary.guide(forProvider: providerName) else { return }
        cancellationNotes = guide.steps.joined(separator: "\n")
    }

    private func saveSubscription() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProvider = provider.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a subscription name."
            showValidationAlert = true
            return
        }

        guard !trimmedProvider.isEmpty else {
            validationMessage = "Please enter a provider name."
            showValidationAlert = true
            return
        }

        guard let cost = Double(costText), cost > 0 else {
            validationMessage = "Please enter a valid cost greater than zero."
            showValidationAlert = true
            return
        }

        let guide = CancellationGuideLibrary.guide(forProvider: trimmedProvider)
        let finalNotes = cancellationNotes.isEmpty
            ? (guide?.steps.joined(separator: "\n") ?? "")
            : cancellationNotes

        let subscription = Subscription(
            name: trimmedName,
            provider: trimmedProvider,
            monthlyCost: cost,
            category: category,
            renewalDate: renewalDate,
            billingCycle: billingCycle,
            cancellationDifficulty: guide?.difficulty ?? .moderate,
            cancellationInstructions: finalNotes,
            cancellationURL: guide?.url ?? "",
            notes: ""
        )

        modelContext.insert(subscription)
        showSavedConfirmation = true
    }

    private func resetForm() {
        name = ""
        provider = ""
        costText = ""
        category = .streaming
        renewalDate = Date()
        billingCycle = .monthly
        cancellationNotes = ""
    }
}

#Preview {
    AddSubscriptionView()
        .modelContainer(PreviewSampleData.container)
}
