# Decide For Us Architecture

Last updated: July 31, 2026

## System overview

```text
Flutter app
  |-- Firebase Authentication (anonymous user)
  |-- RevenueCat SDK (Firebase UID as app user ID)
  |
  `-- HTTPS + Firebase ID token
        |
        v
Firebase Functions
  |-- verify Firebase identity
  |-- verify Premium through RevenueCat V1 API or tester allowlist
  |-- enforce weekly free usage
  |-- read/write recommendation history
  |-- search Google Places
  |-- search Ticketmaster Discovery
  |-- proxy Google Places photos
  `-- proxy Ticketmaster event images
        |
        v
Flutter renders paired outings, live events, and multi-stop trip itineraries
```

## Flutter application

### Entry and identity

`lib/main.dart` initializes Firebase, signs in anonymously when necessary,
initializes RevenueCat, and then starts `DecideApp`.

### Recommendation request

`PlanningRequest` contains:

- group
- budget
- energy
- Date Night flag
- Date Night occasion, style, and timing
- latitude and longitude
- radius in miles

`AIService` sends the request and Firebase ID token to `getIdeas`.
It also requests normalized live events from `getLocalEvents`.

### Planning Engine boundary

`PlanningEngine` is the shared Flutter service contract for creating a plan.
`DefaultPlanningEngine` currently adapts the existing `getIdeas` response so the
current recommendation behavior stays stable while the app migrates.

`CandidateProvider` is the collection boundary. Recommendation and Local Events
providers convert existing `Activity` responses into `PlanningCandidate` records
with an explicit place/event kind, source, provider ID, verification state, and
source URL. The engine consumes candidates and remains independent of a specific
external provider.


`CandidateEvaluator` runs before option construction. It returns an explainable
`CandidateEvaluation` containing eligibility, rejection reasons, a bounded score,
and score reasons. The engine currently removes ineligible candidates without
reordering eligible provider results; later itinerary ranking can use the score.


`PlanningOptionBuilder` consumes eligible evaluations. It selects distinct
category anchors, prevents food-with-food pairings, limits food to one option,
orders events or activities before food, and emits ordered `PlanningStop`
records. Its configurable stop count supports paired outings and implemented
multi-stop itineraries.


`ItineraryScheduler` enriches the selected options after construction. It assigns
ordered start times when a request supplies a start, preserves verified event
times, infers conservative durations, estimates travel gaps from coordinates,
and totals only provider-known prices across the traveler count.

The normalized planning model is:

```text
PlanningEngineRequest
  -> PlanningMode
  -> PlanningLocation (origin and optional destination)
  -> PlanningConstraints
  -> PlanningResponse
       -> PlanningOption (one candidate outing or itinerary)
            -> PlanningStop (ordered Activity plus schedule/travel/cost fields)
```

Quick Decision and Date Night+ use this boundary. Local Events+ retains its
specialized provider screen. Trip Planner+ uses the shared request, location,
constraint, option, stop, scheduler, and pacing models for multi-stop plans.

### Presentation

- `DecideScreen` owns the current selections and request lifecycle.
- `ExperienceCard` renders one two-stop option.
- `LocalEventsScreen` renders upcoming live events with distance filters,
  verified links, maps, companion stops, and native plan sharing.

- `TripPlannerScreen` collects and validates trip setup through `TripPlanDraft`.
- `TripRouteScreen` renders verified corridor discoveries and traveler selection.
- `TripItineraryScreen` renders, saves, edits, shares, and hands completed routes
  to Google Maps.
- `SavedTripsScreen` reopens and deletes device-local trip plans.
- `DecisionCard` remains the single-place presentation used by Favorites.
- Favorites are stored locally in `SharedPreferences`.

Longer term, screen orchestration can move into a planning controller/state
layer as personalization and collaborative planning expand.

## Firebase Functions

### `getIdeas`

1. Verify the Firebase bearer token.
2. Resolve Premium access through RevenueCat or `premium_testers/{uid}`.
3. Reject Date Night+ for non-Premium users.
4. Validate location and constraints.
5. Read the last 40 recommended place IDs.
6. Search Google Places using activity and food query sets.
7. For Date Night+, optionally search Ticketmaster within the selected timing
   window and retain only a relevant event.
8. Filter duplicates, low ratings, budget mismatches, and recent results.
9. Score Date Night+ candidates by occasion, style, and energy.
10. Select four unique candidates and arrange the strongest date activity
    before its dining stop.
11. Allow food in at most one option.
12. Consume one free weekly request when the user is not Premium.
13. Save the selected provider IDs to recommendation history.
14. Return four normalized `Activity` records.

### `getPlacePhoto`

Accepts a Google photo reference, retrieves the image with the protected Google
API key, and returns a cacheable image response. The Flutter app never receives
the Google API key.

### `getLocalEvents`

Requires Premium access, queries Ticketmaster for upcoming events near the
provided coordinates, and returns normalized `Activity` records.

### `getEventImage`

Proxies image responses only from approved Ticketmaster image domains. This
keeps browser behavior consistent without creating an unrestricted proxy.

### `getPremiumAccess`

Returns whether the authenticated user has the RevenueCat `premium` entitlement
or an enabled Firestore tester record. Flutter refreshes this status before gated
navigation so recent purchases, restores, grants, and tester changes are honored.

## Firestore data

### `recommendation_usage/{uid_week}`

- `uid`
- `week`
- `count`
- `updatedAt`

### `recommendation_history/{uid}`

- `recentIds`: newest-first list capped at 40 IDs
- `updatedAt`

### `premium_testers/{uid}`

- `enabled`: boolean

This collection is server-read only. It provides controlled Premium access for
anonymous Firebase users during development and store testing. A temporary paywall control copies the current Firebase UID for tester support
and must be removed before production.

