import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiamicloud_core/kiamicloud_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  await kiamiBootstrap(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    environment: KiamiAppEnvironment.production,
    apiBaseUrl: KiamiConstants.cloudProdApiBaseUrl,
  );
  runApp(
    const ProviderScope(
      child: KiamiApp(),
    ),
  );
}
