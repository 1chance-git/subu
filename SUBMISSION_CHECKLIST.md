# Subu — App Store Submission Checklist

## Blocked on you (nothing I can do here)

- [ ] Enroll in the paid Apple Developer Program ($99/year) — a free
      Personal Team can never submit to the App Store, this isn't a
      configuration issue.
- [ ] Create the app record in App Store Connect once enrolled.
- [ ] Create the "Remove Ads" in-app purchase product in App Store Connect
      — the code already targets product ID `VAP.SubZero.removeads`
      (`StoreManager.swift`); create it there with a matching ID, or update
      the constant if you want a different one.
- [ ] Recommended: spot-check the 50 `SKAdNetworkItems` entries (or the
      full list) against `developers.google.com/admob/ios/ios14` before
      final submission — they were fetched live from Google's docs this
      session (not fabricated from memory), but Google adds entries over
      time and the fetch went through an intermediate summarization step,
      so a final check costs little and removes any residual doubt.
- [ ] Decide on a real bundle identifier if `VAP.SubZero` was a
      placeholder — it's effectively permanent once you submit a build.
- [ ] Host `PRIVACY_POLICY.md` somewhere with a public URL (GitHub Pages, a
      Notion public page, or any site you control) and fill in the date/
      contact email placeholders in it first.
- [ ] Fill in the Support URL placeholder in `APP_STORE_LISTING.md`.
- [ ] Free 5-minute USPTO TESS trademark search for "Subu" before
      publishing publicly, just as a sanity check (flagged in
      `APP_STORE_LISTING.md`) — low risk given it's a coined word, but
      free to confirm.
- [ ] Take App Store screenshots (at least one required device size, e.g.
      6.7" iPhone) — can be done together once the account/build pipeline
      above is unblocked; I can drive the Simulator for this when you're
      ready.
- [ ] Complete App Store Connect's App Privacy questionnaire using
      `PRIVACY_POLICY.md` as the source of truth, and the age-rating
      questionnaire (see the note in `APP_STORE_LISTING.md` about the
      Discover catalog's Social & Creators section).
- [ ] Export compliance question at submission: Subu uses no custom
      encryption, so the standard "no" answer should apply — confirm this
      is still true if anything changes before submission.

## Already done (verified this session)

- [x] App icon set complete — universal iOS icon with light/dark/tinted
      1024×1024 variants, all required macOS sizes.
- [x] Release configuration builds clean on both iOS Simulator and macOS.
- [x] Real-device install, trust, and launch verified on a physical
      iPhone via Personal Team signing.
- [x] Ads render correctly (Google's test creative confirmed live in
      Simulator); "Remove Ads" purchase flow is code-complete and fully
      testable locally via `Products.storekit` (Xcode scheme → Run →
      Options → StoreKit Configuration) without any App Store Connect
      setup.
- [x] No unused Info.plist entries (Reminders/Calendar keys removed after
      that feature was cut).
- [x] `GADApplicationIdentifier` correctly injected into the built
      Info.plist via a build-phase script (custom keys aren't picked up by
      `GENERATE_INFOPLIST_FILE`'s `INFOPLIST_KEY_*` mechanism on their
      own).
- [x] Real AdMob account created; production App ID and banner ad unit ID
      wired in. Debug builds still always use Google's public test IDs
      (Google explicitly warns against serving real ads during your own
      testing); only Release builds use the real ones — verified both
      configurations produce the correct ID in their own Info.plist.
- [x] All 50 `SKAdNetworkItems` entries injected via the same build-phase
      script, verified present in the built Info.plist.
