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

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            KiamiStrings.uploadBackgroundComplete(
              next.succeeded,
              next.failed,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: next.failed > 0 ? 6 : 4),
        ),
      );
      ref.read(uploadBatchResultProvider.notifier).state = null;
    });

    return child;
  }
}
