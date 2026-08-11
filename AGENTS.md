# Decide For Us - Coder Instructions

## Authoritative branch

- Start all new work from the latest `origin/main`.
- Do not continue from `codex/ios-1.0.28-forced-update` after PR #49 is merged.
- Create a short-lived feature branch from `main` for each change.
- Never commit store credentials, signing files, API secrets, or Firebase secret values.

## Current release baseline

- App release: `1.0.28+45`.
- App Store product name: `Decide For Us: What To Do`.
- Bundle/application ID: `com.decideforus.app`.
- iOS builds are produced by Codemagic after changes reach `main`.
- Every upload must use a unique, increasing build number.

## Required checks

Run `flutter pub get`, `flutter analyze`, and `flutter test` before committing application changes. For Firebase Function changes also run `npm --prefix functions run lint` and `node --check functions/index.js`.

## Forced updates

The app uses Firestore document `app_config/version_requirements`. Read `docs/FORCED_UPDATE.md` before changing minimum versions. Never raise a store's minimum version until that exact version is publicly downloadable. Version 1.0.28 is the verified baseline containing the update gate.

## Release documentation

Before the next release, update `pubspec.yaml`, `codemagic.yaml`, `docs/RELEASE_CHECKLIST.md`, and `docs/CODER_HANDOFF.md` together. Keep this file accurate if the authoritative branch or release process changes.
