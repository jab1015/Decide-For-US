# Decide For Us V2 Roadmap

Last updated: August 26, 2026

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
- Strong events can include unique Google Places companion stops.
- Today, This Weekend, and Next 14 Days filters are implemented.
- Sparse searches expand automatically to 25 or 50 miles.
- Group and total-budget suitability influence event order and companion stops.
- Verified provider prices appear when available.

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

## Google Play 2026 quality readiness — in progress

Google Play notified Modern Methods on August 26, 2026 of upcoming quality
requirements covering app memory/code optimization and secure, seamless device
migration. This is now a release-readiness workstream rather than a deferred
maintenance item.

### Implement now

- Keep `compileSdk` and `targetSdk` at Android API 36 or newer.
- Enable R8 code shrinking and Android resource shrinking for release builds.
- Preserve user-created local state during supported Android cloud backup and
  device-to-device transfer using explicit backup rules.
- Limit Android backup scope to Flutter SharedPreferences so favorites, saved
  Trip Planner plans, and non-sensitive app preferences can migrate without
  intentionally copying Firebase authentication stores, secrets, signing data,
  or other native credential material.
- Require encrypted cloud-backup capability for the scoped backup payload.

### Validate before production

- Build a signed Android release through Codemagic with shrinking enabled and
  verify there are no reflection/serialization regressions.
- Test Android 12+ cloud restore and device-to-device migration.
- Verify Favorites and saved Trip Planner plans survive migration.
- Verify a migrated install can refresh Firebase authentication safely and that
  RevenueCat purchase restoration/subscription access works as intended.
- Review Google Play Console memory/quality diagnostics and Android vitals for
  real release builds rather than assuming R8 alone satisfies runtime-memory
  requirements.
- Measure decoded network-image memory and add bounded image decoding/cache
  dimensions where Play Console or device profiling shows unnecessary bitmap
  pressure.
- Review Google's final migration/onboarding enforcement guidance when the
  detailed deadline and test criteria are visible in Play Console; do not add
  credential-transfer behavior without validating it against the app's
  anonymous Firebase identity model.

## Launch gates

Current release checkpoint: restored V2 features are on the current `main` and
Codemagic provides manual iOS and Android release workflows. Keep store release
build numbers monotonic and validate both platforms before production rollout.

- Audit and disable Firestore tester documents before production.
- Upgrade the Functions runtime from Node.js 20.
- Complete privacy policy, terms, subscription disclosure, and account/data
  deletion flows.
- Confirm provider terms, attribution, caching, and image requirements.
- Add monitoring, alerting, budgets, rate limiting, and abuse protection.
- Validate subscriptions in sandbox and production for iOS and Android.
- Release the first build containing the forced-update gate before raising any
  Firestore platform minimum version.
- Keep `docs/CODER_HANDOFF.md` and the release checklist current at every store
  submission.
- Complete the Google Play 2026 memory/code-optimization and device-migration
  validation gates before the next production Android rollout.
