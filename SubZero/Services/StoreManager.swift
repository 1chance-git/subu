//
//  StoreManager.swift
//  SubZero
//
//  StoreKit 2 wrapper for the single "Remove Ads" non-consumable purchase.
//  Cross-platform (StoreKit itself works on macOS too), even though the ads
//  it's removing are iOS-only — buying it on one device unlocks it on any
//  device signed into the same Apple ID via StoreKit's built-in entitlement
//  sync, no server of our own required.
//
//  Testable right now with zero App Store Connect setup via Xcode's local
//  StoreKit configuration (Products.storekit) — see that file's header for
//  how to enable it. The product ID here must match whatever's created in
//  App Store Connect once the paid Developer Program membership is active;
//  no code changes needed at that point, just point the scheme back at the
//  real App Store instead of the local configuration.
//

import StoreKit

@MainActor
@Observable
final class StoreManager {
    static let removeAdsProductID = "com.chancejohnson.subu.removeads"

    private(set) var isAdsRemoved = false
    private(set) var removeAdsProduct: Product?
    private(set) var isLoadingProduct = false

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    func loadProduct() async {
        guard removeAdsProduct == nil else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        removeAdsProduct = try? await Product.products(for: [Self.removeAdsProductID]).first
    }

    func purchaseRemoveAds() async throws {
        guard let product = removeAdsProduct else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result {
            await handle(verification)
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Self.removeAdsProductID {
                isAdsRemoved = true
                return
            }
        }
        isAdsRemoved = false
    }
}
