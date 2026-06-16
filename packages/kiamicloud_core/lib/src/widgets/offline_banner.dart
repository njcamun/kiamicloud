import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/connectivity/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!online)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.cloud_off_rounded),
            content: Text(KiamiStrings.offlineBannerMessage),
            actions: [
              TextButton(
                onPressed: () =>
                    ref.invalidate(isOnlineProvider),
                child: const Text('Verificar'),
              ),
            ],
          ),
        Expanded(child: child),
      ],
    );
  }
}
