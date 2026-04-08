import 'package:emotional_chat/feature/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  group('formatAuthError', () {
    test('maps canceled Google sign-in to a short user message', () {
      const err = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User canceled',
      );
      expect(formatAuthError(err), contains('canceled'));
    });

    test(
      'expands Android Credential Manager "No credential available" into setup steps',
      () {
        const err = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'No credential available: nothing to show',
        );
        final out = formatAuthError(err);
        expect(out, contains('Google Sign-In could not find a credential'));
        expect(out, contains('SHA-1'));
        expect(out, contains('google-services.json'));
        expect(out, contains('nothing to show'));
      },
    );

    test('passes through unknown errors without the no-credential phrase', () {
      const err = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Some other failure',
      );
      expect(formatAuthError(err), 'Some other failure');
    });

    test('returns StateError message', () {
      expect(
        formatAuthError(StateError('Custom auth failure')),
        'Custom auth failure',
      );
    });
  });
}
