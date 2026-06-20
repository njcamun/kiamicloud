import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/upload/upload_queue.dart';

/// Notifica o utilizador quando a fila de uploads termina um ciclo.
class UploadCompletionListener extends ConsumerWidget {
  const UploadCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UploadBatchResult?>(uploadBatchResultProvider, (previous, next) {
      if (next == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      final queue = ref.read(uploadQueueProvider);
      final firstFailed = queue.items
          .where((i) => i.status == UploadQueueItemStatus.failed)
          .map((i) => i.errorMessage)
          .whereType<String>()
          .firstOrNull;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            next.failed > 0 && firstFailed != null
                ? '${KiamiStrings.uploadBackgroundComplete(next.succeeded, next.failed)} $firstFailed'
                : KiamiStrings.uploadBackgroundComplete(
                    next.succeeded,
                    next.failed,
                  ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: next.failed > 0 ? 8 : 4),
        ),
      );
      ref.read(uploadBatchResultProvider.notifier).state = null;
    });

    return child;
  }
}
