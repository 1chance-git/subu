//
//  ProviderHomepageDirectory.swift
//  SubZero
//
//  Fallback homepage URLs for providers that don't have a specific
//  cancellation page in CancellationGuideLibrary (typically Moderate
//  difficulty — we have generic instructions but no direct deep link).
//  Pointing the user at the homepage in Safari is still more useful than
//  no link at all.
//

import Foundation

enum ProviderHomepageDirectory {
    static let homepages: [String: String] = [
        // Entertainment
        "netflix": "https://www.netflix.com",
        "spotify": "https://www.spotify.com",
        "disney+": "https://www.disneyplus.com",
        "hulu": "https://www.hulu.com",
        "youtube premium": "https://www.youtube.com/premium",
        "apple tv+": "https://tv.apple.com",
        "max": "https://www.max.com",
        "paramount+": "https://www.paramountplus.com",
        "peacock": "https://www.peacocktv.com",
        "apple music": "https://music.apple.com",
        "amazon music": "https://music.amazon.com",
        "audible": "https://www.audible.com",
        "espn+": "https://www.espn.com/espnplus",

        // AI
        "chatgpt": "https://chatgpt.com",
        "claude": "https://claude.ai",
        "perplexity": "https://www.perplexity.ai",
        "gemini advanced": "https://gemini.google.com",
        "github copilot": "https://github.com/features/copilot",
        "midjourney": "https://www.midjourney.com",

        // Software
        "adobe": "https://www.adobe.com",
        "canva": "https://www.canva.com",
        "microsoft 365": "https://www.microsoft365.com",
        "notion": "https://www.notion.so",
        "figma": "https://www.figma.com",
        "1password": "https://1password.com",
        "grammarly": "https://www.grammarly.com",

        // Cloud
        "icloud+": "https://www.icloud.com",
        "dropbox": "https://www.dropbox.com",
        "google one": "https://one.google.com",
        "microsoft onedrive": "https://onedrive.live.com",
        "backblaze": "https://www.backblaze.com",

        // Memberships
        "amazon prime": "https://www.amazon.com/prime",
        "costco": "https://www.costco.com",
        "walmart+": "https://www.walmart.com/plus",
        "sam's club": "https://www.samsclub.com",
        "aaa": "https://www.aaa.com",
        "dashpass": "https://www.doordash.com/dashpass",
        "instacart+": "https://www.instacart.com",

        // Gaming
        "xbox game pass": "https://www.xbox.com/game-pass",
        "playstation plus": "https://www.playstation.com/ps-plus",
        "nintendo switch online": "https://www.nintendo.com/switch/online-service",
        "apple arcade": "https://www.apple.com/apple-arcade",

        // Health & Fitness
        "peloton": "https://www.onepeloton.com",
        "strava": "https://www.strava.com",
        "whoop": "https://www.whoop.com",
        "calm": "https://www.calm.com",
        "headspace": "https://www.headspace.com",

        // News
        "apple news+": "https://www.apple.com/apple-news",
        "the new york times": "https://www.nytimes.com",
        "the wall street journal": "https://www.wsj.com",
    ]

    /// Looks up a homepage by matching the provider name against known keys,
    /// falling back to a partial (substring) match — same approach as
    /// `CancellationGuideLibrary.guide(forProvider:)`.
    static func homepageURL(forProvider provider: String) -> URL? {
        let key = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }

        if let exact = homepages[key] {
            return URL(string: exact)
        }
        if let match = homepages.first(where: { key.contains($0.key) }) {
            return URL(string: match.value)
        }
        return nil
    }
}
