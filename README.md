# Dr. Marvis Chat AI

A Flutter app for emotional support conversations. The app includes onboarding, a chat interface backed by Gemini, and a mood-trends chart derived from user messages.

## Features

- **Google Sign-In** via Firebase Auth (signup and login are the same flow with Google)
- **Cloud Firestore** persistence for chat history per user (`users/{uid}/messages`)
- AI chat experience using the Gemini API
- Mood tracking (`Happy`, `Sad`, `Anxious`) from user text, synced with loaded history
- Mood visualization screen using `fl_chart`
- State management with `provider`

## Tech Stack

- Flutter (Material UI)
- Dart
- `provider` for app state
- Firebase Core, Firebase Auth, Google Sign-In, Cloud Firestore
- `http` for API calls
- `fl_chart` for mood chart visualization
- `flutter_dotenv` for environment variables (Gemini key)

## Project Structure

```text
lib/
  main.dart
  firebase_options.dart   # Run flutterfire configure to generate real values
  feature/
    auth/
      auth_gate.dart
      auth_screen.dart
      auth_service.dart
    ai chat/
      views/
        onboarding.dart
        chat_screen.dart
        mood_chart_screen.dart
      view-model/
        chat_provider.dart
firestore.rules          # Example rules — deploy in Firebase Console
test/
  widget_test.dart
  chat_provider_test.dart
```

## Setup

1. Install Flutter SDK and verify:

   ```bash
   flutter --version
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase (required for sign-in and chat history):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This overwrites `lib/firebase_options.dart` and links your Firebase project. Then in the [Firebase Console](https://console.firebase.google.com/):

   - Enable **Authentication** → Sign-in method → **Google**.
   - Enable **Cloud Firestore** (start in test mode for development, then deploy rules below).
   - Download **google-services.json** into `android/app/`.
   - Download **GoogleService-Info.plist** into `ios/Runner/`.
   - For Android release/debug, add your app’s **SHA-1** (and **SHA-256**) in Project settings so Google Sign-In works.

   Deploy Firestore rules so users can only read/write their own messages (see `firestore.rules` in this repo). Example:

   ```text
   users/{userId}/messages/{messageId} → allow if request.auth.uid == userId
   ```

   **iOS (Google Sign-In):** Some Firebase downloads omit **`CLIENT_ID`** / **`REVERSED_CLIENT_ID`** in `GoogleService-Info.plist`. That is normal if the iOS OAuth client was never created. You can fix it in either order:

   **A) Prefer:** Firebase Console → Project settings → your **iOS** app → **Download GoogleService-Info.plist** again after the iOS app is registered with bundle ID `com.example.emotionalChat`. If the new file still has no `CLIENT_ID`, use **B**.

   **B) Manual (Google Cloud):** Use the **same Google Cloud project** as Firebase (`marvis-ai-202` or the project ID shown in Firebase settings).

   1. Open [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
   2. **Create credentials** → **OAuth client ID** (complete the OAuth consent screen if prompted).
   3. Application type: **iOS**.
   4. **Bundle ID:** `com.example.emotionalChat` (must match Xcode **Runner** target).
   5. Create, then copy the **Client ID** (ends with `.apps.googleusercontent.com`). That string is your **`CLIENT_ID`** for iOS.

   **Build `REVERSED_CLIENT_ID` (URL scheme) from the Client ID:**

   - If the Client ID is `123456789-abcXYZ.apps.googleusercontent.com`, then **`REVERSED_CLIENT_ID`** is `com.googleusercontent.apps.123456789-abcXYZ` (prefix `com.googleusercontent.apps.` + the part before `.apps.googleusercontent.com`).

   **Put the values here:**

   - `ios/Runner/GoogleService-Info.plist` — add keys (optional but handy):

     ```xml
     <key>CLIENT_ID</key>
     <string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
     <key>REVERSED_CLIENT_ID</key>
     <string>com.googleusercontent.apps.YOUR_PREFIX</string>
     ```

   - `ios/Runner/Info.plist` → **`GIDClientID`** = same as **Client ID** above  
   - `ios/Runner/Info.plist` → **`CFBundleURLTypes` / `CFBundleURLSchemes`** = **`REVERSED_CLIENT_ID`** above  
   - `.env` → **`GOOGLE_IOS_CLIENT_ID`** = same as **Client ID** above  

   **`GIDServerClientID`** in `Info.plist` should match your **Web** OAuth client (same as `GOOGLE_SERVER_CLIENT_ID` in `.env`).  
   The app already falls back to the Web client for `GoogleSignIn` if `GOOGLE_IOS_CLIENT_ID` is empty, but **`Info.plist` URL scheme** still needs **`REVERSED_CLIENT_ID`** for the OAuth redirect to work.  
   Rebuild the iOS app (not hot reload) after changes.

   **Android (Google Sign-In):** After you add **SHA-1** / **SHA-256**, download **`google-services.json` again**. Open it and confirm **`oauth_client`** is not empty — if it is still `[]`, Google Sign-In will not work until fingerprints are correct and the file is refreshed.

   Align these (same **Web** client ID everywhere):

   - `.env` → **`GOOGLE_SERVER_CLIENT_ID`**
   - `android/app/src/main/res/values/strings.xml` → **`default_web_client_id`** (must match the Web client ID)

   The app also passes `serverClientId` from `.env` in Dart; keep **`.env`** and **`strings.xml`** in sync when you rotate keys. Rebuild Android after changes (not hot reload).

   If Gradle reports a **duplicate `default_web_client_id`** resource after `oauth_client` is filled in `google-services.json`, remove the manual line from `strings.xml` and rely on the value generated from the updated JSON.

4. Add a `.env` file at the project root for Gemini:

   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

   For **Google Sign-In on Android**, also add the **Web client ID** (OAuth 2.0 client of type *Web*, ending in `.apps.googleusercontent.com`). You can copy it from Firebase Console → Project settings → General → *Your apps* (Web) or Google Cloud → APIs & Credentials:

   ```env
   GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
   ```

   Without this, Google may not return an **ID token**, and Firebase sign-in will fail even after adding SHA-1.

5. Run the app:

   ```bash
   flutter run
   ```

## Testing

This project includes both widget and unit tests.

- `test/widget_test.dart`
  - Pumps `ChatScreen` with `EmotionalSupportApp(testHome: ...)` (no Firebase required).
  - Verifies chat title, mood trends button, and input/send controls.

- `test/chat_provider_test.dart`
  - Verifies mood tracking increments correctly (case-insensitive).
  - Verifies unmatched text does not change mood counters.
  - Verifies `sendMessage()` exits safely with empty input.

Run all tests:

```bash
flutter test
```

Run a specific test file:

```bash
flutter test test/widget_test.dart
flutter test test/chat_provider_test.dart
```

## Notes

- Chat responses rely on a reachable Gemini endpoint and valid API key.
- Mood tracking is keyword-based and currently checks for `happy`, `sad`, and `anxious`.
- Do **not** commit real API keys or production `google-services.json` / `GoogleService-Info.plist` to public repos. Add `.env` to `.gitignore` if you share the project.
- Until Firebase is configured, the app starts but shows instructions on the sign-in screen instead of `ChatScreen`.