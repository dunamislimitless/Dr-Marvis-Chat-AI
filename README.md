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
  auth_service_test.dart
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

   **Android (Google Sign-In):**

   - After you add **SHA-1** and **SHA-256** for `com.example.emotional_chat`, download a fresh **`google-services.json`** into `android/app/`. The file should list **Web** and **Android** entries under **`oauth_client`** (not an empty array `[]`). An empty `oauth_client` commonly causes **“No credential available”** from Android’s Credential Manager until fingerprints are registered and the file is updated.
   - Align the **Web** client ID in three places: `.env` → **`GOOGLE_SERVER_CLIENT_ID`**, `strings.xml` → **`default_web_client_id`**, and the Web entry inside `google-services.json` / `oauth_client`.
   - Set **`GOOGLE_ANDROID_CLIENT_ID`** in `.env` and **`google_android_client_id`** in `strings.xml` to the **Android** OAuth client (same ID shown in Google Cloud for your Android app). This keeps configuration explicit; sign-in still relies on **`serverClientId`** (Web) plus package name + signing cert.
   - Rebuild the Android app after changes (not hot reload).

   If Gradle reports a **duplicate `default_web_client_id`** after `oauth_client` is populated in `google-services.json`, remove the manual `default_web_client_id` line from `strings.xml` and rely on the merged value from the updated JSON (or keep a single source of truth and avoid duplication).

4. Add a `.env` file at the project root (see `flutter` assets in `pubspec.yaml` — it must list `.env`):

   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

   **Google Sign-In (required for Firebase Auth with Google):**

   | Variable | Role |
   |----------|------|
   | `GOOGLE_SERVER_CLIENT_ID` | **Web** OAuth client ID (`*.apps.googleusercontent.com`). Used as `serverClientId` so Google returns an **ID token** for Firebase. Must match `android/app/src/main/res/values/strings.xml` → `default_web_client_id`. |
   | `GOOGLE_IOS_CLIENT_ID` | **iOS** OAuth client ID (same as `CLIENT_ID` in `GoogleService-Info.plist` and `GIDClientID` in `Info.plist`). |
   | `GOOGLE_ANDROID_CLIENT_ID` | **Android** OAuth client ID — same value as `google_android_client_id` in `strings.xml`. Documented for parity; `google_sign_in` on Android does **not** use the Dart `clientId` parameter (the OS uses your app package + SHA-1 + `google-services.json`). |

   Minimal example:

   ```env
   GEMINI_API_KEY=your_api_key_here
   GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
   GOOGLE_IOS_CLIENT_ID=yyyy.apps.googleusercontent.com
   GOOGLE_ANDROID_CLIENT_ID=zzzz.apps.googleusercontent.com
   ```

   Copy the Web and client IDs from Firebase Console → Project settings → *Your apps*, or Google Cloud → APIs & Services → Credentials.

   Without `GOOGLE_SERVER_CLIENT_ID`, Google may not return an **ID token**, and Firebase sign-in will fail even after adding SHA-1.

5. Run the app:

   ```bash
   flutter run
   ```

## Testing

This project includes widget tests, unit tests, and pure logic tests for auth error strings.

- `test/widget_test.dart`
  - Builds `EmotionalSupportApp(testHome: ChatScreen())` so **`AuthGate` is skipped** and no Firebase initialization is required for the test run.
  - `EmotionalSupportApp` still provides `AuthService` and `ChatProvider` via `MultiProvider`, matching production wiring.
  - Asserts chat title, “View Mood Trends”, hint text, and send affordance.

- `test/chat_provider_test.dart`
  - Mood tracking: case-insensitive keywords, unmatched text, date ranges for `moodCountsForLastDays`.
  - `sendMessage()` with empty input does not enqueue messages.

- `test/auth_service_test.dart`
  - `formatAuthError()` maps `GoogleSignInException` cases (for example **canceled** and **unknownError** with “No credential available”) and `StateError` to user-facing strings.

Run all tests:

```bash
flutter test
```

Run a specific test file:

```bash
flutter test test/widget_test.dart
flutter test test/chat_provider_test.dart
flutter test test/auth_service_test.dart
```

## Notes

- Chat responses rely on a reachable Gemini endpoint and valid API key.
- Mood tracking is keyword-based and currently checks for `happy`, `sad`, and `anxious`.
- Do **not** commit real API keys or production `google-services.json` / `GoogleService-Info.plist` to public repos. Add `.env` to `.gitignore` if you share the project.
- Until Firebase is configured, the app starts but shows instructions on the sign-in screen instead of `ChatScreen`.