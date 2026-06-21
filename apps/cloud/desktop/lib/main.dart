import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiamicloud_core/kiamicloud_core.dart';

import 'firebase_options.dart';
import 'google_oauth_client.dart';

/// Desktop (Windows) — API Cloudflare beta.
Future<void> main() async {
  await kiamiBootstrap(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    googleDesktopClientId: GoogleOAuthClient.desktopClientId,
    environment: KiamiAppEnvironment.production,
    apiBaseUrl: KiamiConstants.cloudProdApiBaseUrl,
  );
  runApp(
    const ProviderScope(
      child: KiamiApp(),
    ),
  );
}
