import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiamicloud_core/kiamicloud_core.dart';

import 'firebase_options.dart';
import 'google_oauth_client.dart';

/// Web — API Cloudflare beta.
Future<void> main() async {
  debugPrint('KiamiCloud: A iniciar bootstrap...');
  try {
    await kiamiBootstrap(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      googleWebClientId: GoogleOAuthClient.webClientId,
      environment: KiamiAppEnvironment.beta,
      apiBaseUrl: KiamiConstants.cloudBetaApiBaseUrl,
    );
    debugPrint('KiamiCloud: Bootstrap concluido.');
  } catch (e, stack) {
    debugPrint('KiamiCloud: ERRO no bootstrap: $e');
    debugPrint(stack.toString());
  }

  runApp(
    const ProviderScope(
      child: KiamiApp(),
    ),
  );
}
