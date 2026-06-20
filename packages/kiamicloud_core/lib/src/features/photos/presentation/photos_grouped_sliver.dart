import 'package:flutter/material.dart';

import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_spacing.dart';
import '../../../widgets/kiami_file_thumbnail.dart';
import '../utils/group_files_by_day.dart';
import 'photo_grid_tile.dart';

/// Slivers de fotos agrupadas por dia (grelha ou lista).
class PhotosGroupedSliver {
  PhotosGroupedSliver._();

  static Widget grid({
    required List<KiamiFile> files,
    required int crossAxisCount,
    required double horizontalPadding,
    required Set<String> favoriteIds,
    required bool selectionMode,
    required Set<String> selectedIds,
    required void Function(KiamiFile file) onOpen,
    required void Function(KiamiFile file) onToggleFavorite,
    required void Function(KiamiFile file) onLongPressSelect,
    required void Function(KiamiFile file) onSelectToggle,
  }) {
    final groups = groupFilesByDay(files);
    final children = <Widget>[];

    for (final group in groups) {
      children.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              group.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      );
      children.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = group.files[index];
                return PhotoGridTile(
                  file: file,
                  isFavorite: favoriteIds.contains(file.id),
                  selected: selectedIds.contains(file.id),
                  selectionMode: selectionMode,
                  onOpen: () => onOpen(file),
                  onToggleFavorite: () => onToggleFavorite(file),
                  onLongPress: () => onLongPressSelect(file),
                  onSelectToggle: () => onSelectToggle(file),
                );
              },
              childCount: group.files.length,
            ),
          ),
        ),
      );
    }

    return SliverMainAxisGroup(slivers: children);
  }

  static Widget list({
    required List<KiamiFile> files,
    required double horizontalPadding,
    required Set<String> favoriteIds,
    required bool selectionMode,
    required Set<String> selectedIds,
    required void Function(KiamiFile file) onOpen,
    required void Function(KiamiFile file) onToggleFavorite,
    required void Function(KiamiFile file) onLongPressSelect,
    required void Function(KiamiFile file) onSelectToggle,
  }) {
    final groups = groupFilesByDay(files);
    final children = <Widget>[];

    for (final group in groups) {
      children.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              group.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
      children.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = group.files[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PhotoListRow(
                    file: file,
                    isFavorite: favoriteIds.contains(file.id),
                    selected: selectedIds.contains(file.id),
                    selectionMode: selectionMode,
                    onOpen: () => onOpen(file),
                    onToggleFavorite: () => onToggleFavorite(file),
                    onLongPress: () => onLongPressSelect(file),
                    onSelectToggle: () => onSelectToggle(file),
                  ),
                );
              },
              childCount: group.files.length,
            ),
          ),
        ),
      );
    }

    return SliverMainAxisGroup(slivers: children);
  }
}

class _PhotoListRow extends StatelessWidget {
  const _PhotoListRow({
    required this.file,
    required this.isFavorite,
    required this.selected,
    required this.selectionMode,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onLongPress,
    required this.onSelectToggle,
  });

  final KiamiFile file;
  final bool isFavorite;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final VoidCallback onLongPress;
  final VoidCallback onSelectToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: selectionMode ? onSelectToggle : onOpen,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              if (selectionMode) ...[
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? KiamiColors.primaryBlue : null,
                ),
                const SizedBox(width: KiamiSpacing.sm),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: KiamiFileThumbnail(file: file, height: 56),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      formatPhotoDayLabel(fileLocalDate(file)),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: KiamiStrings.photoFavoriteToggle,
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? const Color(0xFFE53935) : null,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
