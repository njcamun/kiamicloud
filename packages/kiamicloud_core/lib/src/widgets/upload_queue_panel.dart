import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/upload/upload_queue.dart';
import 'upload_error_report_dialog.dart';
import '../utils/format_bytes.dart';

/// Painel compacto da fila de uploads com barra de progresso por ficheiro.
class UploadQueuePanel extends ConsumerWidget {
  const UploadQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(uploadQueueProvider);
    if (queue.activeCount == 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (queue.isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      KiamiStrings.uploadQueueTitle(queue.activeCount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...queue.items.take(6).map((item) {
                final isUploading =
                    item.status == UploadQueueItemStatus.uploading;
                final isFailed = item.status == UploadQueueItemStatus.failed;
                final percent = (item.progress * 100).round().clamp(0, 100);
                final report = item.errorReport;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: _statusIcon(item.status, item.progress),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.errorMessage ??
                            (isUploading
                                ? KiamiStrings.uploadProgressPercent(percent)
                                : formatBytes(item.sizeBytes)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isFailed
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      if (isFailed && report != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => showUploadErrorReportDialog(
                              context,
                              report: report,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(KiamiStrings.uploadErrorBannerAction),
                          ),
                        ),
                      ],
                      if (isUploading) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: item.progress.clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: item.status == UploadQueueItemStatus.failed
                      ? IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          tooltip: KiamiStrings.uploadQueueRetry,
                          onPressed: () => ref
                              .read(uploadQueueProvider.notifier)
                              .retry(item.id),
                        )
                      : item.status == UploadQueueItemStatus.pending
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => ref
                                  .read(uploadQueueProvider.notifier)
                                  .remove(item.id),
                            )
                          : null,
                  onTap: isFailed && report != null
                      ? () => showUploadErrorReportDialog(
                            context,
                            report: report,
                          )
                      : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(UploadQueueItemStatus status, double progress) {
    return switch (status) {
      UploadQueueItemStatus.pending => const Icon(Icons.schedule_rounded),
      UploadQueueItemStatus.uploading => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress > 0 ? progress.clamp(0.05, 1.0) : null,
          ),
        ),
      UploadQueueItemStatus.completed =>
        const Icon(Icons.check_circle_outline, color: Colors.green),
      UploadQueueItemStatus.failed =>
        const Icon(Icons.error_outline, color: Colors.red),
    };
  }
}
