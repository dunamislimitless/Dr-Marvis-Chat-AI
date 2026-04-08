import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Maps Google / Firebase auth failures into readable steps for debugging.
String formatAuthError(Object error) {
  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'You canceled Google sign-in.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Sign-in was interrupted. Try again.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return 'Google Sign-In is misconfigured on iOS.\n\n'
              '• Firebase Console → Project settings → download a fresh GoogleService-Info.plist '
              '(it must include CLIENT_ID and REVERSED_CLIENT_ID).\n'
              '• Copy CLIENT_ID into ios/Runner/Info.plist → GIDClientID.\n'
              '• Copy REVERSED_CLIENT_ID into Info.plist → CFBundleURLTypes → CFBundleURLSchemes.\n'
              '• Set GOOGLE_IOS_CLIENT_ID and GOOGLE_SERVER_CLIENT_ID in .env, then rebuild (not hot reload).';
        }
        return 'Google Sign-In is misconfigured.\n\n'
            '• Firebase Console → Project settings → Your Android app: add SHA-1 and SHA-256.\n'
            '• Download a fresh google-services.json into android/app/.\n'
            '• In .env set GOOGLE_SERVER_CLIENT_ID to the Web client ID '
            '(…apps.googleusercontent.com) from the same page.\n'
            '• Fully restart the app (not hot reload).';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Play Services or the Sign-In provider is unavailable. '
            'Update Google Play Services and try again.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Sign-in UI could not be shown. Try again in a moment.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Account mismatch. Sign out of Google on the device and try again.';
      case GoogleSignInExceptionCode.unknownError:
        final desc = error.description ?? error.toString();
        if (desc.contains('No credential available')) {
          return 'Google Sign-In could not find a credential for this app.\n\n'
              '• Firebase Console → Project settings → Your Android app '
              '(com.example.emotional_chat): add SHA-1 and SHA-256 '
              '(cd android && ./gradlew signingReport shows debug fingerprints).\n'
              '• Download a fresh google-services.json into android/app/ '
              '(oauth_client must list your Web and Android OAuth clients).\n'
              '• Ensure a Google account is signed in on the device/emulator and Google Play services is up to date.\n'
              '• Use an emulator image **with Google Play**, not “Google APIs” only.\n\n'
              'Details: $desc';
        }
        return desc;
    }
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-disabled':
        return '${error.message ?? error.code}\n\n'
            'Check GOOGLE_SERVER_CLIENT_ID, SHA fingerprints, and google-services.json.';
      default:
        return error.message ?? error.code;
    }
  }
  if (error is StateError) {
    return error.message;
  }
  return error.toString();
}

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    final serverRaw = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim();
    final serverClientId =
        serverRaw != null && serverRaw.isNotEmpty ? serverRaw : null;

    final iosRaw = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();
    final iosClientId =
        iosRaw != null && iosRaw.isNotEmpty ? iosRaw : null;

    final androidRaw = dotenv.env['GOOGLE_ANDROID_CLIENT_ID']?.trim();
    final androidClientId =
        androidRaw != null && androidRaw.isNotEmpty ? androidRaw : null;

    /// Prefer the **iOS** OAuth client from Firebase (`CLIENT_ID` in GoogleService-Info.plist).
    /// If unset, fall back to the Web client so sign-in can still initialize (add a dedicated
    /// iOS client in Firebase + plist for production).
    final String? effectiveIosClientId =
        iosClientId ?? serverClientId;

    if (serverClientId != null) {
      debugPrint('[Auth] Using GOOGLE_SERVER_CLIENT_ID from .env');
    } else {
      debugPrint(
        '[Auth] GOOGLE_SERVER_CLIENT_ID not set — Android may not return an ID token for Firebase. '
        'Add the Web client ID to .env.',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (iosClientId != null) {
        debugPrint('[Auth] iOS: using GOOGLE_IOS_CLIENT_ID from .env');
      } else if (effectiveIosClientId != null) {
        debugPrint(
          '[Auth] iOS: GOOGLE_IOS_CLIENT_ID empty — using Web client for GoogleSignIn clientId. '
          'Download GoogleService-Info.plist from Firebase (must include CLIENT_ID), set '
          'GOOGLE_IOS_CLIENT_ID + Info.plist GIDClientID + URL scheme for production.',
        );
      }
    }

    // Android: `clientId` is ignored by google_sign_in_android — the app is identified by
    // package name + signing cert (see Firebase SHA-1 + google-services.json oauth_client).
    if (defaultTargetPlatform == TargetPlatform.android &&
        androidClientId != null) {
      debugPrint(
        '[Auth] GOOGLE_ANDROID_CLIENT_ID is set (strings.xml / docs only on Android; '
        'Sign-In uses package + SHA + Web serverClientId).',
      );
    }

    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS
              ? effectiveIosClientId
              : null,
    );
    _googleInitialized = true;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    final googleAuth = account.authentication;

    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      throw StateError(
        defaultTargetPlatform == TargetPlatform.iOS
            ? 'Google returned no ID token on iOS. Set GOOGLE_IOS_CLIENT_ID and '
                'GOOGLE_SERVER_CLIENT_ID in .env, set GIDClientID and CFBundleURLTypes '
                'in ios/Runner/Info.plist (see README), then rebuild.'
            : 'Google returned no ID token. On Android, set GOOGLE_SERVER_CLIENT_ID in .env '
                'to your Firebase Web OAuth client ID (…apps.googleusercontent.com), '
                'ensure SHA-1/SHA-256 are registered, then restart the app.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }
}
