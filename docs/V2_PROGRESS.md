# Decide For Us V2 Progress

Last updated: July 30, 2026

## Status summary

| Workstream | Status | Notes |
| --- | --- | --- |
| Phase 0: subscription and recommendation foundation | Merged | PR #29 |
| Phase 1: V2 design system and home experience | Merged | PR #30 |
| Phase 2: paired results experience | Merged | PR #31 |
| Phase 3: Local Events+ | In review | Draft PR #32; working in Chrome |
| Date Night+ specialization | Planned | Premium-only |
| Trip Planner+ | Planned | Premium-only |

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

## Operational work completed

- `REVENUECAT_SECRET_API_KEY` created in Firebase Secret Manager.
- `getIdeas` successfully deployed as a second-generation Cloud Function.
- Firestore IAM failure identified and corrected.
- Google Play Internal Testing already contains version code 30.
- Android release signing remains local and gitignored.
- `TICKETMASTER_API_KEY` created in Firebase Secret Manager.
- `getLocalEvents`, `getEventImage`, and `getPremiumAccess` deployed.
- Google Play license-testing list configured for subscription testing.

## Must verify before merging PR #32

- `flutter analyze`
- `flutter test`
- Android signed `.aab` build
- TestFlight build with both subscription choices
- Local Events+ on TestFlight and Google Play Internal Testing.
- Event images, dates, maps, and external links on real devices.
- Monthly and annual sandbox subscription activation through RevenueCat.
- Non-Premium users still reach the paywall.
- Firestore tester access remains limited to explicitly enabled UIDs.
- Current Firebase Function revisions match PR #32.

## Known temporary or deferred items

- Node.js 20 must be upgraded before its October 30, 2026 decommission date.
- Dependency vulnerabilities need a controlled upgrade; do not force-upgrade.
- Ticketmaster coverage is strongest for ticketed events; additional community
  event providers remain planned.
- Ticketmaster does not provide pricing for every event; unknown prices remain
  unlabeled rather than estimated.
- The app still needs a formal trip-planning data model and timeline UI.

