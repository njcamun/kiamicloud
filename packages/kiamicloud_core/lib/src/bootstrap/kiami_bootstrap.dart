import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../api/kiami_api_config.dart';
import '../config/kiami_environment.dart';
import '../constants/kiami_constants.dart';
import '../data/api_endpoint_store.dart';
import '../features/auth/data/google_auth_service.dart';
import '../firebase/kiami_firebase.dart';
import 'kiami_google_sign_in.dart';

/// Inicialização partilhada das apps KiamiCloud.
Future<void> kiamiBootstrap({
  required FirebaseOptions firebaseOptions,
  String? googleDesktopClientId,
  String? googleWebClientId,
  String? apiBaseUrl,
  KiamiAppEnvironment? environment,
}) async {
  debugPrint('kiamiBootstrap: WidgetsFlutterBinding...');
  final binding = WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    debugPrint('kiamiBootstrap: FlutterNativeSplash.preserve...');
    FlutterNativeSplash.preserve(widgetsBinding: binding);
  }

  debugPrint('kiamiBootstrap: KiamiEnvironment.configure...');
  KiamiEnvironment.configure(environment: environment);

  debugPrint('kiamiBootstrap: KiamiFirebase.initialize...');
  await KiamiFirebase.initialize(options: firebaseOptions);

  if (kIsWeb && KiamiFirebase.isConfigured) {
    debugPrint('kiamiBootstrap: Google redirect result (web)...');
    await GoogleAuthService.completeWebRedirectSignIn(
      FirebaseAuth.instance,
    );
  }

  debugPrint('kiamiBootstrap: KiamiGoogleSignIn.registerDesktopIfNeeded...');
  await KiamiGoogleSignIn.registerDesktopIfNeeded(
    desktopClientId: googleDesktopClientId,
    webClientId: googleWebClientId,
  );

  debugPrint('kiamiBootstrap: Configurar API...');
  if (kIsWeb) {
    await ApiEndpointStore.clear();
    final cloudUrl = _resolveWebApiBaseUrl(apiBaseUrl);
    KiamiApiConfig.configure(cloudUrl, mode: KiamiApiEndpointMode.cloud);
    debugPrint('kiamiBootstrap: Web -> $cloudUrl');
  } else {
    var resolvedApi = (apiBaseUrl != null && apiBaseUrl.trim().isNotEmpty)
        ? apiBaseUrl.trim()
        : KiamiConstants.cloudProdApiBaseUrl;

    resolvedApi = await ApiEndpointStore.loadEffectiveUrl(
      cloudDefault: resolvedApi,
    );
    final mode = await ApiEndpointStore.getMode();
    KiamiApiConfig.configure(resolvedApi, mode: mode);
  }

  debugPrint('kiamiBootstrap: Fim.');
}

String _resolveWebApiBaseUrl(String? apiBaseUrl) {
  const fallback = KiamiConstants.cloudProdApiBaseUrl;
  if (apiBaseUrl == null || apiBaseUrl.trim().isEmpty) {
    return fallback;
  }
  final trimmed = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (_looksLikeLocalApiUrl(trimmed)) {
    return fallback;
  }
  return trimmed;
}

bool _looksLikeLocalApiUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('127.0.0.1') ||
      lower.contains('localhost') ||
      lower.contains('192.168.') ||
      lower.contains('10.0.2.2');
}
