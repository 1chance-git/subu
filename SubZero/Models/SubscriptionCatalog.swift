//
//  SubscriptionCatalog.swift
//  Subu
//
//  A local, static catalog of common subscriptions used to power discovery.
//  This is app metadata only — nothing here is persisted. A `Subscription`
//  (the user-owned SwiftData record) is only created once the user taps to
//  add a catalog item. `businessModel` for the created Subscription is
//  derived automatically from `category` via
//  `SubscriptionBusinessModel.defaultFor(_:)` — no separate field needed
//  here since that mapping already covers every category.
//

import Foundation

// MARK: - CatalogSection

enum CatalogSection: String, CaseIterable, Identifiable {
    case entertainment = "Entertainment"
    case ai = "AI"
    case software = "Software"
    case cloud = "Cloud"
    case memberships = "Memberships"
    case gaming = "Gaming"
    case health = "Health & Fitness"
    case news = "News"
    case physicalGoods = "Physical Goods"
    case consumables = "Consumables"
    case socialCreators = "Social & Creators"

    var id: String { rawValue }
}

// MARK: - SubscriptionCatalogItem

struct SubscriptionCatalogItem: Identifiable, Hashable {
    let id: String
    let name: String
    let section: CatalogSection
    let category: SubscriptionCategory

    /// Lower is more popular; `nil` means unranked. Static, curated
    /// metadata shipped with the app — not derived from any telemetry
    /// (Subu collects none). Powers the "Popular" smart suggestion.
    let popularityRank: Int?

    init(name: String, section: CatalogSection, category: SubscriptionCategory, popularityRank: Int? = nil) {
        self.id = name
        self.name = name
        self.section = section
        self.category = category
        self.popularityRank = popularityRank
    }
}

// MARK: - SubscriptionCatalog

enum SubscriptionCatalog {
    static let items: [SubscriptionCatalogItem] = [
        // Entertainment
        .init(name: "Netflix", section: .entertainment, category: .streaming, popularityRank: 1),
        .init(name: "Spotify", section: .entertainment, category: .streaming, popularityRank: 2),
        .init(name: "Disney+", section: .entertainment, category: .streaming, popularityRank: 7),
        .init(name: "Hulu", section: .entertainment, category: .streaming, popularityRank: 10),
        .init(name: "YouTube Premium", section: .entertainment, category: .streaming, popularityRank: 6),
        .init(name: "Apple TV+", section: .entertainment, category: .streaming),
        .init(name: "Max", section: .entertainment, category: .streaming),
        .init(name: "Paramount+", section: .entertainment, category: .streaming),
        .init(name: "Peacock", section: .entertainment, category: .streaming),
        .init(name: "Apple Music", section: .entertainment, category: .streaming),
        .init(name: "Amazon Music", section: .entertainment, category: .streaming),
        .init(name: "Audible", section: .entertainment, category: .streaming),
        .init(name: "ESPN+", section: .entertainment, category: .streaming),

        // AI
        .init(name: "ChatGPT", section: .ai, category: .ai, popularityRank: 4),
        .init(name: "Claude", section: .ai, category: .ai),
        .init(name: "Perplexity", section: .ai, category: .ai),
        .init(name: "Gemini Advanced", section: .ai, category: .ai),
        .init(name: "GitHub Copilot", section: .ai, category: .ai),
        .init(name: "Midjourney", section: .ai, category: .ai),

        // Software
        .init(name: "Adobe", section: .software, category: .software),
        .init(name: "Canva", section: .software, category: .software),
        .init(name: "Microsoft 365", section: .software, category: .software, popularityRank: 9),
        .init(name: "Notion", section: .software, category: .software),
        .init(name: "Figma", section: .software, category: .software),
        .init(name: "1Password", section: .software, category: .software),
        .init(name: "Grammarly", section: .software, category: .software),

        // Cloud
        .init(name: "iCloud+", section: .cloud, category: .utilities, popularityRank: 5),
        .init(name: "Dropbox", section: .cloud, category: .utilities),
        .init(name: "Google One", section: .cloud, category: .utilities),
        .init(name: "Microsoft OneDrive", section: .cloud, category: .utilities),
        .init(name: "Backblaze", section: .cloud, category: .utilities),

        // Memberships
        .init(name: "Amazon Prime", section: .memberships, category: .membership, popularityRank: 3),
        .init(name: "Costco", section: .memberships, category: .membership, popularityRank: 8),
        .init(name: "Walmart+", section: .memberships, category: .membership),
        .init(name: "Sam's Club", section: .memberships, category: .membership),
        .init(name: "AAA", section: .memberships, category: .membership),
        .init(name: "DashPass", section: .memberships, category: .membership),
        .init(name: "Instacart+", section: .memberships, category: .membership),

        // Gaming
        .init(name: "Xbox Game Pass", section: .gaming, category: .gaming),
        .init(name: "PlayStation Plus", section: .gaming, category: .gaming),
        .init(name: "Nintendo Switch Online", section: .gaming, category: .gaming),
        .init(name: "Apple Arcade", section: .gaming, category: .gaming),

        // Health & Fitness
        .init(name: "Peloton", section: .health, category: .fitness),
        .init(name: "Strava", section: .health, category: .fitness),
        .init(name: "WHOOP", section: .health, category: .fitness),
        .init(name: "Calm", section: .health, category: .fitness),
        .init(name: "Headspace", section: .health, category: .fitness),

        // News
        .init(name: "Apple News+", section: .news, category: .news),
        .init(name: "The New York Times", section: .news, category: .news),
        .init(name: "The Wall Street Journal", section: .news, category: .news),

        // Physical Goods (Boxes)
        .init(name: "FabFitFun", section: .physicalGoods, category: .physicalGoods),
        .init(name: "Birchbox", section: .physicalGoods, category: .physicalGoods),
        .init(name: "Stitch Fix", section: .physicalGoods, category: .physicalGoods),
        .init(name: "BarkBox", section: .physicalGoods, category: .physicalGoods),
        .init(name: "HelloFresh", section: .physicalGoods, category: .physicalGoods),

        // Consumables (Replenishment)
        .init(name: "Dollar Shave Club", section: .consumables, category: .consumables),
        .init(name: "Trade Coffee", section: .consumables, category: .consumables),
        .init(name: "Chewy Autoship", section: .consumables, category: .consumables),
        .init(name: "Amazon Subscribe & Save", section: .consumables, category: .consumables),

        // Social & Creators
        .init(name: "X Premium", section: .socialCreators, category: .socialCreators),
        .init(name: "OnlyFans", section: .socialCreators, category: .socialCreators),
        .init(name: "Patreon", section: .socialCreators, category: .socialCreators),
        .init(name: "Twitch Turbo", section: .socialCreators, category: .socialCreators),
    ]

    static func items(in section: CatalogSection) -> [SubscriptionCatalogItem] {
        items.filter { $0.section == section }
    }

    /// Case-insensitive substring match against the catalog. An empty query
    /// returns the full catalog.
    static func matching(_ query: String) -> [SubscriptionCatalogItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    /// The most popular items (lowest `popularityRank` first), for the
    /// "Popular" smart suggestion.
    static var popular: [SubscriptionCatalogItem] {
        items
            .filter { $0.popularityRank != nil }
            .sorted { $0.popularityRank! < $1.popularityRank! }
    }
}
