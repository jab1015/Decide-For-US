# Release Checklist

Last updated: August 11, 2026

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

Current 1.0.28 status: build 45 has been submitted and is in App Review. The
release is manual after approval.

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

Current 1.0.28 status: code 45 is active in Internal Testing. The three updated
phone screenshots have been sent for Google review. Production access and
closed-testing requirements are not yet complete.

- [ ] Keep `android/key.properties` and the keystore local and gitignored.
- [x] Run `flutter build appbundle --release` for 1.0.28+45.
- [x] Confirm the `.aab` version code is greater than the prior Play release.
- [x] Upload 1.0.28+45 to Internal Testing.
- [x] Add release notes and roll out to internal testers.
- [x] Replace the Google Play phone screenshots and send the listing change for
      review.
- [ ] Complete the required closed-testing period and apply for production
      access.
- [ ] Confirm RevenueCat Android monthly and annual products.
- [ ] Confirm the internal tester list is also selected for license testing.
- [ ] Use a Google Play test payment method and verify Premium activation.
- [ ] Keep `android_min_version` unchanged until the matching Play version is
      available to the intended audience.

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
