import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../api/kiami_api_config.dart';
import '../config/kiami_environment.dart';
import '../constants/kiami_constants.dart';
import '../data/api_endpoint_store.dart';
import '../firebase/kiami_firebase.dart';
import 'kiami_google_sign_in.dart';

/// Inicialização partilhada das apps KiamiCloud.
Future<void> kiamiBootstrap({
  required FirebaseOptions firebaseOptions,
  String? googleDesktopClientId,
  String? apiBaseUrl,
  KiamiAppEnvironment? environment,
}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  KiamiEnvironment.configure(environment: environment);
  await KiamiFirebase.initialize(options: firebaseOptions);
  await KiamiGoogleSignIn.registerDesktopIfNeeded(
    desktopClientId: googleDesktopClientId,
  );

  var resolvedApi = (apiBaseUrl != null && apiBaseUrl.trim().isNotEmpty)
      ? apiBaseUrl.trim()
      : KiamiConstants.cloudBetaApiBaseUrl;

  resolvedApi = await ApiEndpointStore.loadEffectiveUrl(
    cloudDefault: resolvedApi,
  );

  final mode = await ApiEndpointStore.getMode();
  KiamiApiConfig.configure(resolvedApi, mode: mode);
}
