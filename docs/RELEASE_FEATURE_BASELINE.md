# Decide For Us Release Feature Baseline

Last updated: August 26, 2026

This document defines the minimum feature set that must remain present in every release branch and every merge to `main`. The GitHub `V2 Release Baseline` workflow enforces the critical code-level checks below so a release cannot silently drop major V2 features again.

## Protected premium features

### Date Night+

Required behavior:

- Premium-gated Date Night mode remains available from the main Decide screen.
- Enabling Date Night sets the group to Couple without permanently destroying the prior group selection.
- Date Night request data reaches Firebase through `PlanningRequest`.
- Occasion options include Regular date, First date, Anniversary, and Surprise.
- Style options include Romantic and Playful.
- Timing selection remains present, including Tonight.
- Firebase Functions enforce `Date Night+ requires Premium`.
- Date Night uses the same location/radius safeguards as standard recommendations.

Primary implementation:

- `lib/screens/decide_screen.dart`
- `lib/models/planning_request.dart`
- `lib/services/ai_service.dart`
- `functions/index.js`

### Local Events+

Required behavior:

- Premium-gated Local Events entry remains available from the main Decide screen.
- `LocalEventsScreen` remains present and reachable.
- Today, Weekend, and Next 14 Days discovery remains supported.
- 10, 25, and 50 mile searches remain supported, including disclosed adaptive widening when appropriate.
- Event date/time, venue/address, provider image, verified event link, map link, and companion outing behavior remain available when provider data supports them.
- Ticketmaster remains protected by the Firebase secret and backend premium gate.
- Firebase Functions retain `getLocalEvents` and `getEventImage`.

Primary implementation:

- `lib/screens/local_events_screen.dart`
- `lib/screens/decide_screen.dart`
- `lib/services/ai_service.dart`
- `functions/index.js`
- `functions/providers/ticketmaster.js`

### Trip Planner+

Required behavior:

- Premium-gated Trip Planner entry remains available from the main Decide screen.
- Planner, route review, itinerary, and saved-trips screens remain present and connected.
- Route resolution and along-route stop discovery remain backed by Firebase Functions.
- Saved trip plans remain stored and reloadable.
- Trip Planner models/services required for route, pacing, selection, and persistence remain in the repository.
- Firebase Functions retain `resolveTripRoute` and `discoverTripStops`.

Primary implementation:

- `lib/screens/trip_planner_screen.dart`
- `lib/screens/trip_route_screen.dart`
- `lib/screens/trip_itinerary_screen.dart`
- `lib/screens/saved_trips_screen.dart`
- `lib/services/trip_route_service.dart`
- `lib/services/trip_plan_storage.dart`
- `lib/services/trip_itinerary_pacer.dart`
- `functions/index.js`

## Protected core behavior

Every release must also preserve:

- Standard Decide recommendations with two options / four stops.
- Location-based recommendation behavior and server-side radius enforcement.
- Recent-result avoidance / no-repeat history.
- Favorites.
- Google Places imagery with fallback behavior.
- Directions links.
- Firebase authentication.
- RevenueCat Premium entitlement and restore flow.
- Weekly free-use enforcement.
- Tester access only through the explicit tester mechanisms used for test builds.
- Forced-update support.

## Merge rule

`main` is the authoritative known-good source. Feature/release branches are temporary. A branch must not replace `main` as the source of truth.

Before merging any app change to `main`:

1. The `V2 Release Baseline` GitHub workflow must pass.
2. `flutter analyze` and `flutter test` must pass for release-impacting Flutter changes.
3. Backend syntax/deployment validation must pass for Firebase Function changes.
4. Any platform-specific release validation required by `docs/RELEASE_CHECKLIST.md` must pass.
5. Date Night+, Local Events+, and Trip Planner+ must remain explicitly represented in `docs/V2_PROGRESS.md` and this baseline.

If a protected feature is intentionally removed or substantially redesigned, this document and the baseline workflow must be changed deliberately in the same reviewed pull request. A missing protected feature must never be accepted merely because the app still compiles.
