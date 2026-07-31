# Decide For Us V2 Progress

Last updated: July 30, 2026

## Status summary

| Workstream | Status | Notes |
| --- | --- | --- |
| Phase 0: subscription and recommendation foundation | Merged | PR #29 |
| Phase 1: V2 design system and home experience | Merged | PR #30 |
| Phase 2: paired results experience | Merged | PR #31 |
| Phase 3: Local Events+ | Merged | PR #32 |
| Date Night+ specialization | In review | Draft PR #33; build 37 in store testing |
| Subscription QA and event sharing | In progress | Build 38 passes local validation |
| Planning Engine foundation | In progress | Shared modes, options, and stops |
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
- Event plans can be shared with their time, price, venue, companion stop, and
  verified organizer link.

## Operational work completed

- `REVENUECAT_SECRET_API_KEY` created in Firebase Secret Manager.
- `getIdeas` successfully deployed as a second-generation Cloud Function.
- Firestore IAM failure identified and corrected.
- Google Play Internal Testing already contains version code 30.
- Android release signing remains local and gitignored.
- `TICKETMASTER_API_KEY` created in Firebase Secret Manager.
- `getLocalEvents`, `getEventImage`, and `getPremiumAccess` deployed.
- Google Play license-testing list configured for subscription testing.
- Codemagic signs and publishes the same workflow to TestFlight and Google Play
  Internal Testing.
- Build 37 published successfully to both store testing channels.
- An Apple TestFlight sandbox subscription successfully activated the RevenueCat
  `premium` entitlement and unlocked Date Night+ and Local Events+.

### Date Night+ in PR #33

- Premium-only access still supports explicitly enabled Chrome tester UIDs.
- First Date, Regular Date, Anniversary, and Surprise occasions.
- Cozy, Playful, Romantic, and Adventurous date styles.
- Group selection locks to Couple while Date Night+ is active.
- Occasion-, style-, and energy-specific Google Places searches.
- Occasion-aware ranking favors conversation, celebration, surprise, or
  romance signals as appropriate.
- The strongest activity leads into the dining stop for a more natural date
  flow.
- Tonight, This Weekend, and Plan Ahead timing choices.
- Strong Ticketmaster events can lead a date plan when they match the selected
  occasion and style; weak event matches fall back to permanent places.
- Date-plan event cards include verified organizer links.
- Ordinary Couple mode remains a casual, non-romantic recommendation path.
- Chrome functional validation completed for the Date Night+ controls,
  recommendation flow, and results presentation.
- Premium access refreshes before gated navigation so newly purchased, restored,
  or manually granted access is recognized without an unnecessary paywall.
- The temporary paywall tester tool can copy the installation Firebase UID for
  support during TestFlight and Google Play testing.
- Build 38 passes `flutter analyze` with no issues and all four Flutter tests.

### Planning Engine foundation

- `PlanningMode` defines Quick Decision, Date Night+, Local Events+, and Trip.
- `PlanningStop` adds ordering plus future schedule, travel-time, and cost fields
  while preserving the verified `Activity` provider record.
- `PlanningOption` and `PlanningResponse` support both two-option outings and
  future multi-stop itineraries.
- `DefaultPlanningEngine` is the first shared service boundary and currently adapts
  the existing recommendation endpoint without changing user-facing behavior.
- `DecideScreen` now consumes the Planning Engine response instead of calling the
  recommendation service directly.
- Model serialization and option-pairing tests are added.
- The first Planning Engine slice passes `flutter analyze` with no issues and
  all six Flutter tests.

- `PlanningEngineRequest` now provides one mode-aware contract for present-day
  recommendations and future trips.
- `PlanningLocation` supports labeled origins and destinations.
- `PlanningConstraints` carries radius, travelers, travel intervals, interests,
  and exclusions without expanding screen method signatures.
- The existing Quick Decision and Date Night+ request is adapted into the new
  contract, preserving current backend behavior.
- `PlanningCandidate` normalizes verified places and events with explicit kind,
  provider source, provider ID, and source URL.
- `CandidateProvider` separates candidate collection from itinerary construction.
- Recommendation and Local Events adapters normalize their existing endpoint
  responses without changing shipped UI behavior.
- `DefaultPlanningEngine` accepts an injectable provider, enabling deterministic
  tests and future multi-provider composition.

- `CandidateEvaluator` records deterministic eligibility, rejection reasons,
  scores, and score reasons before option construction.
- Hard filters cover verification, provider identity, required display data,
  coordinates, explicit exclusions, event time windows, known price limits, and
  Local Events mode.
- Soft scoring recognizes provider completeness, energy, interests, group fit,
  and Date Night relevance while retaining provider order for now.

- `PlanningOptionBuilder` now turns eligible, scored candidates into at most two
  complementary options for the current UI.
- Food-with-food pairings are prohibited, and food appears in at most one option.
- Events and activities lead before dining; option anchors prefer different
  category families.
- Configurable stops per option provides the first tested path to multi-stop trip
  itineraries without changing the current two-card presentation.

- `ItineraryScheduler` assigns start times, inferred durations, distance-based
  travel gaps, per-stop costs, and option totals after option construction.
- Verified provider event times remain authoritative.
- Known provider prices are multiplied by traveler count; unknown prices remain
  unknown instead of being invented.
- The scheduler enriches current responses without changing existing card UI.


### Trip Planner+ setup

- Premium-only Trip Planner+ entry added to the home experience.
- The existing RevenueCat and explicit tester-access flow protects navigation.
- Branded setup screen collects origin, destination, dates, travelers, total
  budget, maximum drive interval, interests, and exclusions.
- `TripPlanDraft` owns validation and converts completed setup into the shared
  `PlanningEngineRequest` trip contract.
- Review sheet confirms the trip setup before future route discovery.
- Model and widget coverage protects validation, request conversion, and the
  visible setup flow.

## Must verify before merging PR #33

- Updated `getIdeas` deployed with `TICKETMASTER_API_KEY` access.
- Validate Local Events sharing on iOS and Android.
- Google Play sandbox subscription access (Apple TestFlight verified).
- Date Night+ event links and place fallbacks on real devices.

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
- Remove the temporary Copy Tester ID control before production.

## Trip Planner route discovery

- Added Premium-authenticated `resolveTripRoute` Firebase endpoint.
- Resolves typed origins and destinations without exposing Google credentials.
- Uses the device position when the starting point is Current location.
- Computes verified driving distance, duration, and encoded route geometry.
- Samples up to 12 route-corridor discovery zones using the selected maximum drive interval.
- Trip Planner+ now displays a verified route review before attraction discovery.
- Added route-model parsing and round-trip tests.

- Route confirmation now advances to a dedicated road-trip route page instead of closing back to setup.
- The route page presents verified distance, duration, endpoints, and every corridor discovery zone.

## Corridor discovery implementation

- Added Premium-authenticated `discoverTripStops` Firebase endpoint.
- Searches every route zone for highly rated local food, attractions, scenic stops, history, outdoor options, family activities, and hidden gems based on selected interests.
- Includes Ticketmaster events occurring during the selected trip dates.
- Filters user exclusions and prevents repeated candidates across route zones.
- Route page now loads real, image-backed discoveries instead of coordinate-only placeholders.
- Added discovery-zone model coverage; expected Flutter test total is 26.
