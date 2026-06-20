import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../utils/format_bytes.dart';
import 'kiami_card.dart';
import 'kiami_file_actions_button.dart';
import 'kiami_file_thumbnail.dart';

/// Tile de ficheiro para vista em mosaico/grelha.
class KiamiFileGridTile extends StatelessWidget {
  const KiamiFileGridTile({
    super.key,
    required this.file,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
    this.onOpen,
  });

  final KiamiFile file;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return KiamiCard(
      padding: const EdgeInsets.all(10),
      onTap: onOpen ?? onDownload,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: KiamiFileThumbnail(
                    file: file,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: KiamiFileActionsButton(
                    file: file,
                    onDownload: onDownload,
                    onRename: onRename,
                    onDelete: onDelete,
                    iconSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatBytes(file.sizeBytes),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
