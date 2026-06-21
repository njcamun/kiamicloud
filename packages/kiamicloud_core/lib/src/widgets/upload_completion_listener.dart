import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/kiami_app_keys.dart';
import '../constants/kiami_strings.dart';
import '../features/upload/upload_diagnostic.dart';
import '../features/upload/upload_queue.dart';

/// Notifica o utilizador quando a fila de uploads termina um ciclo.
class UploadCompletionListener extends ConsumerWidget {
  const UploadCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UploadBatchResult?>(uploadBatchResultProvider, (previous, next) {
      if (next == null) return;

      final queue = ref.read(uploadQueueProvider);
      final firstFailed = queue.items
          .where((i) => i.status == UploadQueueItemStatus.failed)
          .firstOrNull;
      final firstFailedMessage = firstFailed?.errorMessage;
      final firstFailedReport = firstFailed?.errorReport;

      final messenger = kiamiScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              next.failed > 0 && firstFailedMessage != null
                  ? '${KiamiStrings.uploadBackgroundComplete(next.succeeded, next.failed)} $firstFailedMessage'
                  : KiamiStrings.uploadBackgroundComplete(
                      next.succeeded,
                      next.failed,
                    ),
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: next.failed > 0 ? 20 : 4),
            action: next.failed > 0 && firstFailedReport != null
                ? SnackBarAction(
                    label: KiamiStrings.uploadSnackCopyError,
                    onPressed: () {
                      presentUploadDiagnostic(
                        context,
                        report: firstFailedReport,
                        ref: ref,
                      );
                    },
                  )
                : null,
          ),
        );
      }

      if (next.failed > 0 && firstFailedReport != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          presentUploadDiagnostic(
            context,
            report: firstFailedReport,
            ref: ref,
          );
        });
      }

      ref.read(uploadBatchResultProvider.notifier).state = null;
    });

    return child;
  }
}
