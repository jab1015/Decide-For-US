# Coder Handoff

Last updated: August 11, 2026

## Where to start

Fetch the repository and create all new work from the latest `main`:

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git switch -c codex/<short-description>
```

Do not base new work on `codex/ios-1.0.28-forced-update` or another historical
release branch. Build number 45 is already used on both stores; the next binary
must be `1.0.29+46` or another version with build number 46 or higher.

## Current release state

- Source release version: `1.0.28+45`.
- App Store Connect version record: `1.0.28`.
- Public App Store name for the next version: `Decide For Us: What To Do`.
- Publisher remains Jerry Brown.
- Codemagic builds and uploads iOS archives from `main`.
- App Store Connect App ID: `6760516571`.
- Bundle/application ID: `com.decideforus.app`.

Build 43 uploaded successfully but Apple reported ITMS-90683 because
`NSLocationAlwaysAndWhenInUseUsageDescription` was missing. Build 44 adds that
purpose string, but still contained the previously generated launcher icon.
Build 45 regenerates and commits the native iOS and Android launcher assets
from `assets/icon.png` and is the selected 1.0.28 binary on both stores.

### Apple

- Version 1.0.28, build 45 has the corrected icon and required location purpose
  string.
- The submission is in App Review.
- Release is configured as manual. After approval, confirm 1.0.28 is publicly
  downloadable and then click **Release This Version** if Apple still requires
  that action.

### Google Play

- Version 1.0.28, code 45 is active in Internal Testing and available to
  internal testers.
- The refreshed set of three phone screenshots was saved and sent to Google
  for review. Source-ready files are in `store_assets/google_play/`.
- Production access remains separate from Internal Testing and may still
  require completion of Google's closed-testing requirement.

## Next store actions

1. Monitor Apple review for version 1.0.28, build 45.
2. After approval, manually release it and verify its public App Store page.
3. Monitor Google Play Publishing overview until the phone-screenshot change is
   approved.
4. Recruit and retain the testers needed for Google Play production access.
5. Keep both Firestore minimum versions unchanged until a newer qualifying
   store release is available to the audience being forced to update.

Do not raise `ios_min_version` before Apple releases 1.0.28. A premature value can send users to an App Store version that is not available yet.

## Forced-update implementation

The app checks Firestore at launch and when returning from the background. Configuration and rollback instructions are in `docs/FORCED_UPDATE.md`. The check fails open during a Firebase/network outage. A build released before the update gate existed cannot be retroactively made to show the blocking UI.

## Known follow-up work

- Complete Apple review and manual release for 1.0.28.
- Complete Google Play closed testing and production-access requirements.
- Validate monthly and yearly subscriptions with real sandbox/test purchases on
  both platforms.
- Keep Android and iOS minimum versions independent and do not treat Internal
  Testing availability as public production availability.
- Review the GitHub Dependabot report separately; do not run forced dependency upgrades as part of a store release.
