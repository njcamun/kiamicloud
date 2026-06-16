import 'package:flutter/material.dart';

import '../constants/kiami_strings.dart';
import '../features/files/presentation/file_list_sort.dart';

/// Barra de ordenação e modo de visualização.
class FileListToolbar extends StatelessWidget {
  const FileListToolbar({
    super.key,
    required this.viewMode,
    required this.sortOption,
    required this.onViewModeChanged,
    required this.onSortChanged,
    this.fileCount,
  });

  final FileListViewMode viewMode;
  final FileListSortOption sortOption;
  final ValueChanged<FileListViewMode> onViewModeChanged;
  final ValueChanged<FileListSortOption> onSortChanged;
  final int? fileCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (fileCount != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              KiamiStrings.fileListCount(fileCount!),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        const Spacer(),
        PopupMenuButton<FileListSortOption>(
          tooltip: KiamiStrings.fileListSort,
          initialValue: sortOption,
          onSelected: onSortChanged,
          icon: const Icon(Icons.sort_rounded, size: 22),
          itemBuilder: (context) => [
            _sortItem(
              context,
              FileListSortOption.nameAsc,
              KiamiStrings.fileListSortNameAsc,
            ),
            _sortItem(
              context,
              FileListSortOption.nameDesc,
              KiamiStrings.fileListSortNameDesc,
            ),
            const PopupMenuDivider(),
            _sortItem(
              context,
              FileListSortOption.sizeAsc,
              KiamiStrings.fileListSortSizeAsc,
            ),
            _sortItem(
              context,
              FileListSortOption.sizeDesc,
              KiamiStrings.fileListSortSizeDesc,
            ),
            const PopupMenuDivider(),
            _sortItem(
              context,
              FileListSortOption.dateAsc,
              KiamiStrings.fileListSortDateAsc,
            ),
            _sortItem(
              context,
              FileListSortOption.dateDesc,
              KiamiStrings.fileListSortDateDesc,
            ),
          ],
        ),
        const SizedBox(width: 4),
        SegmentedButton<FileListViewMode>(
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          segments: const [
            ButtonSegment(
              value: FileListViewMode.list,
              icon: Icon(Icons.view_list_rounded, size: 20),
              tooltip: KiamiStrings.fileListViewList,
            ),
            ButtonSegment(
              value: FileListViewMode.grid,
              icon: Icon(Icons.grid_view_rounded, size: 20),
              tooltip: KiamiStrings.fileListViewGrid,
            ),
            ButtonSegment(
              value: FileListViewMode.details,
              icon: Icon(Icons.view_agenda_rounded, size: 20),
              tooltip: KiamiStrings.fileListViewDetails,
            ),
          ],
          selected: {viewMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) onViewModeChanged(selection.first);
          },
        ),
      ],
    );
  }

  PopupMenuItem<FileListSortOption> _sortItem(
    BuildContext context,
    FileListSortOption value,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (sortOption == value)
            Icon(Icons.check_rounded, size: 18, color: Theme.of(context).colorScheme.primary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
