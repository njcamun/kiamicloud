import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/kiami_strings.dart';
import '../routing/kiami_routes.dart';
import '../utils/format_bytes.dart';

/// Diálogo quando o ficheiro ou a quota impedem o upload.
Future<void> showQuotaLimitDialog(
  BuildContext context, {
  required String title,
  required String message,
  int? fileSizeBytes,
  int? availableBytes,
  bool suggestUpgrade = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.cloud_off_outlined),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (fileSizeBytes != null && availableBytes != null) ...[
            const SizedBox(height: 12),
            Text(
              KiamiStrings.quotaLimitDialogSizes(
                formatBytes(fileSizeBytes),
                formatBytes(availableBytes),
              ),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
          if (suggestUpgrade) ...[
            const SizedBox(height: 12),
            Text(
              KiamiStrings.quotaLimitUpgradeHint,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(KiamiStrings.closeButton),
        ),
        if (suggestUpgrade)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(KiamiRoutes.billing);
            },
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            label: const Text(KiamiStrings.quotaLimitUpgradeButton),
          ),
      ],
    ),
  );
}
