//
//  PreviewSampleData.swift
//  SubZero
//
//  Realistic mock data shared by every SwiftUI #Preview in the app so
//  Xcode Canvas can render instantly with no external setup. Covers all
//  three subscription statuses, including one discovered-but-unfilled-in
//  record (Adobe) to preview the discovery-first flow.
//

import Foundation
import SwiftData

@MainActor
enum PreviewSampleData {
    static let netflix = Subscription(
        name: "Netflix",
        provider: "Netflix",
        category: .streaming,
        status: .keep,
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

    static let spotify = Subscription(
        name: "Spotify",
        provider: "Spotify",
        category: .streaming,
        status: .keep,
        cancellationDifficulty: .easy,
        cancellationInstructions: """
        Go to spotify.com/account and sign in.
        Select Your Plan from the account menu.
        Select Cancel Premium.
        Confirm by selecting Cancel Premium again on the following page.
        """,
        cancellationURL: "https://www.spotify.com/account/subscription/",
        notes: ""
    )

    static let iCloud = Subscription(
        name: "iCloud+ 200GB",
        provider: "Apple",
        category: .utilities,
        status: .keep,
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

    /// A record created straight from Discovery: name and category only.
    static let adobe = Subscription(
        name: "Adobe",
        category: .software,
        status: .review,
        cancellationDifficulty: .hard,
        cancellationInstructions: """
        Sign in at account.adobe.com and go to Plans.
        Select Manage plan next to your subscription.
        Select Cancel plan and choose a reason.
        Review any early termination fee before confirming.
        """,
        cancellationURL: "https://account.adobe.com/plans"
    )

    static let gym = Subscription(
        name: "Gym Membership",
        provider: "Local Gym",
        category: .fitness,
        status: .review,
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

    static let unusedSubscription = Subscription(
        name: "Unused Subscription",
        provider: "Old Streaming Service",
        category: .streaming,
        status: .cancel,
        cancellationDifficulty: .moderate,
        notes: "Haven't used this in months."
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
        context.insert(spotify)
        context.insert(iCloud)
        context.insert(adobe)
        context.insert(gym)
        context.insert(unusedSubscription)

        return container
    }()
}