The Functions runtime service account requires `roles/datastore.user`.
Firestore mobile-client rules do not replace server IAM for Admin SDK calls.

## RevenueCat

- Flutter uses platform public SDK keys.
- Firebase uses `REVENUECAT_SECRET_API_KEY`.
- The backend currently calls RevenueCat API V1.
- Entitlement identifier: `premium`.
- The current/default offering should contain monthly and annual packages.
- Firebase UID and RevenueCat app user ID must remain identical.
- Apple TestFlight and Google Play test purchases are expected to appear as
  sandbox transactions and activate the same `premium` entitlement.

## Secrets

Required Firebase Function secrets:

- `GOOGLE_API_KEY`
- `REVENUECAT_SECRET_API_KEY`
- `TICKETMASTER_API_KEY`

Secrets must never be committed, logged, returned to Flutter, or placed in
Codemagic build output.

## Current limitations

- Ticketmaster primarily covers ticketed events and does not replace broader
  community-event coverage.
- Trip descriptions use Google editorial summaries when available and factual
  type, locality, rating, and review fallbacks otherwise.
- Favorites and Saved Trips are device-local; account sync is not implemented.
- Event/place pairing and trip routing are implemented; weather-aware replanning,
  lodging, and automatic detour optimization are not.
- Date Night+ timing is a preference window, not a reservation or guaranteed
  availability check.
- Free usage is weekly, but there is no user-facing countdown/reset date yet.

## Trip route boundary

Flutter calls `TripRouteService`, which sends a Firebase ID token and route setup to the Premium-only `resolveTripRoute` function. Firebase owns the Google credential, geocodes text locations, calls Google Routes, decodes the returned polyline, and returns only normalized route data.

```text
Trip Planner UI
  -> TripRouteService (Firebase ID token)
  -> resolveTripRoute (Premium/tester authorization)
  -> Geocoding API + Routes API
  -> normalized endpoints, distance, duration, polyline, corridor zones
```

Route-corridor points are planning inputs rather than recommendations. The discovery provider searches around those points before traveler selection, scheduling, pacing, persistence, and Maps handoff produce the final trip.

## Trip corridor discovery boundary

After `resolveTripRoute` returns normalized endpoints, route geometry, and sampled corridor zones, Flutter calls `TripRouteService.discoverStops`. The Premium-only `discoverTripStops` function coordinates the live provider search.

```text
TripRouteScreen
  -> TripRouteService.discoverStops (Firebase ID token)
  -> discoverTripStops
       -> Premium/tester authorization
       -> interest-to-query mapping
       -> Google Places searches per corridor zone
       -> Ticketmaster searches within trip dates
       -> exclusion filtering
       -> cross-zone duplicate prevention
       -> category-diverse candidate selection
  -> List<TripDiscoveryZone>
  -> image-backed discovery cards
```

Key rules:

- Provider credentials never enter Flutter.
- At most eight sampled corridor zones are searched in one request.
- Each zone returns at most three candidates.
- A live event may occupy one candidate position.
- Place candidates must satisfy the existing minimum rating threshold.
- Candidate identifiers are unique across the complete route response.
- Short routes without intermediate corridor points search around the destination.
- Corridor discovery produces candidates, not a finalized itinerary.

Traveler selections are stored as Planning Stops and passed through the shared Itinerary Scheduler. Event start times remain authoritative; non-event stops receive estimated duration and travel gaps.

## Trip selection-to-itinerary boundary

The route screen owns temporary selection state as a map of corridor-zone index to candidate ID. This guarantees no more than one chosen stop per zone while making replacement deterministic. Selected candidates are restored in zone order and converted to `PlanningStop` values inside one `PlanningOption`.

The existing `ItineraryScheduler` then assigns:

- sequential start times beginning at 9:00 AM on the departure date;
- estimated driving gaps between selected places;
- category-aware visit durations;
- price estimates when provider pricing exists; and
- authoritative Ticketmaster start times for events.

The scheduled `PlanningOption` passes through `TripItineraryPacer`, which moves late non-event stops to the next day while preserving authoritative event times. `TripItineraryScreen` can persist the draft, route, and itinerary through `TripPlanStorage`. `SavedTripsScreen` reconstructs those models for reopening, supports deletion, and returns travelers to the existing route-selection screen when they choose to change stops. Storage is currently device-local through SharedPreferences; account-synced Firestore storage remains a later boundary.

## Trip research and navigation boundary

Trip discovery candidates carry normalized provider metadata through `Activity`, including image, event URL, Google place URL, address, coordinates, and a place-specific description. Firebase requests Google editorial summaries when available; otherwise it produces a factual fallback from place type, locality, rating, and review count.

The candidate tile separates two intentions:

- tapping the tile selects or replaces that stop;
- Check it out / View event opens the provider detail page without changing selection.

## Trip handoff boundary

`TripHandoffService` converts the completed itinerary into a standard Google Maps Directions URL:

```text
origin
  -> selected itinerary stops as ordered waypoints
  -> destination
```

The same URL is included in native share text. On mobile, users can open the route for GPS navigation or share it through Messages, email, AirDrop, and installed apps. When browser-native sharing is unavailable, the complete itinerary and route link are copied to the clipboard.

Itinerary navigation exposes Decide home, Saved Trips, and Favorites without discarding persisted trip data.

## Trip Planner+ Phase 1 architecture status

Phase 1 is complete. Its stable boundaries are:

1. Premium authorization
2. Route resolution
3. Corridor provider discovery
4. Candidate inspection and selection
5. Itinerary scheduling and multi-day pacing
6. Device-local persistence and editing
7. Google Maps and native-share handoff

Phase 2 may add account-synced storage, lodging, route-order optimization, weather replanning, reservations, and collaborative editing without replacing these boundaries.

