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
- [ ] Verify tester reset returns directly to Decide.
- [ ] Verify both Monthly and Yearly packages appear.

## Firebase deployment

```sh
npm --prefix functions ci
firebase deploy --only functions
```

After deployment:

- [ ] Confirm the intended revision is Active.
- [ ] Make one real recommendation request.
- [ ] Review `firebase functions:log --only getIdeas`.
- [ ] Confirm Firestore usage and history writes succeed.

## iOS / TestFlight

- [ ] Use a new App Store Connect build number.
- [ ] Confirm bundle ID `com.decideforus.app`.
- [ ] Build the intended branch in Codemagic.
- [ ] Confirm signing profile and Apple Distribution certificate.
- [ ] Confirm TestFlight processing completes.
- [ ] Test location permission, purchases, restore, and external map links.

## Android / Google Play

- [ ] Keep `android/key.properties` and the keystore local and gitignored.
- [ ] Run `flutter build appbundle --release`.
- [ ] Confirm the `.aab` version code is greater than the current Play release.
- [ ] Upload to Internal Testing.
- [ ] Add release notes and roll out to internal testers.
- [ ] Confirm RevenueCat Android monthly and annual products.

## Production-only gates

- [ ] Remove the Reset tester usage button.
- [ ] Delete `resetTesterUsage` from Firebase Functions.
- [ ] Upgrade the Functions runtime from Node.js 20.
- [ ] Review and upgrade vulnerable/outdated dependencies without forcing
      breaking changes.
- [ ] Disable or restrict test accounts and test-only configuration.
- [ ] Confirm free-limit copy and weekly reset behavior.
- [ ] Confirm subscription terms, pricing, restore, and manage-subscription links.
- [ ] Complete privacy policy, terms, support, and account/data deletion.
- [ ] Review Google Places attribution and caching requirements.
- [ ] Add event-provider attribution and terms before Local Events+ launches.
- [ ] Configure monitoring, error alerts, quotas, and budget alerts.
- [ ] Back up signing keys and store credentials securely.

