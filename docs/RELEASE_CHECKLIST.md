# Release Checklist

Last updated: July 30, 2026

## Every test build

- [ ] Refresh the intended Git branch.
- [ ] Confirm `pubspec.yaml` version and unused build number.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `node --check functions/index.js` after backend changes.
- [ ] Deploy every changed Firebase Function.
- [ ] Confirm Function secrets and IAM bindings.
- [ ] Test on a real iPhone and Android device.
- [ ] Verify two option cards and four distinct stops.
- [ ] Verify photos, directions, favorites, and scrolling.
- [ ] Verify the fourth free decision opens the paywall.
- [ ] Verify both Monthly and Yearly packages appear.
- [ ] Verify Local Events+ loading, empty, and error states.
- [ ] Verify event images, dates, maps, and event links.
- [ ] Confirm non-Premium users cannot call Local Events+.
- [ ] Confirm non-Premium users cannot activate Date Night+.
- [ ] Confirm enabled Firestore testers can activate Date Night+ in Chrome.
- [ ] Test every Date Night+ occasion, style, energy, and timing control.
- [ ] Verify Date Night+ event links and fallback-to-places behavior.
- [ ] Confirm ordinary Couple results remain distinct from Date Night+.

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
- [ ] Test Date Night+ with Apple sandbox Premium access.

## Android / Google Play

- [ ] Keep `android/key.properties` and the keystore local and gitignored.
- [ ] Run `flutter build appbundle --release`.
- [ ] Confirm the `.aab` version code is greater than the current Play release.
- [ ] Upload to Internal Testing.
- [ ] Add release notes and roll out to internal testers.
- [ ] Confirm RevenueCat Android monthly and annual products.
- [ ] Confirm the internal tester list is also selected for license testing.
- [ ] Use a Google Play test payment method and verify Premium activation.
- [ ] Test Date Night+ with Google Play license-testing Premium access.

## Production-only gates

- [x] Remove the Reset tester usage button.
- [x] Delete `resetTesterUsage` from Firebase Functions.
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

