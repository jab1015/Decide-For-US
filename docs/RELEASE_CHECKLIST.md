# Release Checklist

Last updated: August 26, 2026

## Branch and handoff

- [ ] Start from the latest `origin/main`.
- [ ] Use a short-lived branch; do not base new work on an old merged release branch.
- [ ] Update `docs/CODER_HANDOFF.md` with the new version and remaining steps.

## Every test build

- [ ] Refresh the intended Git branch.
- [ ] Confirm `pubspec.yaml` version and unused build number.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `node --check functions/index.js` after backend changes.
- [ ] Deploy every changed Firebase Function.
- [ ] Confirm Function secrets and IAM bindings.
- [ ] For tester builds, set the Functions `TESTER_PREMIUM_ACCESS` parameter to
      `true` and build Flutter with `--dart-define=TESTER_PREMIUM_ACCESS=true`.
- [ ] Test on a real iPhone and Android device.
- [ ] Verify two option cards and four distinct stops.
- [ ] Verify photos, directions, favorites, and scrolling.
- [ ] Verify the fourth free decision opens the paywall.
- [ ] Verify both Monthly and Yearly packages appear.
- [ ] Verify Local Events+ loading, empty, and error states.
- [ ] Verify event images, dates, maps, and event links.
- [ ] Confirm non-Premium users cannot call Local Events+.

## Firebase deployment

```sh
npm --prefix functions ci
firebase deploy --only functions
```

After deployment:

- [ ] Confirm the intended revision is Active.
- [ ] Make one real recommendation request.
- [ ] Review `firebase functions:log --only getIdeas`.
- [ ] Review `firebase functions:log --only getLocalEvents`.
- [ ] Confirm Firestore usage and history writes succeed.

## iOS / TestFlight

- [ ] Use a new App Store Connect build number.
- [ ] Confirm bundle ID `com.decideforus.app`.
- [ ] Build the intended branch in Codemagic.
- [ ] Confirm signing profile and Apple Distribution certificate.
- [ ] Confirm TestFlight processing completes.
- [ ] Test location permission, purchases, restore, and external map links.
- [ ] Confirm TestFlight subscription transactions run in Apple sandbox.
- [ ] Test Local Events+ at 10, 25, and 50 miles.
- [ ] Confirm the forced-update gate allows the release version to open.
- [ ] Do not raise `ios_min_version` until the release is publicly available.
- [ ] After release, test updating from an older gate-enabled build.

## Android / Google Play

Codemagic is the signed Android release path. Google Play publishing remains
manual-only so repository pushes cannot accidentally publish a store build.

- [x] Target Android API 36.
- [x] Configure protected Android signing in Codemagic.
- [ ] Confirm the `.aab` version code is greater than the prior Play release.
- [ ] Build the intended `main` revision through the YAML workflow
      `android-play-internal`.
- [ ] Confirm upload to Internal Testing succeeds before any production rollout.
- [ ] Confirm RevenueCat Android monthly and annual products.
- [ ] Confirm the internal tester list is also selected for license testing.
- [ ] Use a Google Play test payment method and verify Premium activation.
- [ ] Keep `android_min_version` unchanged until the matching Play version is
      available to the intended audience.

### Google Play 2026 quality gates

These checks implement the August 26, 2026 Google Play quality notice covering
memory/code optimization and secure/seamless device migration.

- [x] `compileSdk` and `targetSdk` are API 36.
- [x] Enable R8 code shrinking for release builds.
- [x] Enable Android resource shrinking for release builds.
- [x] Add an app-specific `proguard-rules.pro` without broad keep rules.
- [x] Add Android 12+ `dataExtractionRules` for cloud backup and device transfer.
- [x] Add legacy `fullBackupContent` rules.
- [x] Scope migration to Flutter SharedPreferences instead of backing up all app
      private data.
- [x] Require encrypted-capable cloud backup for the scoped payload.
- [ ] Build a signed release with R8/resource shrinking and verify startup,
      Firebase, RevenueCat, maps, Local Events+, Date Night+, and Trip Planner+.
- [ ] Test Android 12+ device-to-device transfer on real/emulated devices.
- [ ] Test encrypted cloud backup and restore.
- [ ] Verify Favorites are restored after migration.
- [ ] Verify saved Trip Planner plans are restored after migration.
- [ ] Verify Firebase identity/session behavior after migration; do not rely on
      copied native auth-token stores.
- [ ] Verify Premium access after migration and test Restore Purchases where
      needed.
- [ ] Review Play Console memory/quality diagnostics and Android vitals for the
      release build.
- [ ] Profile image-heavy screens if Play Console/device metrics show bitmap
      pressure; optimize decoded image dimensions based on measured results.
- [ ] Review Google's final migration/onboarding enforcement guidance in Play
      Console and add any additional required mechanism only after compatibility
      with anonymous Firebase Auth is confirmed.

## Production-only gates

- [x] Remove the Reset tester usage button.
- [x] Delete `resetTesterUsage` from Firebase Functions.
- [ ] Set the Functions `TESTER_PREMIUM_ACCESS` parameter to `false` and omit
      the matching Dart define from production binaries.
- [ ] Upgrade the Functions runtime from Node.js 20.
- [ ] Review and upgrade vulnerable/outdated dependencies without forcing
      breaking changes.
- [ ] Disable every `premium_testers` document before production.
- [ ] Confirm free-limit copy and weekly reset behavior.
- [ ] Confirm subscription terms, pricing, restore, and manage-subscription links.
- [ ] Complete privacy policy, terms, support, and account/data deletion.
- [ ] Review Google Places attribution and caching requirements.
- [ ] Add event-provider attribution and terms before Local Events+ launches.
- [ ] Review Ticketmaster image, linking, attribution, caching, and quota terms.
- [ ] Configure monitoring, error alerts, quotas, and budget alerts.
- [ ] Back up signing keys and store credentials securely.
