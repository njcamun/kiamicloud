import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../theme/kiami_decorations.dart';
import '../utils/file_icon.dart';
import '../utils/format_bytes.dart';
import '../utils/format_date.dart';
import 'kiami_card.dart';
import 'kiami_file_actions_button.dart';

/// Tile de ficheiro para vista em detalhes.
class KiamiFileDetailTile extends StatelessWidget {
  const KiamiFileDetailTile({
    super.key,
    required this.file,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
    required this.onShare,
  });

  final KiamiFile file;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final icon = fileIconForName(file.name);
    final iconColor = fileIconColorForName(file.name);
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return KiamiCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      onTap: onDownload,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.sd_storage_outlined,
                  label: formatBytes(file.sizeBytes),
                  color: secondary,
                ),
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: formatFileDate(file.createdAt),
                  color: secondary,
                ),
                if (file.mimeType != null && file.mimeType!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: Icons.insert_drive_file_outlined,
                    label: file.mimeType!,
                    color: secondary,
                  ),
                ],
              ],
            ),
          ),
          KiamiFileActionsButton(
            file: file,
            onDownload: onDownload,
            onRename: onRename,
            onDelete: onDelete,
            onShare: onShare,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ),
      ],
    );
  }
}
