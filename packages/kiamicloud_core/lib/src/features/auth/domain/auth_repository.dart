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

  /// Reenvia e-mail de verificação Firebase (contas e-mail/palavra-passe).
  Future<void> sendEmailVerification();

  /// Actualiza claims locais (ex.: após o utilizador clicar no link de verificação).
  Future<void> reloadCurrentUser();

  Future<KiamiUser> signInWithGoogle();

  Future<void> signOut();
}
