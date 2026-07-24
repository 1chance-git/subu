//
//  PreviewSampleData.swift
//  SubZero
//
//  Realistic mock data shared by every SwiftUI #Preview in the app so
//  Xcode Canvas can render instantly with no external setup.
//

import Foundation
import SwiftData

@MainActor
enum PreviewSampleData {
    static let netflix = Subscription(
        name: "Netflix",
        provider: "Netflix",
        monthlyCost: 15.49,
        category: .streaming,
        renewalDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
        billingCycle: .monthly,
        cancellationDifficulty: .easy,
        cancellationInstructions: """
        Open the Netflix app or go to netflix.com and sign in.
        Select your profile icon, then choose Account.
        Under Membership & Billing, select Cancel Membership.
        Confirm the cancellation when prompted.
        """,
        cancellationURL: "https://www.netflix.com/CancelPlan",
        notes: "Shared with family."
    )

    static let iCloud = Subscription(
        name: "iCloud+ 200GB",
        provider: "Apple",
        monthlyCost: 9.99,
        category: .utilities,
        renewalDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        billingCycle: .monthly,
        cancellationDifficulty: .easy,
        cancellationInstructions: """
        Open Settings on your iPhone or iPad.
        Tap your name at the top of the screen.
        Tap Subscriptions.
        Select iCloud+ and tap Cancel Subscription.
        """,
        cancellationURL: "https://apps.apple.com/account/subscriptions",
        notes: "Backs up photos and documents."
    )

    static let gym = Subscription(
        name: "Gym Membership",
        provider: "Local Gym",
        monthlyCost: 39.99,
        category: .fitness,
        renewalDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(),
        billingCycle: .monthly,
        cancellationDifficulty: .hard,
        cancellationInstructions: """
        Cancellation requires a signed written notice.
        Deliver it in person at the front desk or send it by certified mail.
        Submit at least 30 days before your next renewal date.
        Request a signed copy for your own records.
        """,
        cancellationURL: "",
        notes: "Requires 30-day written notice."
    )

    /// A single representative subscription for previews that only need one.
    static var sampleSubscription: Subscription { netflix }

    /// An in-memory ModelContainer pre-seeded with sample subscriptions.
    static let container: ModelContainer = {
        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        context.insert(netflix)
        context.insert(iCloud)
        context.insert(gym)

        return container
    }()
}
