//  CancelAssistantView.swift
//  SubZero
//
//  SubZero's core differentiating feature: a native, step-by-step
//  cancellation workflow for any tracked subscription, including an
//  Apple Subscriptions shortcut and a reusable cancellation email
//  template with copy/share support.
//
//  AppKit is imported here only for NSPasteboard, since SwiftUI has no
//  native clipboard API.
//

import SwiftUI
import SwiftData
import AppKit

struct CancelAssistantView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.openURL) private var openURL

    var preselectedSubscription: Subscription?

    @State private var selectedSubscription: Subscription?
    @State private var showCopiedConfirmation = false

    init(preselectedSubscription: Subscription? = nil) {
        self.preselectedSubscription = preselectedSubscription
        _selectedSubscription = State(initialValue: preselectedSubscription)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let subscription = selectedSubscription {
                    guideView(for: subscription)
                } else {
                    pickerView
                }
            }
            .navigationTitle("Cancel Assistant")
            .toolbar {
                if selectedSubscription != nil && preselectedSubscription == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Change") {
                            selectedSubscription = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: Picker

    private var pickerView: some View {
        Group {
            if subscriptions.isEmpty {
                emptyState
            } else {
                List(subscriptions) { subscription in
                    Button {
                        selectedSubscription = subscription
                    } label: {
                        HStack {
                            Image(systemName: subscription.category.symbolName)
                                .foregroundStyle(subscription.category.tintColor)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(subscription.provider)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: subscription.cancellationDifficulty.symbolName)
                                .foregroundStyle(subscription.cancellationDifficulty.tintColor)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trash.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Nothing to cancel yet")
                .font(.headline)
            Text("Add a subscription first, then come back here for step-by-step cancellation help.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Guide

    private func guideView(for subscription: Subscription) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(for: subscription)
                stepsSection(for: subscription)

                if subscription.isAppleManaged {
                    appleSubscriptionsButton
                }

                emailTemplateSection(for: subscription)
            }
            .padding()
        }
    }

    private func header(for subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: subscription.category.symbolName)
                    .font(.title2)
                    .foregroundStyle(subscription.category.tintColor)
                VStack(alignment: .leading) {
                    Text(subscription.name)
                        .font(.title3.weight(.bold))
                    Text(subscription.provider)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 6) {
                Image(systemName: subscription.cancellationDifficulty.symbolName)
                Text("Cancellation Difficulty: \(subscription.cancellationDifficulty.rawValue)")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(subscription.cancellationDifficulty.tintColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func steps(for subscription: Subscription) -> [String] {
        if !subscription.cancellationInstructions.isEmpty {
            let lines = subscription.cancellationInstructions
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if !lines.isEmpty {
                return lines
            }
        }

        if let guide = CancellationGuideLibrary.guide(forProvider: subscription.provider) {
            return guide.steps
        }

        return CancellationGuideLibrary.genericSteps
    }

    private func stepsSection(for subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cancellation Guide")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps(for: subscription).enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.accentColor))

                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !subscription.cancellationURL.isEmpty, let url = URL(string: subscription.cancellationURL) {
                Button {
                    openURL(url)
                } label: {
                    Label("Open Cancellation Page", systemImage: "safari.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var appleSubscriptionsButton: some View {
        Button {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                openURL(url)
            }
        } label: {
            Label("Open Apple Subscriptions", systemImage: "apple.logo")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.primary)
    }

    // MARK: Email Template

    private func emailSubject(for subscription: Subscription) -> String {
        "Cancellation Request"
    }

    private func emailBody(for subscription: Subscription) -> String {
        """
        Hello,

        I would like to cancel my subscription.

        Account: [Your account email or ID]
        Subscription: \(subscription.name)

        Thank you.
        """
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func emailTemplateSection(for subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cancellation Email Template")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Subject: \(emailSubject(for: subscription))")
                    .font(.subheadline.weight(.semibold))
                Text(emailBody(for: subscription))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 12) {
                Button {
                    copyToClipboard(emailBody(for: subscription))
                    showCopiedConfirmation = true
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                ShareLink(item: emailBody(for: subscription)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .alert("Copied to Clipboard", isPresented: $showCopiedConfirmation) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    CancelAssistantView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Preselected Subscription") {
    CancelAssistantView(preselectedSubscription: PreviewSampleData.netflix)
        .modelContainer(PreviewSampleData.container)
}
