# Decide For Us

Decide For Us is a Flutter experience-planning app backed by Firebase,
Google Places, and RevenueCat.

## Development setup

1. Install Flutter and run `flutter pub get`.
2. Configure the Firebase apps represented by `lib/firebase_options.dart`.
3. Enable Anonymous authentication in Firebase Authentication. The app uses
   the Firebase user ID as its RevenueCat app user ID.
4. Configure the RevenueCat `premium` entitlement and current offering.
5. Configure the Firebase Function secrets:

   ```sh
   firebase functions:secrets:set GOOGLE_API_KEY
   firebase functions:secrets:set REVENUECAT_SECRET_API_KEY
   ```

   `REVENUECAT_SECRET_API_KEY` must be a RevenueCat secret key with subscriber
   read access. Never place it in the Flutter application.

6. Deploy the recommendation function:

   ```sh
   firebase deploy --only functions
   ```

## Access model

- Firebase anonymous authentication gives each installation a server-verifiable
  identity.
- RevenueCat owns Premium entitlement status.
- Firebase Functions verifies Premium status with RevenueCat.
- Free recommendation usage is counted weekly in Firestore.
- Date Night+ is enforced by both the Flutter interface and Firebase Functions.

## Validation

```sh
flutter analyze
flutter test
npm --prefix functions run lint
node --check functions/index.js
```
