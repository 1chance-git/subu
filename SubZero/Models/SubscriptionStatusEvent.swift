//
//  SubscriptionStatusEvent.swift
//  SubZero
//
//  A lightweight history log of status changes (Keep/Review/Cancel),
//  written automatically whenever `Subscription.status` changes — see that
//  property's setter. This is the "past transactions" record that feeds
//  the on-device cancel-risk prediction: how often you've reconsidered a
//  subscription is a real signal, not something CancelRiskPredictor has to
//  guess at.
//

import Foundation
import SwiftData

@Model
final class SubscriptionStatusEvent {
    var id: UUID
    var subscriptionID: UUID
    var previousStatusRaw: String
    var newStatusRaw: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        subscriptionID: UUID,
        previousStatus: SubscriptionStatus,
        newStatus: SubscriptionStatus,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.previousStatusRaw = previousStatus.rawValue
        self.newStatusRaw = newStatus.rawValue
        self.timestamp = timestamp
    }

    var previousStatus: SubscriptionStatus {
        SubscriptionStatus(rawValue: previousStatusRaw) ?? .review
    }

    var newStatus: SubscriptionStatus {
        SubscriptionStatus(rawValue: newStatusRaw) ?? .review
    }
}
