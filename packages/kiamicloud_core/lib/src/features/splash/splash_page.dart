import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../routing/kiami_routes.dart';
import '../../utils/kiami_native_splash.dart';
import '../../theme/kiami_colors.dart';
import '../../widgets/kiami_splash_art.dart';

/// Splash única — `splashpage.png` durante pelo menos 3 segundos.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const Duration minDisplayDuration = Duration(seconds: 3);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final DateTime _startedAt = DateTime.now();
  bool _navigated = false;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mostra de imediato a splash Flutter em ecrã inteiro (sem ícone circular nativo).
      removeNativeSplash();
      _tryNavigate();
    });
  }

  Future<void> _tryNavigate() async {
    if (!mounted || _navigated || _navigationScheduled) return;

    final auth = ref.read(authStateProvider);
    if (!auth.hasValue) return;

    _navigationScheduled = true;

    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = SplashPage.minDisplayDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    final user = auth.valueOrNull;
    if (user != null) {
      context.go(KiamiRoutes.home);
    } else {
      context.go(KiamiRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue) _tryNavigate();
    });

    return Scaffold(
      backgroundColor: KiamiColors.deepBlue,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: const KiamiSplashArt(),
      ),
    );
  }
}
