# Forced Update Configuration

Last updated: August 11, 2026

Decide For Us checks Firestore on app startup and whenever the app resumes from the background.

## Firestore document

Create this document in the Firebase project used by the app:

- Collection: `app_config`
- Document: `version_requirements`

Recommended fields:

- `ios_min_version` (string) - minimum iOS app version allowed to continue
- `android_min_version` (string) - minimum Android app version allowed to continue
- `ios_store_url` (string, optional) - override Apple App Store URL
- `android_store_url` (string, optional) - override Google Play URL
- `message` (string, optional) - message displayed on the blocking update screen

Built-in store URL fallbacks:

- iOS: `https://apps.apple.com/us/app/decide-for-us/id6760516571`
- Android: `https://play.google.com/store/apps/details?id=com.decideforus.app`

## Example

```text
ios_min_version: 1.0.28
android_min_version: 1.0.28
message: A new version of Decide For Us is required. Update now to continue.
```

Only raise a minimum version after that version is publicly available in the corresponding store. Setting `ios_min_version` higher than the version Apple currently offers can lock users on an update screen while no qualifying download exists.

For the 1.0.28 release, leave the existing iOS minimum unchanged while Apple
reviews and publishes build 45. Android 1.0.28+45 is currently available only
through Internal Testing, so Internal Testing alone is not a reason to raise the
production Android minimum.

Version 1.0.28 is the first release containing the gate on both platforms. It
cannot force users running older, pre-gate binaries. Treat it as the baseline:
release a later version, verify that later version is downloadable by the
intended audience, and only then raise that platform's minimum above 1.0.28.

## Behavior

If the installed version is lower than the configured minimum version:

1. The normal app screen is blocked.
2. A non-dismissible `Update Required` screen is shown.
3. `Update Now` opens the correct app store.
4. When the user returns, the requirement is checked again.
5. The normal app is available only after the installed version satisfies the minimum.

If Firestore cannot be reached, the check fails open so a Firebase/network outage cannot permanently lock every user out.

## Rollback

Lower the platform minimum to the previous supported version to relax enforcement. Deleting or emptying that platform's minimum disables enforcement. Confirm the change on a real device before relying on it as an incident response.

## Important limitation

A forced-update gate can only enforce updates from a build that already contains the gate. An older store build released before this feature existed cannot be retroactively made to display the blocking screen. Version 1.0.28 is the verified baseline for future enforcement.
