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
    required this.onShare,
  });

  final KiamiFile file;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return KiamiCard(
      padding: const EdgeInsets.all(12),
      onTap: onDownload,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KiamiFileThumbnail(file: file),
              ),
              KiamiFileActionsButton(
                file: file,
                onDownload: onDownload,
                onRename: onRename,
                onDelete: onDelete,
                onShare: onShare,
                iconSize: 20,
              ),
            ],
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
          const Spacer(),
          Text(
            formatBytes(file.sizeBytes),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
