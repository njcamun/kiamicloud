import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';

/// Regista google_sign_in_dartio no Windows/macOS/Linux (obrigatório para Google).
abstract final class KiamiGoogleSignIn {
  static bool _registered = false;
  static String? _clientId;

  static bool get isDesktopRegistered => _registered;

  /// Client ID OAuth activo (após [registerDesktopIfNeeded]).
  static String? get clientId => _clientId;

  /// Regista implementação desktop e guarda o Client ID.
  static Future<void> registerDesktopIfNeeded({
    required String? desktopClientId,
  }) async {
    if (kIsWeb) return;

    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!isDesktop) return;

    final id = _normalizeClientId(desktopClientId);
    if (id == null) {
      _registered = false;
      _clientId = null;
      if (kDebugMode) {
        debugPrint(
          '[KiamiGoogleSignIn] Client ID OAuth invalido. '
          'Edite apps/cloud/desktop/lib/google_oauth_client.dart — '
          'apenas UM id terminado em .apps.googleusercontent.com',
        );
      }
      return;
    }

    await GoogleSignInDart.register(clientId: id);
    _clientId = id;
    _registered = true;
    if (kDebugMode) {
      debugPrint('[KiamiGoogleSignIn] Registado para desktop.');
    }
  }

  /// Instância [GoogleSignIn] com clientId no desktop quando configurado.
  static GoogleSignIn createInstance() {
    if (_registered && _clientId != null) {
      return GoogleSignIn(clientId: _clientId);
    }
    return GoogleSignIn();
  }

  /// Valida formato Google OAuth Client ID (evita colar placeholder por engano).
  static String? _normalizeClientId(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.contains('YOUR_')) return null;

    // Ex.: id real + "YOUR_....apps.googleusercontent.com" colado por engano
    final suffixCount = '.apps.googleusercontent.com'
        .allMatches(trimmed.toLowerCase())
        .length;
    if (suffixCount != 1) return null;

    final valid = RegExp(
      r'^\d+-[a-z0-9]+\.apps\.googleusercontent\.com$',
      caseSensitive: false,
    ).hasMatch(trimmed);

    return valid ? trimmed : null;
  }
}
