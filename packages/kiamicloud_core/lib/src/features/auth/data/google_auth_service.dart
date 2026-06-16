import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../bootstrap/kiami_google_sign_in.dart';

/// Login Google por plataforma (mobile / web / desktop Windows).
abstract final class GoogleAuthService {
  static Future<UserCredential> signIn({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  }) async {
    if (kIsWeb) {
      return _signInWeb(auth);
    }

    if (_isDesktop) {
      return _signInDesktop(auth: auth, googleSignIn: googleSignIn);
    }

    return _signInWithGoogleSignIn(auth: auth, googleSignIn: googleSignIn);
  }

  static bool get _isDesktop {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Web: popup Firebase (nao usar google_sign_in no browser).
  static Future<UserCredential> _signInWeb(FirebaseAuth auth) async {
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      return await auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'auth/popup-blocked' ||
          e.code == 'popup-blocked' ||
          (e.message?.toLowerCase().contains('popup') ?? false)) {
        throw FirebaseAuthException(
          code: 'popup-blocked-by-browser',
          message: 'O browser bloqueou a janela Google. Permita popups para localhost.',
        );
      }
      rethrow;
    }
  }

  /// Desktop (Windows/macOS/Linux): google_sign_in_dartio + browser OAuth.
  /// signInWithProvider NÃO é suportado no Firebase Auth desktop.
  static Future<UserCredential> _signInDesktop({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  }) async {
    if (!KiamiGoogleSignIn.isDesktopRegistered) {
      throw FirebaseAuthException(
        code: 'google-sign-in-desktop-not-configured',
        message:
            'Configure apps/cloud/desktop/lib/google_oauth_client.dart com o Client ID OAuth.',
      );
    }

    return _signInWithGoogleSignIn(auth: auth, googleSignIn: googleSignIn);
  }

  static Future<UserCredential> _signInWithGoogleSignIn({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  }) async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'popup-closed-by-user');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null && accessToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-desktop-not-configured',
        message:
            'Tokens Google em falta. Verifique o Client ID OAuth no Windows.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    return auth.signInWithCredential(credential);
  }
}
