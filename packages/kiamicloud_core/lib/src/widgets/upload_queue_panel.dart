import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/upload/upload_queue.dart';
import '../utils/format_bytes.dart';

/// Painel compacto da fila de uploads.
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
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: _statusIcon(item.status),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.errorMessage ??
                        formatBytes(item.sizeBytes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.status == UploadQueueItemStatus.failed
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
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
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(UploadQueueItemStatus status) {
    return switch (status) {
      UploadQueueItemStatus.pending => const Icon(Icons.schedule_rounded),
      UploadQueueItemStatus.uploading => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      UploadQueueItemStatus.completed =>
        const Icon(Icons.check_circle_outline, color: Colors.green),
      UploadQueueItemStatus.failed =>
        const Icon(Icons.error_outline, color: Colors.red),
    };
  }
}
