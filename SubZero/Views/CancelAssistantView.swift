//  CancelAssistantView.swift
//  Subu
//
//  Subu's core differentiating feature: a native, step-by-step
//  cancellation workflow for any tracked subscription, including an
//  Apple Subscriptions shortcut.
//

import SwiftUI
import SwiftData

struct CancelAssistantView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Environment(\.openURL) private var openURL

    var preselectedSubscription: Subscription?

    @State private var selectedSubscription: Subscription?

    init(preselectedSubscription: Subscription? = nil) {
        self.preselectedSubscription = preselectedSubscription
        _selectedSubscription = State(initialValue: preselectedSubscription)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let subscription = selectedSubscription {
                    guideView(for: subscription)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    pickerView
                        .transition(.opacity)
                }
            }
            .animation(.snappy, value: selectedSubscription)
            .sensoryFeedback(.selection, trigger: selectedSubscription)
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
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(subscriptions) { subscription in
                            Button {
                                selectedSubscription = subscription
                            } label: {
                                SubscriptionPickerRow(subscription: subscription)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
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
            Text("Discover a subscription first, then come back here for step-by-step cancellation help.")
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
                cancelDirectlyButton(for: subscription)
                stepsSection(for: subscription)

                if subscription.isAppleManaged {
                    appleSubscriptionsButton
                }
            }
            .padding()
        }
    }

    // MARK: Direct cancel link

    /// The best link we can offer for this subscription: its specific
    /// cancellation page when we have one (Easy difficulty, mostly), or
    /// failing that, the provider's homepage — still faster than making the
    /// user search for it themselves, which is most of what Moderate
    /// difficulty subscriptions get today (instructions but no direct link).
    private func directLink(for subscription: Subscription) -> (url: URL, label: String)? {
        if !subscription.cancellationURL.isEmpty, let url = URL(string: subscription.cancellationURL) {
            return (url, "Cancel on \(subscription.provider)'s Website")
        }
        if let url = ProviderHomepageDirectory.homepageURL(forProvider: subscription.provider) {
            return (url, "Open \(subscription.provider)'s Website")
        }
        return nil
    }

    /// Surfaces the best available link as the primary action, opened
    /// directly in Safari via `openURL`, ahead of the numbered guide.
    @ViewBuilder
    private func cancelDirectlyButton(for subscription: Subscription) -> some View {
        if let link = directLink(for: subscription) {
            VStack(spacing: 4) {
                Button {
                    openURL(link.url)
                } label: {
                    Label(link.label, systemImage: "safari.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if let host = link.url.host {
                    Text("Opens \(host) in Safari")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
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
        .cardBackground(cornerRadius: 18)
    }

    /// Whether the cancellation steps come from Subu's built-in guide
    /// library (verified per-provider) or the generic fallback, so the
    /// screen can be transparent about where the guidance originated.
    private enum GuideSource {
        case builtIn
        case general

        var label: String {
            switch self {
            case .builtIn: return "Subu's built-in cancellation guide"
            case .general: return "General guidance — steps may vary by provider"
            }
        }

        var icon: String {
            switch self {
            case .builtIn: return "checkmark.seal.fill"
            case .general: return "info.circle.fill"
            }
        }
    }

    private func stepsAndSource(for subscription: Subscription) -> (steps: [String], source: GuideSource) {
        if !subscription.cancellationInstructions.isEmpty {
            let lines = subscription.cancellationInstructions
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if !lines.isEmpty {
                return (lines, .builtIn)
            }
        }

        if let guide = CancellationGuideLibrary.guide(forProvider: subscription.provider) {
            return (guide.steps, .builtIn)
        }

        return (CancellationGuideLibrary.genericSteps, .general)
    }

    private func stepsSection(for subscription: Subscription) -> some View {
        let (steps, source) = stepsAndSource(for: subscription)

        return VStack(alignment: .leading, spacing: 14) {
            Text("Cancellation Guide")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
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

            Label(source.label, systemImage: source.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .cardBackground(cornerRadius: 18)
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
}

// MARK: - SubscriptionPickerRow

private struct SubscriptionPickerRow: View {
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
                Text(subscription.provider)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: subscription.cancellationDifficulty.symbolName)
                .foregroundStyle(subscription.cancellationDifficulty.tintColor)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .cardBackground(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subscription.name), \(subscription.provider), cancellation difficulty \(subscription.cancellationDifficulty.rawValue)")
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
