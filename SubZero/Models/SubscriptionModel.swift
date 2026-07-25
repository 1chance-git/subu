//
//  SubscriptionModel.swift
//  SubZero
//
//  Core SwiftData model representing a tracked recurring subscription,
//  plus the supporting enums used throughout the app.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - SubscriptionCategory

enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable {
    case streaming = "Streaming"
    case software = "Software"
    case ai = "AI"
    case fitness = "Fitness"
    case food = "Food"
    case utilities = "Utilities"
    case membership = "Memberships"
    case gaming = "Gaming"
    case news = "News"
    case education = "Education"
    case physicalGoods = "Physical Goods"
    case consumables = "Consumables"
    case socialCreators = "Social & Creators"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .streaming: return "play.tv.fill"
        case .software: return "laptopcomputer"
        case .ai: return "brain.head.profile"
        case .fitness: return "figure.run"
        case .food: return "fork.knife"
        case .utilities: return "bolt.fill"
        case .membership: return "person.3.fill"
        case .gaming: return "gamecontroller.fill"
        case .news: return "newspaper.fill"
        case .education: return "graduationcap.fill"
        case .physicalGoods: return "shippingbox.fill"
        case .consumables: return "cart.fill"
        case .socialCreators: return "person.crop.circle.badge.checkmark"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .streaming: return .red
        case .software: return .blue
        case .ai: return .mint
        case .fitness: return .green
        case .food: return .orange
        case .utilities: return .yellow
        case .membership: return .indigo
        case .gaming: return .teal
        case .news: return .brown
        case .education: return .purple
        case .physicalGoods: return .pink
        case .consumables: return .cyan
        case .socialCreators: return Color(red: 0.10, green: 0.60, blue: 0.98)
        case .other: return .gray
        }
    }
}

// MARK: - SubscriptionBusinessModel

/// A backing classification used by the on-device cancel-risk model —
/// churn patterns genuinely differ across these archetypes (e.g. physical
/// goods boxes and consumables are commonly paused/cancelled far more
/// readily than SaaS tools embedded in a workflow, or sticky memberships
/// like Costco). Not surfaced as its own visible badge in the UI.
enum SubscriptionBusinessModel: String, Codable, CaseIterable, Identifiable {
    case saaS = "SaaS"
    case contentMedia = "Content & Media"
    case physicalGoods = "Physical Goods"
    case consumables = "Consumables"
    case serviceMembership = "Service Membership"

    var id: String { rawValue }

    /// A reasonable default derived from category, for subscriptions
    /// created before this field existed or without an explicit value.
    static func defaultFor(_ category: SubscriptionCategory) -> SubscriptionBusinessModel {
        switch category {
        case .streaming, .news, .socialCreators: return .contentMedia
        case .software, .ai, .utilities, .gaming, .fitness, .education: return .saaS
        case .membership: return .serviceMembership
        case .physicalGoods: return .physicalGoods
        case .consumables: return .consumables
        case .food, .other: return .saaS
        }
    }
}

// MARK: - CancellationDifficulty

enum CancellationDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"

    var id: String { rawValue }

    var tintColor: Color {
        switch self {
        case .easy: return .green
        case .moderate: return .orange
        case .hard: return .red
        }
    }

    var symbolName: String {
        switch self {
        case .easy: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .hard: return "xmark.octagon.fill"
        }
    }
}

// MARK: - SubscriptionStatus

/// The user's disposition toward a tracked subscription. New subscriptions
/// created through discovery default to `.review` until the user decides.
enum SubscriptionStatus: String, Codable, CaseIterable, Identifiable {
    case keep = "Keep"
    case review = "Review"
    case cancel = "Cancel"

    var id: String { rawValue }

    var tintColor: Color {
        switch self {
        case .keep: return .green
        case .review: return .yellow
        case .cancel: return .red
        }
    }

    var symbolName: String {
        switch self {
        case .keep: return "checkmark.circle.fill"
        case .review: return "questionmark.circle.fill"
        case .cancel: return "xmark.circle.fill"
        }
    }
}

// MARK: - Subscription

@Model
final class Subscription {
    var id: UUID
    var name: String
    var provider: String

    var categoryRaw: String
    var businessModelRaw: String?

    var statusRaw: String
    var cancellationDifficultyRaw: String
    var cancellationInstructions: String
    var cancellationURL: String
    var notes: String
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        provider: String = "",
        category: SubscriptionCategory,
        businessModel: SubscriptionBusinessModel? = nil,
        status: SubscriptionStatus = .review,
        cancellationDifficulty: CancellationDifficulty = .moderate,
        cancellationInstructions: String = "",
        cancellationURL: String = "",
        notes: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.provider = provider.isEmpty ? name : provider
        self.categoryRaw = category.rawValue
        self.businessModelRaw = (businessModel ?? .defaultFor(category)).rawValue
        self.statusRaw = status.rawValue
        self.cancellationDifficultyRaw = cancellationDifficulty.rawValue
        self.cancellationInstructions = cancellationInstructions
        self.cancellationURL = cancellationURL
        self.notes = notes
        self.createdDate = createdDate
    }

    // MARK: Typed accessors

    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Falls back to a category-derived default for subscriptions created
    /// before this field existed.
    var businessModel: SubscriptionBusinessModel {
        get { businessModelRaw.flatMap(SubscriptionBusinessModel.init(rawValue:)) ?? .defaultFor(category) }
        set { businessModelRaw = newValue.rawValue }
    }

    var status: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: statusRaw) ?? .review }
        set {
            let previous = status
            guard previous != newValue else { return }
            statusRaw = newValue.rawValue
            modelContext?.insert(
                SubscriptionStatusEvent(subscriptionID: id, previousStatus: previous, newStatus: newValue)
            )
        }
    }

    var cancellationDifficulty: CancellationDifficulty {
        get { CancellationDifficulty(rawValue: cancellationDifficultyRaw) ?? .moderate }
        set { cancellationDifficultyRaw = newValue.rawValue }
    }

    // MARK: Derived values

    var isAppleManaged: Bool {
        let lowercasedProvider = provider.lowercased()
        return lowercasedProvider.contains("apple") || lowercasedProvider.contains("icloud")
    }
}
