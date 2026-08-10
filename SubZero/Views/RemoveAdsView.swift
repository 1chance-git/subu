//
//  RemoveAdsView.swift
//  Subu
//
//  The "Remove Ads" purchase sheet. Includes Restore Purchases, which Apple
//  requires for any non-consumable purchase.
//

import SwiftUI
import StoreKit

struct RemoveAdsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var storeManager: StoreManager

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("Remove Ads")
                        .font(.title2.weight(.bold))
                    Text("A one-time purchase that removes ads from Subu for good.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if storeManager.isAdsRemoved {
                    Label("Ads already removed — thank you!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.semibold))
                        .transition(.motionAware(reduceMotion, full: .scale(scale: 0.9).combined(with: .opacity)))
                } else {
                    purchaseButton
                        .transition(.opacity)
                }

                Button {
                    restore()
                } label: {
                    if isRestoring {
                        ProgressView()
                    } else {
                        Text("Restore Purchases")
                    }
                }
                .font(.subheadline)
                .frame(minHeight: 44)
                .disabled(isRestoring || storeManager.isAdsRemoved)

                Spacer()
            }
            .padding()
            .navigationTitle("Remove Ads")
            .animation(
                .motionAware(reduceMotion, full: .spring(duration: 0.4, bounce: 0.25)),
                value: storeManager.isAdsRemoved
            )
            .sensoryFeedback(.success, trigger: storeManager.isAdsRemoved)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Something Went Wrong", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        Button {
            purchase()
        } label: {
            if isPurchasing {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let product = storeManager.removeAdsProduct {
                Text("Buy for \(product.displayPrice)")
                    .frame(maxWidth: .infinity)
            } else if storeManager.isLoadingProduct {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Unavailable Right Now")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isPurchasing || storeManager.removeAdsProduct == nil)
    }

    private func purchase() {
        isPurchasing = true
        Task {
            defer { isPurchasing = false }
            do {
                try await storeManager.purchaseRemoveAds()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            defer { isRestoring = false }
            do {
                try await storeManager.restorePurchases()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    RemoveAdsView(storeManager: StoreManager())
}
