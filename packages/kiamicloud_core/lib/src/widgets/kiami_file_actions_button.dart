import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';

/// Menu de acções (download, renomear, apagar) para um ficheiro.
class KiamiFileActionsButton extends StatelessWidget {
  const KiamiFileActionsButton({
    super.key,
    required this.file,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
    this.iconSize = 22,
  });

  final KiamiFile file;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: KiamiStrings.fileMoreActions,
      icon: Icon(Icons.more_vert_rounded, size: iconSize),
      onSelected: (value) {
        switch (value) {
          case 'download':
            onDownload();
          case 'rename':
            onRename();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'download',
          child: ListTile(
            leading: Icon(Icons.download_outlined),
            title: Text(KiamiStrings.downloadButton),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.drive_file_rename_outline),
            title: Text(KiamiStrings.fileRename),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: KiamiColors.error),
            title: Text(
              KiamiStrings.fileDelete,
              style: TextStyle(color: KiamiColors.error),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}
