//
//  DiscoverSubscriptionsView.swift
//  SubZero
//
//  Replaces manual subscription entry with a discovery-first flow: browse
//  or search a local catalog of common subscriptions and tap to add. Adding
//  a catalog item creates a minimal Subscription (name, category, status
//  Review) — cost, billing cycle, and renewal date are filled in later from
//  the subscription's detail screen.
//

import SwiftUI
import SwiftData

struct DiscoverSubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var subscriptions: [Subscription]

    @State private var searchText = ""
    @State private var addedItemName: String?
    @State private var showAddedConfirmation = false
    @State private var addPulse = 0
    @AppStorage("hasShownDiscoverAddTip") private var hasShownAddTip = false

    private var groupedItems: [(section: CatalogSection, items: [SubscriptionCatalogItem])] {
        let matches = SubscriptionCatalog.matching(searchText)
        return CatalogSection.allCases.compactMap { section in
            let items = matches.filter { $0.section == section }
            guard !items.isEmpty else { return nil }
            return (section, items)
        }
    }

    private var totalMatches: Int {
        groupedItems.reduce(0) { $0 + $1.items.count }
    }

    private func isAdded(_ item: SubscriptionCatalogItem) -> Bool {
        subscriptions.contains { $0.name.caseInsensitiveCompare(item.name) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if groupedItems.isEmpty {
                    emptyState
                } else {
                    LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                        if !searchText.isEmpty {
                            resultCountLabel
                        }
                        ForEach(groupedItems, id: \.section) { group in
                            Section {
                                VStack(spacing: 10) {
                                    ForEach(group.items) { item in
                                        CatalogItemRow(item: item, isAdded: isAdded(item)) {
                                            addSubscription(for: item)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            } header: {
                                sectionHeader(group.section)
                            }
                        }
                        if !searchText.isEmpty {
                            webSearchFallback
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Find Your Subscriptions")
            .searchable(text: $searchText, prompt: "Search subscriptions")
            .animation(.snappy, value: totalMatches)
            .sensoryFeedback(.success, trigger: addPulse)
            .alert("Added to Review", isPresented: $showAddedConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(addedItemName ?? "Subscription") was added. Add cost and renewal details anytime from its page.")
            }
        }
    }

    // MARK: Sections

    private var resultCountLabel: some View {
        Text("\(totalMatches) result\(totalMatches == 1 ? "" : "s")")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }

    private func sectionHeader(_ section: CatalogSection) -> some View {
        Text(section.rawValue.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
            .accessibilityAddTraits(.isHeader)
    }

    private func addSubscription(for item: SubscriptionCatalogItem) {
        guard !isAdded(item) else { return }

        let guide = CancellationGuideLibrary.guide(forProvider: item.name)
        let subscription = Subscription(
            name: item.name,
            category: item.category,
            cancellationDifficulty: guide?.difficulty ?? .moderate,
            cancellationInstructions: guide?.steps.joined(separator: "\n") ?? "",
            cancellationURL: guide?.url ?? ""
        )

        withAnimation(.snappy) {
            modelContext.insert(subscription)
        }
        addPulse += 1

        // The checkmark bounce + haptic above already confirm the add
        // inline: only interrupt with a modal alert the first time, so
        // adding several subscriptions in a row doesn't mean tapping "OK"
        // over and over.
        guard !hasShownAddTip else { return }
        addedItemName = item.name
        showAddedConfirmation = true
        hasShownAddTip = true
    }

    // MARK: Web Search Fallback

    /// A single, fixed, scoped deep link out to Safari for a web search of
    /// the current query plus "subscription" — not an embedded browser, not
    /// a general-purpose search entry point, and no network request is made
    /// by the app itself (Safari handles it after the link opens).
    private func webSearchQueryURL(for query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let encoded = "\(trimmed) subscription".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }

    @ViewBuilder
    private var webSearchFallback: some View {
        if let url = webSearchQueryURL(for: searchText) {
            Button {
                openURL(url)
            } label: {
                Label("Search the web for “\(searchText)”", systemImage: "safari")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No matches")
                .font(.headline)
            Text("Try a different search term, or search the web below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            webSearchFallback
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - CatalogItemRow

private struct CatalogItemRow: View {
    let item: SubscriptionCatalogItem
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.category.tintColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: item.category.symbolName)
                    .foregroundStyle(item.category.tintColor)
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button(action: onAdd) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .symbolEffect(.bounce, value: isAdded)
                    .foregroundStyle(isAdded ? .green : Color.accentColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
            .accessibilityLabel(isAdded ? "Added" : "Add \(item.name)")
        }
        .padding(14)
        .cardBackground(cornerRadius: 16)
        .animation(.snappy, value: isAdded)
    }
}

#Preview {
    DiscoverSubscriptionsView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Empty Catalog Search") {
    DiscoverSubscriptionsView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
