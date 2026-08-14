# Decide For Us

Decide For Us is a Flutter experience-planning app backed by Firebase, Google
Places, and RevenueCat. The free experience helps a user make a quick decision.
Premium is evolving into a planning product for Date Night+, local events,
weekends, and trips.

## Release status

- Source version: `1.0.29+46` on the tester-access release branch.
- Apple: build 45 is in App Review with manual release after approval.
- Google Play: code 45 is active in Internal Testing; refreshed phone
  screenshots are in listing review.
- Build number 45 is consumed on both stores. Start future work from the latest
  `origin/main` and use build number 46 or higher for the next binary.

## Current product behavior

- A decision returns two outing options.
- Each option contains two complementary stops.
- The four recommendations must be unique.
- At most one option should contain a food stop.
- The backend remembers the latest 40 place IDs, approximately 10 decisions,
  to reduce repetition.
- Free users receive three decisions per week.
- Date Night+ and unlimited usage require the RevenueCat `premium` entitlement.
- Google Places photos are delivered through a Firebase proxy so the Google API
  key is not exposed in Flutter.
- Local Events+ discovers upcoming Ticketmaster events within 10, 25, or 50
  miles and includes verified dates, venues, maps, images, and event links.
- Explicit Firestore tester UIDs can receive Premium access during Chrome
  development without changing production entitlement rules.

See the [coder handoff](docs/CODER_HANDOFF.md), [V2 progress](docs/V2_PROGRESS.md),
[roadmap](docs/V2_ROADMAP.md), [architecture](docs/ARCHITECTURE.md),
[forced-update configuration](docs/FORCED_UPDATE.md), and the
[release checklist](docs/RELEASE_CHECKLIST.md).

## Development setup

1. Install Flutter and run:

   ```sh
   flutter pub get
   ```

2. Configure the Firebase apps represented by `lib/firebase_options.dart`.
3. Enable Anonymous authentication in Firebase Authentication. The Firebase
   user ID is also used as the RevenueCat app user ID.
4. Configure RevenueCat:
   - entitlement: `premium`
   - default/current offering
   - monthly and annual packages attached to that offering
5. Configure Firebase Function secrets:

   ```sh
   firebase functions:secrets:set GOOGLE_API_KEY
   firebase functions:secrets:set REVENUECAT_SECRET_API_KEY
   firebase functions:secrets:set TICKETMASTER_API_KEY
   ```

   `REVENUECAT_SECRET_API_KEY` must be a RevenueCat V1 secret key because the
   backend currently reads `/v1/subscribers/{app_user_id}`. Never place a
   RevenueCat secret key in Flutter or GitHub.

6. Grant the Cloud Functions runtime service account the least-privilege
   `Cloud Datastore User` (`roles/datastore.user`) role so it can maintain usage
   and recommendation history in Firestore.
7. Install and deploy Functions:

   ```sh
   npm --prefix functions ci
   firebase deploy --only functions
   ```

## Firebase Functions

- `getIdeas`: authenticates the user, enforces limits and Premium access,
  searches Google Places, avoids recent results, and creates four candidates.
- `getPlacePhoto`: securely proxies a Google Places photo.
- `getLocalEvents`: returns Premium-only upcoming events from Ticketmaster.
- `getEventImage`: securely proxies allowlisted Ticketmaster images.
- `getPremiumAccess`: resolves RevenueCat or Firestore tester access.

## Premium tester builds

TestFlight and Google Play testing builds can grant Premium to every tester,
without collecting Firebase UIDs or requiring sandbox purchases. Enable the
same flag in both the app binary and deployed Functions:

```sh
firebase deploy --only functions
flutter build appbundle --release --dart-define=TESTER_PREMIUM_ACCESS=true
flutter build ipa --release --dart-define=TESTER_PREMIUM_ACCESS=true
```

Before deploying, set `TESTER_PREMIUM_ACCESS=true` in
`functions/.env.decide-for-us-792bc`. The Firebase environment file is
intentionally gitignored; set it in the deployment environment rather than
committing it.

Production binaries must omit the Dart define, and the Functions parameter must
be returned to `false` after tester validation. The server requires both the
enabled parameter and the tester-build request header.

The UID allowlist remains available for controlled development access:

Chrome cannot use RevenueCat mobile purchasing. Add an authenticated anonymous
Firebase UID to Firestore for controlled development access:

```text
premium_testers/{uid}
  enabled: true
```

Use a fixed Flutter web port so the browser origin and anonymous UID remain
stable:

```sh
flutter run -d chrome --web-port 7357
```

Sandbox purchases and Google Play license testing are only required when testing
the actual purchase flow, not when validating Premium features in a tester build.

## Release builds

### Android

Release signing uses the local, gitignored files:

- `android/key.properties`
- the keystore referenced by `storeFile`

Tester build:

```sh
flutter build appbundle --release --dart-define=TESTER_PREMIUM_ACCESS=true
```

Production build:

```sh
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Android reads `versionName` and `versionCode` from `pubspec.yaml`.

### iOS

iOS archives are built on macOS through Codemagic and published to TestFlight.
Every App Store Connect upload requires a previously unused build number.
The authoritative integration branch is `main`; create new branches from the
latest `origin/main` and merge them before expecting Codemagic to build.

## Validation

Run before publishing:

```sh
flutter analyze
flutter test
npm --prefix functions run lint
node --check functions/index.js
```

Do not run `npm audit fix --force` without reviewing the proposed breaking
dependency changes.
