//
//  CancelRiskPredictor.swift
//  SubZero
//
//  On-device inference wrapper around CancelRiskModel.mlmodel — a tabular
//  regressor trained offline (see train_cancel_risk_model.swift, not part
//  of the app target) on synthetic data reflecting reasonable domain
//  heuristics. Predicts a continuous 0...1 "cancel risk" score from a
//  subscription's category, cancellation difficulty, tenure, and status
//  change history (via SubscriptionStatusEvent). Inference only — nothing
//  is trained on-device, nothing leaves the device.
//

import Foundation
import CoreML
import SwiftData

enum CancelRiskPredictor {
    private static let model: CancelRiskModel? = {
        try? CancelRiskModel(configuration: MLModelConfiguration())
    }()

    /// Ordinal encodings must match the synthetic training data's category
    /// order exactly (see the training script) — order here is arbitrary
    /// but fixed, not meaningful magnitude.
    private static let categoryOrdinals: [SubscriptionCategory: Double] = [
        .streaming: 0, .software: 1, .ai: 2, .fitness: 3, .food: 4,
        .utilities: 5, .membership: 6, .gaming: 7, .news: 8, .education: 9,
    ]

    private static func difficultyOrdinal(_ difficulty: CancellationDifficulty) -> Double {
        switch difficulty {
        case .easy: return 0
        case .moderate: return 1
        case .hard: return 2
        }
    }

    private static func statusOrdinal(_ status: SubscriptionStatus) -> Double {
        switch status {
        case .keep: return 0
        case .review: return 1
        case .cancel: return 2
        }
    }

    /// Must match the synthetic training data's ordinal assignment exactly
    /// (see the training script): 0 saaS, 1 contentMedia, 2 physicalGoods,
    /// 3 consumables, 4 serviceMembership.
    private static let businessModelOrdinals: [SubscriptionBusinessModel: Double] = [
        .saaS: 0, .contentMedia: 1, .physicalGoods: 2, .consumables: 3, .serviceMembership: 4,
    ]

    /// Returns a 0...1 cancel-risk score, or `nil` if the model couldn't be
    /// loaded or prediction failed — callers should treat `nil` as "no
    /// signal available" rather than crash or show a bogus score.
    static func risk(for subscription: Subscription, statusChangeCount: Int) -> Double? {
        guard let model else { return nil }

        let tenureDays = Date().timeIntervalSince(subscription.createdDate) / 86400

        guard let output = try? model.prediction(
            statusChangeCount: Double(statusChangeCount),
            categoryOrdinal: categoryOrdinals[subscription.category] ?? 9,
            currentStatusOrdinal: statusOrdinal(subscription.status),
            businessModelOrdinal: businessModelOrdinals[subscription.businessModel] ?? 0,
            difficultyOrdinal: difficultyOrdinal(subscription.cancellationDifficulty),
            tenureDays: max(0, tenureDays)
        ) else {
            return nil
        }

        return min(1, max(0, output.cancelRisk))
    }

    /// Convenience overload that looks up the status-change count for this
    /// subscription from SwiftData directly.
    static func risk(for subscription: Subscription, using context: ModelContext) -> Double? {
        risk(for: subscription, statusChangeCount: statusChangeCount(for: subscription, using: context))
    }

    private static func statusChangeCount(for subscription: Subscription, using context: ModelContext) -> Int {
        let subscriptionID = subscription.id
        let descriptor = FetchDescriptor<SubscriptionStatusEvent>(
            predicate: #Predicate { $0.subscriptionID == subscriptionID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Reasoning

    /// A cancel-risk score paired with plain-language reasons for it.
    ///
    /// Important: this does NOT introspect the compiled `.mlmodel`'s
    /// internals — a deployed CoreML model doesn't expose per-prediction
    /// feature attribution at runtime. Instead this mirrors, in Swift, the
    /// same relative weights used to author the synthetic training labels
    /// in `train_cancel_risk_model.swift` (status × 0.35, difficulty ×
    /// 0.08, tenure × 0.15, status changes × 0.06) to rank which factors
    /// most plausibly drove *this* subscription's score. It's a parallel
    /// explanation layer built on the same domain logic that generated the
    /// training data, not a literal readout of the model's decision.
    struct CancelRiskInsight {
        let score: Double
        let reasons: [String]

        /// e.g. "62% risk — hard to cancel and reconsidered twice"
        var summary: String {
            let percent = Int(score * 100)
            guard !reasons.isEmpty else { return "\(percent)% risk" }
            return "\(percent)% risk — \(reasons.joined(separator: " and "))"
        }
    }

    static func insight(for subscription: Subscription, using context: ModelContext) -> CancelRiskInsight? {
        let changeCount = statusChangeCount(for: subscription, using: context)
        guard let score = risk(for: subscription, statusChangeCount: changeCount) else { return nil }

        let tenureDays = max(0, Date().timeIntervalSince(subscription.createdDate) / 86400)

        var weightedReasons: [(weight: Double, text: String)] = []

        switch subscription.status {
        case .cancel:
            weightedReasons.append((0.35 * 2, "already marked to cancel"))
        case .review:
            weightedReasons.append((0.35, "still under review"))
        case .keep:
            break
        }

        if subscription.cancellationDifficulty == .hard {
            weightedReasons.append((0.08 * 2, "hard to cancel"))
        } else if subscription.cancellationDifficulty == .moderate {
            weightedReasons.append((0.08, "moderately hard to cancel"))
        }

        if tenureDays >= 180 {
            let months = Int(tenureDays / 30)
            weightedReasons.append((0.15 * min(tenureDays, 720) / 720, "running for \(months) months"))
        }

        if changeCount > 0 {
            let times = changeCount == 1 ? "once" : "\(changeCount) times"
            weightedReasons.append((0.06 * Double(min(changeCount, 5)), "reconsidered \(times)"))
        }

        switch subscription.businessModel {
        case .contentMedia:
            weightedReasons.append((0.12, "commonly cancelled content subscription"))
        case .physicalGoods:
            weightedReasons.append((0.10, "easy to pause or skip"))
        case .consumables:
            weightedReasons.append((0.09, "easy to pause or skip"))
        case .saaS, .serviceMembership:
            break
        }

        let topReasons = weightedReasons
            .sorted { $0.weight > $1.weight }
            .prefix(2)
            .map(\.text)

        return CancelRiskInsight(score: score, reasons: Array(topReasons))
    }
}
