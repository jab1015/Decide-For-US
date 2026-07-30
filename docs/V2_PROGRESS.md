# Decide For Us V2 Progress

Last updated: July 30, 2026

## Status summary

| Workstream | Status | Notes |
| --- | --- | --- |
| Phase 0: subscription and recommendation foundation | Merged | PR #29 |
| Phase 1: V2 design system and home experience | Merged | PR #30 |
| Phase 2: paired results experience | In review | Draft PR #31 |
| Local events provider | Not started | Ticketmaster Discovery is the first recommended provider |
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

### Results experience in PR #31

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
- Temporary tester usage reset that automatically returns to Decide.
- Monthly and yearly RevenueCat packages displayed when both are present in the
  current offering.
- Android release version now follows `pubspec.yaml`.

## Operational work completed

- `REVENUECAT_SECRET_API_KEY` created in Firebase Secret Manager.
- `getIdeas` successfully deployed as a second-generation Cloud Function.
- Firestore IAM failure identified and corrected.
- Google Play Internal Testing already contains version code 30.
- Android release signing remains local and gitignored.

## Must verify before merging PR #31

- `flutter analyze`
- `flutter test`
- Android signed `.aab` build
- TestFlight build with both subscription choices
- Two cards and four distinct stops on a real device
- Photos load for places that provide a Google photo
- Directions and favorites work for all four stops
- Tester reset returns directly to Decide
- Result scrolling anchors to Option One
- Current Firebase Function revisions match the branch

## Known temporary or deferred items

- `resetTesterUsage` must be removed before production.
- Node.js 20 must be upgraded before its October 30, 2026 decommission date.
- Dependency vulnerabilities need a controlled upgrade; do not force-upgrade.
- Ticketmaster/local events are not yet integrated.
- The app still needs a formal trip-planning data model and timeline UI.

