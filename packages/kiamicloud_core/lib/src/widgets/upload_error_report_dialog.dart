import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/kiami_strings.dart';

/// Diálogo com relatório técnico de upload — seleccionável e copiável.
Future<void> showUploadErrorReportDialog(
  BuildContext context, {
  required String report,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(KiamiStrings.uploadErrorReportTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: SelectableText(
            report,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(KiamiStrings.uploadErrorReportClose),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(KiamiStrings.uploadErrorReportCopied),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(KiamiStrings.uploadErrorReportCopy),
        ),
      ],
    ),
  );
}
