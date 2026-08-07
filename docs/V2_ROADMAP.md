# Decide For Us V2 Roadmap

Last updated: July 31, 2026

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

### Future Local Events+ enhancements

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

## Phase 4: Date Night+ — completed, device testing

- First date, regular date, anniversary, and surprise intents are implemented.
- Cozy, playful, romantic, and adventurous styles are implemented.
- Romantic, conversation-friendly, scenic, and memorable scoring is implemented.
- Date-specific event prioritization is implemented with timing and relevance
  thresholds.
- Chrome functional validation is complete; build 39 is prepared for TestFlight
  and Google Play Internal Testing.
- Apple TestFlight sandbox subscription activation is verified; Google Play
  sandbox purchase validation remains.
- Reservation and ticket links when verified.
- Weather and time-of-day awareness.
- No fast food unless explicitly requested.

## Phase 5: Planning Engine — foundation completed

The Flutter foundation now routes Quick Decision and Date Night+ through a
shared `PlanningEngine` boundary and models responses as ordered options and
stops. Local Events+ retains its specialized provider screen while Trip Planner+ uses
the shared location, constraint, option, stop, and scheduler contracts.

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

## Phase 6: Trip Planner+ — Phase 1 completed

- Premium-only home entry and validated setup
- Verified Google Routes distance, duration, and discovery corridor
- Interest-aware Google Places and date-aware Ticketmaster candidates
- Real images, factual descriptions, and pre-selection research links
- Intentional stop selection and replacement
- Multi-day pacing with authoritative event times
- Saved Trips reopen, edit, update, and delete behavior
- Itinerary navigation to Decide, Saved Trips, and Favorites
- Google Maps GPS route handoff and native sharing/send-to-phone

Optional Phase 2 work is tracked below and does not block Phase 1 release.

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

### Completed: corridor candidates

Query places, events, scenic stops, and local food near each corridor zone, then run them through the shared eligibility, scoring, option-building, and itinerary scheduling pipeline.

- Completed route-review navigation and the dedicated corridor presentation screen.
- Real candidates are fetched, ranked, described, and linked in every discovery zone.

### Complete: real corridor discoveries

- Interest-aware Google Places searches around route zones
- Date-aware Ticketmaster event searches
- Cross-zone duplicate prevention and exclusion filtering
- Loading, retry, empty, and image-fallback states in Trip Planner+

### Completed: itinerary selection

Let travelers select or replace discoveries, then schedule the chosen stops against drive time, trip dates, opening constraints, and the shared itinerary scheduler.

## Current execution point

Trip Planner+ Phase 1 is complete. Build 39 is the current store-testing
candidate. The execution focus is cross-device release validation, production
gates, and selection of the next Premium planning mode.

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

Validated: saved-trip reopening, edit flow, update-in-place behavior, itinerary navigation, Google Maps GPS handoff, and share/send-to-phone behavior.

### Complete: Trip Planner+ Phase 1

- Place-specific descriptions and real provider images
- Check it out and View event links before selection
- Multi-day pacing with authoritative event times
- Saved Trips library with reopen, edit, delete, and update-in-place behavior
- Decide, Saved Trips, and Favorites navigation from itineraries
- Google Maps multi-stop GPS handoff
- Native share/send-to-phone and clipboard fallback
- Clean Flutter analysis and 29 passing tests
- Manual Chrome QA complete

### Trip Planner+ Phase 2 backlog

These are optional enhancements and do not block the completed Phase 1:

1. Hotels, overnight cities, and lodging-aware pacing
2. Automatic stop-order and detour optimization
3. Weather-aware trip rebuilding
4. Reservation and ticket-booking links
5. Fuel, lodging, ticket, and meal cost estimates
6. Account-synced trips across devices
7. Collaborative trip editing
8. Offline itinerary access

