import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Inicialização segura do Firebase (sem expor credenciais no código).
abstract final class KiamiFirebase {
  static bool _configured = false;

  /// True após [initialize] com opções válidas do FlutterFire.
  static bool get isConfigured => _configured;

  /// Inicializa Firebase. Ignora placeholders até `flutterfire configure`.
  static Future<void> initialize({required FirebaseOptions options}) async {
    if (_isPlaceholder(options)) {
      if (kDebugMode) {
        debugPrint(
          '[KiamiFirebase] Nao configurado. Execute: flutterfire configure',
        );
      }
      _configured = false;
      return;
    }

    await Firebase.initializeApp(options: options);
    _configured = true;
  }

  static bool _isPlaceholder(FirebaseOptions options) {
    return options.apiKey.startsWith('YOUR_') ||
        options.projectId.startsWith('YOUR_') ||
        options.appId.startsWith('YOUR_');
  }
}
