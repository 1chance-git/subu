# Subu — App Store Submission Checklist

## Status: Submitted for review (2026-08-11)

Build 1.0 (3) uploaded and submitted to App Review. Apple's review
typically takes up to 48 hours; notification arrives by email. Nothing
left to do here unless the review comes back with a rejection.

## Done

- [x] Enrolled in the paid Apple Developer Program — team `S4TVS38XY6`
      confirmed as a non-free Individual account.
- [x] App record created in App Store Connect (Apple ID `6799872853`),
      under the name `Subu - Subscription Tracker` (plain "Subu" was
      already taken as a display name by another app — unrelated to
      trademark, just Apple's storefront-uniqueness check).
- [x] "Remove Ads" in-app purchase product created, product ID
      `com.chancejohnson.subu.removeads` matching `StoreManager.swift`.
- [x] Category set to Productivity, age rating questionnaire completed
      (landed at 4+), App Privacy questionnaire completed using
      `PRIVACY_POLICY.md` as source of truth (Identifiers/Device ID and
      Usage Data/Advertising Data declared for the Google Mobile Ads SDK,
      everything else "No" — nothing else leaves the device).
- [x] Content Rights Information set (no third-party content).
- [x] Pricing set to Free.
- [x] `ITSAppUsesNonExemptEncryption = NO` baked into both build configs
      — pre-answers the export compliance question on every build going
      forward.
- [x] Listing content filled in: name, subtitle, promotional text,
      description, keywords, support URL, copyright (`Subu App, 2026`).
- [x] All required App Store screenshot sizes uploaded: 6.9"/6.7" iPhone
      (1320×2868, 4 screens), 6.5" iPhone (1284×2778), 13" iPad
      (2064×2752).
- [x] **Real crash bug found and fixed during iPad screenshot
      generation**: Subu crashed on launch on iPad
      (`GADInvalidInitializationException`) because
      `GADApplicationIdentifier` was missing from the built Info.plist.
      Root cause was a build-script ordering race — the "Inject Custom
      Info.plist Keys" script phase had no declared dependency on
      `ProcessInfoPlistFile`, so on iPad builds the system-generated
      Info.plist was overwriting the injected ad config. Fixed by
      declaring `$(CODESIGNING_FOLDER_PATH)/Info.plist` as an explicit
      input path, verified via rebuild + successful iPad launch.
- [x] Build number bumped to 3 (build 2 was the pre-fix upload, never
      submitted).
- [x] Archive re-signed under the paid team (`Apple Distribution: CHANCE
      MICAH JOHNSON (S4TVS38XY6)`), uploaded via Xcode Organizer,
      confirmed via local distribution logs: `UPLOAD SUCCEEDED with no
      errors`, status 201.
- [x] Submitted for App Review.

## If Apple rejects

Come back here and paste the rejection reason — happy to help diagnose
and fix before resubmitting.
