# Decide For Us V2 Roadmap

Last updated: July 30, 2026

## Product promise

Free answers: **What should we do?**

Premium answers: **Plan the experience for us.**

## Phase 2: paired results — completed

- PR #31 merged.
- Confirm both cards contain two unique, complementary stops.
- Confirm Google photo coverage and fallbacks.
- Refine descriptions with verified provider data only.
- Preserve the 10-decision no-repeat window.
- Complete TestFlight and Google Play Internal Testing.

## Phase 3: Local Events+ — device testing

Local Events+ is subscription-only.

### Completed foundation

- Ticketmaster Discovery is the first verified events source.
- `TICKETMASTER_API_KEY` is stored in Firebase Secret Manager.
- Premium access is enforced by RevenueCat or the explicit Firestore tester
  allowlist.
- Event imagery is delivered through a secure Firebase proxy.
- Chrome testing is verified with live results at 50 miles.
- Strong events can include unique Google Places companion stops.
- Today, This Weekend, and Next 14 Days filters are implemented.
- Sparse searches expand automatically to 25 or 50 miles.
- Group and total-budget suitability influence event order and companion stops.
- Verified provider prices appear when available.
- Complete event plans can be shared through the native platform share sheet.

### Next implementation slice

- Keep two meaningfully different outing options.
- Add community-event providers after provider terms and quotas are reviewed.

### Provider architecture

- Formalize the current Ticketmaster module behind an `EventProvider` interface.
- Normalize events and permanent places into a shared candidate model.
- Record provider, source URL, start/end time, venue, coordinates, image, price,
  and event status.
- Never invent event names, times, venues, or ticket availability.
- Ignore cancelled, past, distant, or low-quality events.
- Cache event queries by geohash and time window to control cost and quota.

### Pairing rules

- Prefer an eligible event for one Premium option when a strong event exists.
- Do not force an event when coverage or relevance is weak.
- Pair an event with a complementary place or activity.
- Never pair food with food.
- Keep the second option meaningfully different.

## Phase 4: Date Night+ — in progress

- First date, regular date, anniversary, and surprise intents are implemented.
- Cozy, playful, romantic, and adventurous styles are implemented.
- Romantic, conversation-friendly, scenic, and memorable scoring is in
  progress.
- Date-specific event prioritization is implemented with timing and relevance
  thresholds.
- Chrome functional validation is complete; build 37 is available through
  TestFlight and Google Play Internal Testing.
- Apple TestFlight sandbox subscription activation is verified; Google Play
  sandbox purchase validation remains.
- Reservation and ticket links when verified.
- Weather and time-of-day awareness.
- No fast food unless explicitly requested.

## Phase 5: Planning Engine — foundation in progress

The Flutter foundation now routes Quick Decision and Date Night+ through a
shared `PlanningEngine` boundary and models responses as ordered options and
stops. Local Events+ and Trip Planner+ will migrate onto the same contract in
subsequent slices.

Target architecture:

```text
PlanningRequest
  -> Candidate providers
  -> Eligibility filters
  -> Scoring
  -> Pairing / itinerary builder
  -> PlanningResponse
```

Foundation delivered:

- shared Premium-aware planning modes
- reusable ordered stops with schedule, travel-time, and cost fields
- reusable options and serializable planning responses
- adapter around the current verified recommendation endpoint
- existing Decide UI preserved while the service boundary changes
- shared origin/destination and constraint models for multi-stop planning
- compatibility adapter from the current recommendation request
- shared candidate model for verified places and events
- provider contract with recommendation and Local Events adapters
- deterministic eligibility and explainable candidate scoring
- complementary, category-aware option construction
- configurable multi-stop option support for Trip Planner+
- timeline scheduling, travel gaps, duration estimates, and known-cost totals

Core inputs:

- mode
- location and radius
- start/end time
- budget
- group
- energy
- interests and exclusions
- weather
- recent history
- subscription capabilities

## Phase 6: Trip Planner+

- Premium home entry and validated trip setup form completed.
- Origin, destination, dates, travelers, budget, drive interval, interests, and
  exclusions map to the shared Planning Engine request.

- Origin, destination, dates, travelers, budget, and maximum drive interval.
- Along-route attractions, meals, scenic stops, events, charging, and lodging.
- Multi-day timeline with travel-time feasibility.
- Replace, reorder, save, share, and regenerate individual stops.
- Estimated cost and route-impact summaries.

## Phase 7: personalization and retention

- Explicit likes, dislikes, exclusions, and accessibility needs.
- Saved outings and trip collections.
- “Never suggest again.”
- Weekly local-event digest.
- Seasonal suggestions and weather-triggered replanning.
- Privacy controls and memory reset.

## Launch gates

- Audit and disable Firestore tester documents before production.
- Upgrade the Functions runtime from Node.js 20.
- Complete privacy policy, terms, subscription disclosure, and account/data
  deletion flows.
- Confirm provider terms, attribution, caching, and image requirements.
- Add monitoring, alerting, budgets, rate limiting, and abuse protection.
- Validate Google Play sandbox subscriptions and both stores in production.
- Remove temporary tester-ID UI and audit tester access before launch.

## Trip Planner+ delivery status

### Complete: route foundation

- Origin and destination setup
- Date, travelers, budget, pace, interests, and exclusions
- Protected destination resolution
- Verified driving route, distance, and duration
- Route-corridor discovery zones

### Next: corridor candidates

Query places, events, scenic stops, and local food near each corridor zone, then run them through the shared eligibility, scoring, option-building, and itinerary scheduling pipeline.

- Completed route-review navigation and the dedicated corridor presentation screen.
- Next implementation slice: fetch and rank real candidates around each discovery zone.

### Complete: real corridor discoveries

- Interest-aware Google Places searches around route zones
- Date-aware Ticketmaster event searches
- Cross-zone duplicate prevention and exclusion filtering
- Loading, retry, empty, and image-fallback states in Trip Planner+

### Next: itinerary selection

Let travelers select or replace discoveries, then schedule the chosen stops against drive time, trip dates, opening constraints, and the shared itinerary scheduler.

## Current execution point

Trip Planner+ has completed its route and live-discovery foundation. The next delivery slice is **traveler choice and itinerary generation**.

Planned order:

1. Add select/skip controls for every discovery.
2. Enforce a practical stop count based on trip length and dates.
3. Allow replacement of an individual recommendation without rebuilding the route.
4. Feed selected stops into the shared itinerary scheduler.
5. Present a day-by-day timeline with driving legs and estimated visit durations.
6. Save the generated trip under the existing saved-plan architecture.
7. Add share/export behavior.
8. Add destination-area discoveries and overnight planning in a later slice.

Acceptance criteria for the next milestone:

- A traveler can intentionally choose stops rather than receiving a fixed list.
- The app prevents impossible or overcrowded itineraries.
- Events retain authoritative start times.
- Food, activities, and events remain varied.
- The finished plan clearly separates driving time from activity time.
- Users can return to the saved itinerary after leaving the planner.

### Implemented: traveler choice and first-pass itinerary

- One intentional selection per corridor zone
- Toggle and replace behavior
- Zone-order preservation
- Shared scheduler integration
- Timed itinerary presentation

Completed after the first-pass itinerary:

- Multi-day pacing rolls late non-event activities to the next morning.
- Live events retain their authoritative provider start time.
- Trips can be saved locally, reopened from Saved Trips, returned to selection for changes, and deleted.

Next validation focus: saved-trip reopening across restarts, edit flow clarity, and share/export behavior.
