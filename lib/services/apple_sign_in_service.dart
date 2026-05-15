import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInResult {
  final UserCredential? credential;
  final String? errorMessage;
  final bool cancelled;

  AppleSignInResult({
    this.credential,
    this.errorMessage,
    this.cancelled = false,
  });

  bool get isSuccess => credential != null;
}

class AppleSignInService {
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<AppleSignInResult> signIn() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      return AppleSignInResult(credential: userCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AppleSignInResult(cancelled: true);
      }
      dev.log('AppleSignIn AuthorizationException ${e.code}', error: e);
      return AppleSignInResult(
          errorMessage: 'Apple sign-in failed: ${e.message}');
    } on FirebaseAuthException catch (e, st) {
      dev.log('AppleSignIn FirebaseAuthException ${e.code}',
          error: e, stackTrace: st);
      return AppleSignInResult(
          errorMessage: e.message ?? 'Authentication failed.');
    } catch (e, st) {
      dev.log('AppleSignIn unknown error', error: e, stackTrace: st);
      return AppleSignInResult(errorMessage: 'Apple sign-in failed: $e');
    }
  }
}
