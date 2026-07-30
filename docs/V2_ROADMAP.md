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

## Phase 3: Local Events+ — in progress

Local Events+ is subscription-only.

### Completed foundation

- Ticketmaster Discovery is the first verified events source.
- `TICKETMASTER_API_KEY` is stored in Firebase Secret Manager.
- Premium access is enforced by RevenueCat or the explicit Firestore tester
  allowlist.
- Event imagery is delivered through a secure Firebase proxy.
- Chrome testing is verified with live results at 50 miles.

### Next implementation slice

- Pair a strong event with a complementary Google Places stop.
- Keep two meaningfully different outing options.
- Add Today, This Weekend, and Next 14 Days filters.
- Expand automatically from 10 to 25 or 50 miles when coverage is sparse.
- Add group and budget suitability scoring.
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

## Phase 4: Date Night+

- First date, regular date, anniversary, surprise, budget, and splurge intents.
- Romantic, conversation-friendly, scenic, and memorable scoring.
- Date-specific event prioritization.
- Reservation and ticket links when verified.
- Weather and time-of-day awareness.
- No fast food unless explicitly requested.

## Phase 5: Planning Engine

Replace mode-specific service sprawl with:

```text
PlanningRequest
  -> Candidate providers
  -> Eligibility filters
  -> Scoring
  -> Pairing / itinerary builder
  -> PlanningResponse
```

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
- Validate subscriptions in sandbox and production for iOS and Android.
