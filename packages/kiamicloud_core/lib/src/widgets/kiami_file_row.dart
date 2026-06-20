import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../utils/format_bytes.dart';
import '../utils/format_date.dart';
import 'kiami_card.dart';
import 'kiami_file_actions_button.dart';
import 'kiami_file_thumbnail.dart';

/// Linha de ficheiro com accoes (download, renomear, apagar).
class KiamiFileRow extends StatelessWidget {
  const KiamiFileRow({
    super.key,
    required this.file,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
    this.onOpen,
    this.selected = false,
    this.onSelectToggle,
    this.canDownload = true,
  });

  final KiamiFile file;
  final VoidCallback? onOpen;
  final bool selected;
  final VoidCallback? onSelectToggle;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final bool canDownload;

  @override
  Widget build(BuildContext context) {
    return KiamiCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onTap: onSelectToggle ?? onOpen ?? onDownload,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: onSelectToggle != null
            ? Checkbox(
                value: selected,
                onChanged: (_) => onSelectToggle?.call(),
              )
            : SizedBox(
                width: 44,
                height: 44,
                child: KiamiFileThumbnail(
                  file: file,
                  height: 44,
                ),
              ),
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${formatBytes(file.sizeBytes)} · ${formatFileDate(file.createdAt)}',
        ),
        trailing: KiamiFileActionsButton(
          file: file,
          onDownload: onDownload,
          onRename: onRename,
          onDelete: onDelete,
          canDownload: canDownload,
        ),
      ),
    );
  }
}
