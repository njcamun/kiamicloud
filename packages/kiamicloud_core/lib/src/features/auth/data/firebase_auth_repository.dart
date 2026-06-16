import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../bootstrap/kiami_google_sign_in.dart';
import '../../../firebase/kiami_firebase.dart';
import '../domain/auth_repository.dart';
import '../domain/kiami_user.dart';
import 'google_auth_service.dart';

/// Implementação Firebase Authentication (apenas identidade).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? KiamiGoogleSignIn.createInstance();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<KiamiUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  KiamiUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<KiamiUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  @override
  Future<KiamiUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    _ensureConfigured();
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<KiamiUser> signInWithGoogle() async {
    _ensureConfigured();
    try {
      final userCredential = await GoogleAuthService.signIn(
        auth: _auth,
        googleSignIn: _googleSignIn,
      );
      return _requireUser(userCredential.user);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[GoogleAuth] Erro: $e');
        debugPrint('$stack');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (!KiamiFirebase.isConfigured) return;
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignorar se google_sign_in não estiver activo nesta plataforma.
    }
  }

  void _ensureConfigured() {
    if (!KiamiFirebase.isConfigured) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Firebase nao configurado. Execute flutterfire configure.',
      );
    }
  }

  KiamiUser? _mapUser(User? user) {
    if (user == null) return null;
    return KiamiUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  KiamiUser _requireUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    return mapped;
  }
}
