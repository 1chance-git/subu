//
//  Cancellationguidelibrary .swift
//  SubZero
////
//  CancellationGuideLibrary.swift
//  SubZero
//
//  A small built-in library of cancellation steps for common providers,
//  plus a generic fallback guide for anything not in the list.
//

import Foundation

struct CancellationGuide {
    let steps: [String]
    let url: String
    let difficulty: CancellationDifficulty
}

enum CancellationGuideLibrary {
    static let guides: [String: CancellationGuide] = [
        "netflix": CancellationGuide(
            steps: [
                "Open the Netflix app or go to netflix.com and sign in.",
                "Select your profile icon, then choose Account.",
                "Under Membership & Billing, select Cancel Membership.",
                "Confirm the cancellation when prompted."
            ],
            url: "https://www.netflix.com/CancelPlan",
            difficulty: .easy
        ),
        "spotify": CancellationGuide(
            steps: [
                "Go to spotify.com/account and sign in.",
                "Select Your Plan from the account menu.",
                "Select Cancel Premium.",
                "Confirm by selecting Cancel Premium again on the following page."
            ],
            url: "https://www.spotify.com/account/subscription/",
            difficulty: .easy
        ),
        "apple": CancellationGuide(
            steps: [
                "Open Settings on your iPhone or iPad.",
                "Tap your name at the top of the screen.",
                "Tap Subscriptions.",
                "Select the subscription and tap Cancel Subscription."
            ],
            url: "https://apps.apple.com/account/subscriptions",
            difficulty: .easy
        ),
        "icloud": CancellationGuide(
            steps: [
                "Open Settings on your iPhone or iPad.",
                "Tap your name, then tap iCloud.",
                "Tap Manage Account Storage, then Change Storage Plan.",
                "Choose the free tier or a smaller plan to downgrade."
            ],
            url: "https://apps.apple.com/account/subscriptions",
            difficulty: .easy
        ),
        "amazon prime": CancellationGuide(
            steps: [
                "Go to amazon.com/prime and sign in.",
                "Select Manage Membership, then End Membership.",
                "Follow the on-screen prompts to confirm cancellation.",
                "Choose whether to cancel immediately or at the end of the billing period."
            ],
            url: "https://www.amazon.com/gp/primecentral",
            difficulty: .moderate
        ),
        "youtube premium": CancellationGuide(
            steps: [
                "Go to youtube.com/paid_memberships and sign in.",
                "Select Manage Membership next to YouTube Premium.",
                "Select Deactivate, then Continue to Cancel.",
                "Confirm the cancellation."
            ],
            url: "https://www.youtube.com/paid_memberships",
            difficulty: .easy
        ),
        "hulu": CancellationGuide(
            steps: [
                "Log in to your account at hulu.com/account.",
                "Select Cancel Your Subscription under Your Subscription.",
                "Follow the prompts and confirm cancellation.",
                "Check your email for a cancellation confirmation."
            ],
            url: "https://secure.hulu.com/account/cancel",
            difficulty: .easy
        ),
        "adobe": CancellationGuide(
            steps: [
                "Sign in at account.adobe.com and go to Plans.",
                "Select Manage plan next to your subscription.",
                "Select Cancel plan and choose a reason.",
                "Review any early termination fee before confirming."
            ],
            url: "https://account.adobe.com/plans",
            difficulty: .hard
        ),
        "planet fitness": CancellationGuide(
            steps: [
                "Cancellation typically requires an in-person visit or certified mail.",
                "Bring a photo ID to your home club, or write a cancellation letter.",
                "Request a copy of your signed cancellation confirmation.",
                "Verify billing has stopped by checking your next statement."
            ],
            url: "",
            difficulty: .hard
        )
    ]

    /// Looks up a guide by matching the provider name against known keys,
    /// falling back to a partial (substring) match.
    static func guide(forProvider provider: String) -> CancellationGuide? {
        let key = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        if let exact = guides[key] {
            return exact
        }
        return guides.first { key.contains($0.key) }?.value
    }

    static let genericSteps: [String] = [
        "Locate the subscription in the provider's app or website, usually under Account or Membership settings.",
        "Look for a Cancel, End Membership, or Manage Plan option.",
        "Follow the prompts to confirm the cancellation.",
        "Save or screenshot any confirmation message or email for your records."
    ]
}
