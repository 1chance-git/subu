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
    case fitness = "Fitness"
    case food = "Food"
    case utilities = "Utilities"
    case education = "Education"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .streaming: return "play.tv.fill"
        case .software: return "laptopcomputer"
        case .fitness: return "figure.run"
        case .food: return "fork.knife"
        case .utilities: return "bolt.fill"
        case .education: return "graduationcap.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .streaming: return .red
        case .software: return .blue
        case .fitness: return .green
        case .food: return .orange
        case .utilities: return .yellow
        case .education: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - BillingCycle

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
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

// MARK: - Subscription

@Model
final class Subscription {
    var id: UUID
    var name: String
    var provider: String

    /// Cost charged per billing cycle (i.e. the amount the user is actually
    /// billed each time — monthly amount for monthly plans, annual amount
    /// for yearly plans). Use `normalizedMonthlyCost` for cross-subscription
    /// comparisons and totals.
    var monthlyCost: Double

    var categoryRaw: String
    var renewalDate: Date
    var billingCycleRaw: String
    var cancellationDifficultyRaw: String
    var cancellationInstructions: String
    var cancellationURL: String
    var notes: String
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        provider: String,
        monthlyCost: Double,
        category: SubscriptionCategory,
        renewalDate: Date,
        billingCycle: BillingCycle,
        cancellationDifficulty: CancellationDifficulty = .moderate,
        cancellationInstructions: String = "",
        cancellationURL: String = "",
        notes: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.monthlyCost = monthlyCost
        self.categoryRaw = category.rawValue
        self.renewalDate = renewalDate
        self.billingCycleRaw = billingCycle.rawValue
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

    var billingCycle: BillingCycle {
        get { BillingCycle(rawValue: billingCycleRaw) ?? .monthly }
        set { billingCycleRaw = newValue.rawValue }
    }

    var cancellationDifficulty: CancellationDifficulty {
        get { CancellationDifficulty(rawValue: cancellationDifficultyRaw) ?? .moderate }
        set { cancellationDifficultyRaw = newValue.rawValue }
    }

    // MARK: Derived values

    /// The recurring cost normalized to a monthly value, regardless of billing cycle.
    var normalizedMonthlyCost: Double {
        switch billingCycle {
        case .monthly:
            return monthlyCost
        case .yearly:
            return monthlyCost / 12.0
        }
    }

    var isAppleManaged: Bool {
        let lowercasedProvider = provider.lowercased()
        return lowercasedProvider.contains("apple") || lowercasedProvider.contains("icloud")
    }

    /// Rolls `renewalDate` forward to the next occurrence that has not yet
    /// passed, based on the billing cycle. Falls back to `renewalDate`
    /// itself if it is already in the future.
    var nextRenewalDate: Date {
        let calendar = Calendar.current
        let now = Date()
        guard renewalDate < now else { return renewalDate }

        var date = renewalDate
        var safetyCounter = 0
        while date < now && safetyCounter < 1000 {
            switch billingCycle {
            case .monthly:
                guard let advanced = calendar.date(byAdding: .month, value: 1, to: date) else {
                    safetyCounter = 1000
                    continue
                }
                date = advanced
            case .yearly:
                guard let advanced = calendar.date(byAdding: .year, value: 1, to: date) else {
                    safetyCounter = 1000
                    continue
                }
                date = advanced
            }
            safetyCounter += 1
        }
        return date
    }

    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfRenewal = calendar.startOfDay(for: nextRenewalDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfRenewal)
        return components.day ?? 0
    }
}//
//  Subscriptionmodel.swift
//  SubZero
//
//  Created by Ashley Johnson on 7/23/26.
//


