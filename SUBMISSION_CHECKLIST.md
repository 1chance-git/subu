# Subu — App Store Submission Checklist

## Blocked on you (nothing I can do here)

- [ ] Enroll in the paid Apple Developer Program ($99/year) — a free
      Personal Team can never submit to the App Store, this isn't a
      configuration issue.
- [ ] Create the app record in App Store Connect once enrolled.
- [ ] Create the "Remove Ads" in-app purchase product in App Store Connect
      — the code already targets product ID `com.chancejohnson.subu.removeads`
      (`StoreManager.swift`); create it there with a matching ID, or update
      the constant if you want a different one.
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
      script, verified present in the built Info.plist. Spot-checked
      against `developers.google.com/admob/ios/ios14` directly (raw HTML
      diff, no summarization step) — exact match, all 50 confirmed current.
- [x] Bundle identifier decided: `com.chancejohnson.subu` (app renamed
      SubZero → Subu throughout; verified clean Debug build after the
      rename).
- [x] `PRIVACY_POLICY.md` date and contact email placeholders filled in,
      and the policy is hosted at a public URL via GitHub Pages:
      https://1chance-git.github.io/subu/privacy.html
- [x] Support URL filled in (`APP_STORE_LISTING.md`): the project's GitHub
      repo, https://github.com/1chance-git/subu, with a real README
      (description, support contact, privacy policy link) replacing
      GitHub's auto-generated placeholder.
- [x] USPTO trademark search for "Subu" done (via tmsearch.uspto.gov,
      run by the user directly since it's behind bot-detection I can't
      script or view in-browser) — no conflicts found.
