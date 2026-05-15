import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInResult {
  final UserCredential? credential;
  final String? errorMessage;
  final bool cancelled;

  GoogleSignInResult({
    this.credential,
    this.errorMessage,
    this.cancelled = false,
  });

  bool get isSuccess => credential != null;
}

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<GoogleSignInResult> signIn() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        log('GoogleSignIn: user cancelled');
        return GoogleSignInResult(cancelled: true);
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        log('GoogleSignIn: idToken is null — OAuth client misconfigured in Firebase');
        return GoogleSignInResult(
            errorMessage:
                'Google account configuration error. Contact support.');
      }

      final OAuthCredential cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(cred);

      return GoogleSignInResult(credential: userCred);
    } on PlatformException catch (e, st) {
      log('GoogleSignIn PlatformException', error: e, stackTrace: st);
      return GoogleSignInResult(errorMessage: _platformErrorMessage(e));
    } on FirebaseAuthException catch (e, st) {
      log('GoogleSignIn FirebaseAuthException ${e.code}',
          error: e, stackTrace: st);
      return GoogleSignInResult(
          errorMessage: e.message ?? 'Authentication failed.');
    } catch (e, st) {
      log('GoogleSignIn unknown error', error: e, stackTrace: st);
      return GoogleSignInResult(errorMessage: 'Google sign-in failed: $e');
    }
  }

  static String _platformErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
        if (e.message?.contains('10:') == true) {
          return 'App not authorized for Google sign-in. SHA-1 missing in Firebase.';
        }
        if (e.message?.contains('12500') == true) {
          return 'Google Play Services error. Update Play Services and try again.';
        }
        if (e.message?.contains('7:') == true) {
          return 'No internet connection.';
        }
        return 'Google sign-in failed: ${e.message ?? e.code}';
      case 'network_error':
        return 'No internet connection.';
      case 'sign_in_canceled':
        return 'Sign-in cancelled.';
      default:
        return 'Sign-in error: ${e.code} ${e.message ?? ''}'.trim();
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
