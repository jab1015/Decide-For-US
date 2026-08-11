# Forced Update Configuration

Decide For Us now checks Firestore on app startup and whenever the app resumes from the background.

## Firestore document

Create this document in the Firebase project used by the app:

- Collection: `app_config`
- Document: `version_requirements`

Recommended fields:

- `ios_min_version` (string) — minimum iOS app version allowed to continue
- `android_min_version` (string) — minimum Android app version allowed to continue
- `ios_store_url` (string, optional) — override Apple App Store URL
- `android_store_url` (string, optional) — override Google Play URL
- `message` (string, optional) — message displayed on the blocking update screen

The app has built-in store URL fallbacks:

- iOS: `https://apps.apple.com/us/app/decide-for-us/id6760516571`
- Android: `https://play.google.com/store/apps/details?id=com.decideforus.app`

## Example

```text
ios_min_version: 1.0.17
android_min_version: 1.0.25
message: A new version of Decide For Us is required. Update now to continue.
```

Only raise a minimum version after that version is available in the corresponding public store. Setting `ios_min_version` higher than the version Apple currently offers would lock users on the update screen while the App Store has no qualifying version to install.

## Behavior

If the installed version is lower than the configured minimum version:

1. The normal app screen is blocked.
2. A non-dismissible `Update Required` screen is shown.
3. `Update Now` opens the correct app store.
4. When the user returns to the app, the version requirement is checked again.
5. The normal app is available only after the installed version satisfies the minimum.

If Firestore cannot be reached, the check fails open so a Firebase/network outage cannot permanently lock every user out of the app.

## Important limitation

A forced-update gate can only enforce updates from a build that already contains the gate. An older App Store build released before this feature existed cannot be retroactively made to display the new blocking screen. Once a build containing this feature is installed, future minimum-version changes can be enforced remotely through Firestore.
