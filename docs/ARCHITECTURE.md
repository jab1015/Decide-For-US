# Decide For Us Architecture

Last updated: July 30, 2026

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
Flutter renders two option cards with two stops each
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
- latitude and longitude
- radius in miles

`AIService` sends the request and Firebase ID token to `getIdeas`.
It also requests normalized live events from `getLocalEvents`.

### Presentation

- `DecideScreen` owns the current selections and request lifecycle.
- `ExperienceCard` renders one two-stop option.
- `LocalEventsScreen` renders upcoming live events with distance filters,
  verified links, and maps.
- `DecisionCard` remains the single-place presentation used by Favorites.
- Favorites are stored locally in `SharedPreferences`.

Longer term, screen orchestration should move into a planning controller/state
layer before Date Night+, events, and trips substantially expand.

## Firebase Functions

### `getIdeas`

1. Verify the Firebase bearer token.
2. Resolve Premium access through RevenueCat or `premium_testers/{uid}`.
3. Reject Date Night+ for non-Premium users.
4. Validate location and constraints.
5. Read the last 40 recommended place IDs.
6. Search Google Places using activity and food query sets.
7. Filter duplicates, low ratings, budget mismatches, and recent results.
8. Select four unique candidates.
9. Allow food in at most one option.
10. Consume one free weekly request when the user is not Premium.
11. Save the selected place IDs to recommendation history.
12. Return four normalized `Activity` records.

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
or an enabled Firestore tester record.

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
anonymous Firebase users during Chrome development.

The Functions runtime service account requires `roles/datastore.user`.
Firestore mobile-client rules do not replace server IAM for Admin SDK calls.

## RevenueCat

- Flutter uses platform public SDK keys.
- Firebase uses `REVENUECAT_SECRET_API_KEY`.
- The backend currently calls RevenueCat API V1.
- Entitlement identifier: `premium`.
- The current/default offering should contain monthly and annual packages.
- Firebase UID and RevenueCat app user ID must remain identical.

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
- Descriptions are structured from Places metadata rather than editorial or AI
  prose.
- Favorites are device-local and store individual stops, not full itineraries.
- Event/place pairing, weather, routing, and travel-time logic are not yet
  implemented.
- Free usage is weekly, but there is no user-facing countdown/reset date yet.
