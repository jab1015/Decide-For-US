# Coder Handoff

Last updated: August 11, 2026

## Where to start

After PR #49 is merged, fetch the repository and create all new work from the latest `main`:

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git switch -c codex/<short-description>
```

The release branch `codex/ios-1.0.28-forced-update` is temporary and must not become the base for later work after it is merged.

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
from `assets/icon.png` and is the binary that should be selected for 1.0.28.

## What happens after merge

1. Confirm Codemagic starts a build from the merged `main` commit.
2. Confirm the uploaded build finishes processing in App Store Connect.
3. Select the new build for App Store version 1.0.28.
4. Complete review metadata and submit version 1.0.28 to Apple.
5. Wait until 1.0.28 is publicly downloadable.
6. Only then set Firestore `app_config/version_requirements.ios_min_version` to `1.0.28` if older compatible builds should be blocked.

Do not raise `ios_min_version` before Apple releases 1.0.28. A premature value can send users to an App Store version that is not available yet.

## Forced-update implementation

The app checks Firestore at launch and when returning from the background. Configuration and rollback instructions are in `docs/FORCED_UPDATE.md`. The check fails open during a Firebase/network outage. A build released before the update gate existed cannot be retroactively made to show the blocking UI.

## Known follow-up work

- Verify the Codemagic build and App Store submission for 1.0.28.
- Activate the iOS minimum version only after public release.
- Keep Android testing and its minimum version independent from iOS.
- Review the GitHub Dependabot report separately; do not run forced dependency upgrades as part of a store release.
