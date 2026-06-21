import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/upload/upload_queue.dart';
import 'upload_error_report_dialog.dart';

/// Banner visível quando há envios falhados — abre o relatório copiável.
class UploadFailureBanner extends ConsumerWidget {
  const UploadFailureBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref
        .watch(uploadQueueProvider)
        .items
        .where((i) => i.status == UploadQueueItemStatus.failed)
        .toList();
    if (failed.isEmpty) return const SizedBox.shrink();

    final first = failed.first;
    final report = first.errorReport;
    if (report == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showUploadErrorReportDialog(context, report: report),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        KiamiStrings.uploadErrorBannerTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        first.errorMessage ?? first.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      showUploadErrorReportDialog(context, report: report),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(KiamiStrings.uploadErrorBannerAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
