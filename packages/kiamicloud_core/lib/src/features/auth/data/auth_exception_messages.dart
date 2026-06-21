import 'package:firebase_auth/firebase_auth.dart';

/// Mensagens de erro Firebase Auth em português.
abstract final class AuthExceptionMessages {
  static String fromFirebaseAuthException(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'O e-mail não é válido.',
      'user-disabled' => 'Esta conta foi desactivada.',
      'user-not-found' => 'Não existe conta com este e-mail.',
      'wrong-password' => 'Palavra-passe incorrecta.',
      'invalid-credential' => 'E-mail ou palavra-passe incorrectos.',
      'email-already-in-use' => 'Este e-mail já está registado.',
      'weak-password' => 'A palavra-passe é demasiado fraca (mín. 6 caracteres).',
      'operation-not-allowed' => 'Método de autenticação não activado no Firebase.',
      'too-many-requests' => 'Demasiadas tentativas. Tente mais tarde.',
      'network-request-failed' => 'Sem ligação à internet. Verifique a rede.',
      'popup-closed-by-user' => 'Início de sessão Google cancelado.',
      'popup-blocked-by-browser' =>
        'Permita popups para este site ou tente novamente.',
      'redirect-initiated' => 'A redireccionar para o Google…',
      'auth/popup-closed-by-user' => 'Início de sessão Google cancelado.',
      'auth/popup-blocked' =>
        'Popup bloqueado. Permita janelas emergentes para este site.',
      'account-exists-with-different-credential' =>
        'Já existe conta com este e-mail noutro método.',
      'firebase-not-configured' =>
        'Firebase não configurado. Consulte docs/FIREBASE_SETUP.md',
      'google-sign-in-desktop-not-configured' =>
        'Client ID OAuth invalido em google_oauth_client.dart. Use apenas um ID terminado em .apps.googleusercontent.com (sem texto extra).',
      'cancelled-popup-request' => 'Início de sessão Google cancelado.',
      'unknown-error' =>
        e.message?.contains('non-mobile') == true
            ? 'Google no Windows requer Client ID OAuth em google_oauth_client.dart.'
            : (e.message ?? 'Erro de autenticação desconhecido.'),
      _ => e.message ?? 'Ocorreu um erro de autenticação.',
    };
  }

  static String fromObject(Object error) {
    if (error is FirebaseAuthException) {
      return fromFirebaseAuthException(error);
    }
    if (error is StateError) {
      return error.message;
    }
    final text = error.toString();
    if (text.contains('google_sign_in') ||
        text.contains('GoogleSignIn') ||
        text.contains('MissingPluginException')) {
      return 'Google Sign-In não disponível nesta plataforma. '
          'No Windows, configure o OAuth Client ID (docs/FIREBASE_SETUP.md) '
          'ou use e-mail/palavra-passe.';
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
