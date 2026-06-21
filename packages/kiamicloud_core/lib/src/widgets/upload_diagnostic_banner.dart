import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/upload/upload_debug.dart';
import '../features/upload/upload_diagnostic.dart';
import 'upload_error_report_dialog.dart';

/// Banner persistente com o último erro de upload/diagnóstico — sempre visível.
class UploadDiagnosticBanner extends ConsumerWidget {
  const UploadDiagnosticBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(lastUploadDiagnosticProvider);
    if (report == null || report.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        elevation: 2,
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report_outlined, color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      KiamiStrings.uploadDiagnosticBannerTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: KiamiStrings.uploadDiagnosticDismiss,
                    onPressed: () =>
                        ref.read(lastUploadDiagnosticProvider.notifier).state =
                            null,
                    icon: Icon(Icons.close, color: scheme.onErrorContainer),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                KiamiStrings.uploadDiagnosticBannerHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      showUploadErrorReportDialog(context, report: report),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(KiamiStrings.uploadErrorBannerAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
