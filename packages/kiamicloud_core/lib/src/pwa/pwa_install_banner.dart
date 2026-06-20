import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import 'pwa_install.dart';

final pwaInstallProvider =
    StateNotifierProvider<PwaInstallNotifier, PwaInstallState>((ref) {
  return PwaInstallNotifier();
});

class PwaInstallNotifier extends StateNotifier<PwaInstallState> {
  PwaInstallNotifier() : super(PwaInstallController.initial) {
    if (kIsWeb) {
      PwaInstallController.attach((next) => state = next);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      PwaInstallController.detach();
    }
    super.dispose();
  }

  Future<void> install() => PwaInstallController.promptInstall();

  void dismiss() => PwaInstallController.dismiss();
}

/// Banner para instalar a PWA (Android Chrome) ou instruções iOS.
class PwaInstallBanner extends ConsumerWidget {
  const PwaInstallBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return child;

    final install = ref.watch(pwaInstallProvider);
    if (!install.shouldShowBanner) return child;

    final theme = Theme.of(context);
    final isAndroid = install.canInstallAndroid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 1,
          color: theme.colorScheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.install_mobile_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          KiamiStrings.pwaInstallTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAndroid
                              ? KiamiStrings.pwaInstallAndroidBody
                              : KiamiStrings.pwaInstallIosBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (isAndroid) ...[
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () =>
                                ref.read(pwaInstallProvider.notifier).install(),
                            child: const Text(KiamiStrings.pwaInstallAction),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () =>
                        ref.read(pwaInstallProvider.notifier).dismiss(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
