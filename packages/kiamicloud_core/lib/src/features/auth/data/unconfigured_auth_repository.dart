import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';
import '../domain/kiami_user.dart';

/// Fallback quando Firebase ainda não foi configurado (flutterfire).
class UnconfiguredAuthRepository implements AuthRepository {
  static const String _message =
      'Firebase não configurado. Siga docs/FIREBASE_SETUP.md';

  @override
  Stream<KiamiUser?> authStateChanges() => Stream.value(null);

  @override
  KiamiUser? get currentUser => null;

  @override
  Future<KiamiUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _fail();

  @override
  Future<KiamiUser> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _fail();

  @override
  Future<void> sendPasswordResetEmail({required String email}) => _fail();

  @override
  Future<void> sendEmailVerification() => _fail();

  @override
  Future<void> reloadCurrentUser() => _fail();

  @override
  Future<KiamiUser> signInWithGoogle() => _fail();

  @override
  Future<void> signOut() async {}

  Future<Never> _fail() {
    throw FirebaseAuthException(
      code: 'firebase-not-configured',
      message: _message,
    );
  }
}
