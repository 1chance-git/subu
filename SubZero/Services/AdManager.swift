//
//  AdManager.swift
//  SubZero
//
//  Thin wrapper around the Google Mobile Ads SDK: SDK startup, the App
//  Tracking Transparency prompt (needed for personalized ads), and a
//  SwiftUI banner view. iOS only — Google Mobile Ads doesn't ship a macOS
//  or visionOS target, so every symbol here is compiled out on those
//  platforms and the ad/IAP surface simply doesn't appear there.
//
//  Debug builds always use Google's public test IDs, never the real ones —
//  Google explicitly warns against serving real ads during your own
//  testing (clicking your own live ads counts as "invalid activity" and
//  can get an AdMob account suspended). Release builds use Subu's real
//  AdMob App ID (set via the `GAD_APPLICATION_IDENTIFIER` build setting,
//  Release configuration only) and the real banner ad unit ID below.
//

#if os(iOS)
import GoogleMobileAds
import AppTrackingTransparency
import SwiftUI

enum AdManager {
    /// Google's official public test banner unit in Debug; Subu's real
    /// banner ad unit in Release.
    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    static let bannerAdUnitID = "ca-app-pub-2428001862412704/9318791666"
    #endif

    private static var didStart = false

    /// Starts the Mobile Ads SDK. Safe to call more than once.
    static func start() {
        guard !didStart else { return }
        didStart = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    /// Requests the App Tracking Transparency prompt if the user hasn't
    /// been asked yet. Personalized ads only serve after this is granted;
    /// non-personalized ads still work either way.
    @MainActor
    static func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}

// MARK: - BannerAdView

/// A SwiftUI-hostable AdMob banner. Sizes itself to the standard 320x50
/// banner and reloads automatically when re-created.
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdManager.bannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.keyWindowRootViewController()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    private static func keyWindowRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}
#endif
