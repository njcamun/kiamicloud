import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../constants/kiami_strings.dart';
import 'category_illustration.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../utils/file_category.dart';
import '../utils/file_icon.dart';
import '../utils/format_bytes.dart';
import '../utils/format_date.dart';
import 'kiami_card.dart';

/// Secção expansivel — pasta virtual por tipo de ficheiro.
class FileCategoryFolder extends StatelessWidget {
  const FileCategoryFolder({
    super.key,
    required this.category,
    required this.files,
    required this.expanded,
    required this.onToggle,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  final KiamiFileCategory category;
  final List<KiamiFile> files;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(KiamiFile file) onDownload;
  final void Function(KiamiFile file) onRename;
  final void Function(KiamiFile file) onDelete;

  @override
  Widget build(BuildContext context) {
    return KiamiCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _CategoryThumb(category: category, count: files.length),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        category.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: KiamiColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: KiamiColors.deepBlue.withValues(alpha: 0.06),
            ),
            ...List.generate(files.length, (index) {
              final file = files[index];
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: KiamiColors.deepBlue.withValues(alpha: 0.06),
                    ),
                  _FolderFileRow(
                    file: file,
                    onDownload: () => onDownload(file),
                    onRename: () => onRename(file),
                    onDelete: () => onDelete(file),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CategoryThumb extends StatelessWidget {
  const _CategoryThumb({required this.category, required this.count});

  final KiamiFileCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
            child: SizedBox(
              width: 52,
              height: 52,
              child: CategoryIllustration(
                category: category,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                cacheWidth: 104,
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: KiamiColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderFileRow extends StatelessWidget {
  const _FolderFileRow({
    required this.file,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  final KiamiFile file;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final icon = fileIconForName(file.name);
    final iconColor = fileIconColorForName(file.name);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${formatBytes(file.sizeBytes)} · ${formatFileDate(file.createdAt)}',
      ),
      trailing: PopupMenuButton<String>(
        tooltip: KiamiStrings.fileMoreActions,
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
            ),
          ),
          const PopupMenuItem(
            value: 'rename',
            child: ListTile(
              leading: Icon(Icons.drive_file_rename_outline),
              title: Text(KiamiStrings.fileRename),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: KiamiColors.error),
              title: Text(
                KiamiStrings.fileDelete,
                style: TextStyle(color: KiamiColors.error),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: onDownload,
    );
  }
}
