import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_constants.dart';
import '../features/auth/providers/auth_providers.dart';
import '../theme/kiami_theme.dart';
import 'kiami_theme_scope.dart';

/// Widget raiz partilhado (requer [ProviderScope] no main).
class KiamiApp extends ConsumerStatefulWidget {
  const KiamiApp({super.key});

  @override
  ConsumerState<KiamiApp> createState() => _KiamiAppState();
}

class _KiamiAppState extends ConsumerState<KiamiApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    debugPrint('KiamiApp: initState');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('KiamiApp: a construir...');
    final router = ref.watch(kiamiRouterProvider);

    return KiamiThemeScope(
      themeMode: _themeMode,
      onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      child: MaterialApp.router(
        title: KiamiConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: KiamiTheme.light(),
        darkTheme: KiamiTheme.dark(),
        themeMode: _themeMode,
        routerConfig: router,
      ),
    );
  }
}
