# Decide For Us V2 Progress

Last updated: August 26, 2026

## Status summary

| Workstream | Status | Notes |
| --- | --- | --- |
| Phase 0: subscription and recommendation foundation | Merged | PR #29 |
| Phase 1: V2 design system and home experience | Merged | PR #30 |
| Phase 2: paired results experience | Merged | PR #31 |
| Phase 3: Local Events+ | Implemented; store validation pending | Premium-only |
| Date Night+ specialization | Implemented; store validation pending | Premium-only |
| Trip Planner+ | Implemented; store validation pending | Premium-only |
| Google Play 2026 quality readiness | In progress; Phase 1 implemented | Memory/code optimization + device migration |

## Completed

### Foundation

- Firebase initializes before the Flutter app starts.
- Anonymous Firebase authentication gives each installation a server-verifiable
  identity.
- RevenueCat is initialized for iOS and Android and uses the Firebase user ID.
- Purchase and restore flows update the `premium` entitlement.
- Free usage is enforced server-side at three decisions per week.
- Date Night+ is gated in both Flutter and Firebase Functions.
- Function secrets are stored in Secret Manager.
- The Functions runtime service account has Firestore data access through the
  Cloud Datastore User role.

### Design system

- Warm cream, indigo, coral, lavender, and supporting design tokens.
- Reusable spacing, radii, gradients, shadows, buttons, and selection groups.
- Time-aware home greeting.
- Premium Date Night+ card.
- Responsive DECIDE control.
- Updated Favorites and Premium visual treatments.

### Results experience

- Two option cards with two stops each.
- Four distinct recommendations per decision.
- No food-with-food pairing; at most one option contains food.
- Recent-result avoidance using the last 40 place IDs.
- Secure Google Places photo proxy with branded image fallback.
- Place-specific descriptions using matched activity type, rating, review
  count, card position, and Date Night context.
- Directions links and per-stop favorites.
- Automatic scroll to the first results card.
- DECIDE disabled until group, budget, and energy are selected.
- Persistent user-facing location and backend errors.
- Monthly and yearly RevenueCat packages displayed when both are present in the
  current offering.
- Android release version now follows `pubspec.yaml`.
- Recommendation search results are post-filtered by actual geographic distance
  so Explore stays regional instead of accepting distant Google Places matches.

### Local Events+ in PR #32

- Ticketmaster Discovery provider protected by `TICKETMASTER_API_KEY`.
- Premium-only `getLocalEvents` endpoint for upcoming nearby events.
- Event metadata includes date, time, venue, address, coordinates, image, and
  verified event URL.
- Local Events+ home entry and branded event-discovery screen.
- 10, 25, and 50-mile event searches over the next 14 days.
- Event links, map links, pull-to-refresh, and empty/error states.
- Secure `getEventImage` proxy resolves browser CORS restrictions.
- Firestore `premium_testers/{uid}` allowlist supports Chrome testing without
  weakening production subscription checks.
- Testers bypass weekly free usage while RevenueCat subscribers continue to use
  the normal entitlement flow.
- Temporary tester usage reset UI and Function removed.
- Chrome validation completed with live events at a 50-mile radius.
- Events can be paired with a unique, verified Google Places add-on within
  five miles.
- Today, This Weekend, and Next 14 Days date filters.
- Sparse searches expand from 10 to 25 or 50 miles and disclose the expanded
  radius in the interface.
- Local Events+ group and total-budget controls influence event ranking and
  companion searches.
- Verified Ticketmaster price ranges appear when the provider supplies them.

### Google Play 2026 quality readiness — Phase 1

Google Play's August 26, 2026 developer notice has been converted into active
engineering work instead of being left as a future compliance reminder.

Implemented on `feature/google-play-quality-2026`:

- Android remains on `compileSdk = 36` and `targetSdk = 36`.
- Release builds now enable R8 code minification and Android resource shrinking.
- `proguard-android-optimize.txt` plus an app-specific `proguard-rules.pro` are
  wired into the release build.
- Android 12+ `dataExtractionRules` explicitly scope cloud backup and
  device-to-device transfer to Flutter's `FlutterSharedPreferences.xml`.
- Legacy `fullBackupContent` rules provide the equivalent scoped behavior on
  older Android versions.
- Cloud backup is disabled when the device/account cannot provide encryption
  capability for the scoped backup payload.
- Firebase authentication stores, native credential stores, signing material,
  API secrets, and other app-private files are not intentionally included in
  the migration rules.
- This scoped state covers local Flutter SharedPreferences data such as
  Favorites and saved Trip Planner plans.

## Operational work completed

- `REVENUECAT_SECRET_API_KEY` created in Firebase Secret Manager.
- `getIdeas` successfully deployed as a second-generation Cloud Function.
- Firestore IAM failure identified and corrected.
- Android release signing is configured for Codemagic through the protected
  `Decide_Google` keystore.
- `TICKETMASTER_API_KEY` created in Firebase Secret Manager.
- `getLocalEvents`, `getEventImage`, and `getPremiumAccess` deployed.
- Google Play license-testing list configured for subscription testing.
- Firestore-controlled forced-update handling added for iOS and Android.
- App Store product name selected as `Decide For Us: What To Do`.
- Native iOS and Android icons were regenerated from `assets/icon.png`.
- Google Play and Apple release workflows are manual-only in Codemagic to avoid
  accidental store uploads.
- Trip Planner+ and the full Date Night+ occasion/style/timing experience were
  restored to the current V2 baseline.

Current store-release handoff and branch instructions live in
`docs/CODER_HANDOFF.md`; new work starts from the latest `main`.

## Store validation still required

- `flutter analyze`
- `flutter test`
- Android signed `.aab` build with R8/resource shrinking enabled.
- TestFlight build with both subscription choices.
- Local Events+ on TestFlight and Google Play Internal Testing.
- Event images, dates, maps, and external links on real devices.
- Monthly and annual sandbox subscription activation through RevenueCat.
- Non-Premium users still reach the paywall.
- Firestore tester access remains limited to explicitly enabled UIDs.
- Current Firebase Function revisions match the intended `main` revision.
- Android 12+ device-to-device migration test.
- Android cloud-backup/restore test with encrypted backup capability.
- Confirm Favorites and saved Trip Planner plans return after migration.
- Confirm migrated installs safely re-establish Firebase identity/session state
  and RevenueCat subscription access or restore purchases as designed.
- Review Play Console's new memory/quality diagnostics and Android vitals using
  a release build before declaring the new Google quality work complete.

## Known temporary or deferred items

- Node.js 20 must be upgraded before its October 30, 2026 decommission date.
- Dependency vulnerabilities need a controlled upgrade; do not force-upgrade.
- Ticketmaster coverage is strongest for ticketed events; additional community
  event providers remain planned.
- Ticketmaster does not provide pricing for every event; unknown prices remain
  unlabeled rather than estimated.
- Google Play's final enforcement details for the newly announced migration
  standard must be reviewed in Play Console as they become available; do not
  add credential-transfer behavior that conflicts with anonymous Firebase Auth.
- Runtime memory and bitmap work remains measurement-driven: review Play Console
  diagnostics and profile real devices before making broad caching/image changes.
