import 'kiami_user.dart';

/// Contrato de autenticação (Firebase na implementação).
abstract class AuthRepository {
  Stream<KiamiUser?> authStateChanges();

  KiamiUser? get currentUser;

  Future<KiamiUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<KiamiUser> registerWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<KiamiUser> signInWithGoogle();

  Future<void> signOut();
}
