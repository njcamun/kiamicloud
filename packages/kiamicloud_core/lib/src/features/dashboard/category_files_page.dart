import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/kiami_file.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/file_category.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/file_list_toolbar.dart';
import '../../widgets/kiami_category_banner.dart';
import '../../widgets/kiami_empty_state.dart';
import '../../widgets/kiami_file_detail_tile.dart';
import '../../widgets/kiami_file_grid_tile.dart';
import '../../widgets/kiami_file_row.dart';
import '../../widgets/kiami_loading_skeleton.dart';
import '../../widgets/kiami_page_header.dart';
import '../../widgets/kiami_search_bar.dart';
import '../files/presentation/file_list_actions.dart';
import '../files/presentation/file_list_sort.dart';
import '../files/providers/files_providers.dart';
import '../../data/file_list_preferences.dart';

import '../../theme/kiami_spacing.dart';

enum _AudioQuickFilter { all, music, recordings }

bool _matchesAudioFilter(KiamiFile file, _AudioQuickFilter filter) {
  if (filter == _AudioQuickFilter.all) return true;
  final dot = file.name.lastIndexOf('.');
  if (dot < 0) return filter == _AudioQuickFilter.all;
  final ext = file.name.substring(dot + 1).toLowerCase();
  const music = {'mp3', 'm4a', 'flac', 'ogg', 'aac', 'wma', 'opus'};
  const recordings = {'wav', 'amr', 'caf', 'aiff', '3gp'};
  return switch (filter) {
    _AudioQuickFilter.music => music.contains(ext),
    _AudioQuickFilter.recordings => recordings.contains(ext),
    _AudioQuickFilter.all => true,
  };
}

/// Lista de ficheiros de uma categoria (ecrã dedicado).
class CategoryFilesPage extends ConsumerStatefulWidget {
  const CategoryFilesPage({super.key, required this.category});

  final KiamiFileCategory category;

  @override
  ConsumerState<CategoryFilesPage> createState() => _CategoryFilesPageState();
}

class _CategoryFilesPageState extends ConsumerState<CategoryFilesPage>
    with KiamiFileListActions {
  String _searchQuery = '';
  _AudioQuickFilter _audioFilter = _AudioQuickFilter.all;
  FileListViewMode _viewMode = FileListViewMode.list;
  FileListSortOption _sortOption = FileListSortOption.nameAsc;
  final _searchController = TextEditingController();
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await FileListPreferences.load();
    if (!mounted) return;
    setState(() {
      _viewMode = prefs.getViewMode(widget.category.routeId);
      _sortOption = prefs.getSortOption(widget.category.routeId);
    });
  }

  Future<void> _saveViewMode(FileListViewMode mode) async {
    final prefs = await FileListPreferences.load();
    await prefs.setViewMode(widget.category.routeId, mode);
  }

  Future<void> _saveSort(FileListSortOption sort) async {
    final prefs = await FileListPreferences.load();
    await prefs.setSortOption(widget.category.routeId, sort);
  }

  void _toggleSelection(String fileId) {
    setState(() {
      if (_selectedIds.contains(fileId)) {
        _selectedIds.remove(fileId);
      } else {
        _selectedIds.add(fileId);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _deleteSelected(List<KiamiFile> visible) async {
    final selected =
        visible.where((f) => _selectedIds.contains(f.id)).toList();
    if (selected.isEmpty) return;
    await deleteKiamiFiles(selected);
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KiamiFile> _prepareFiles(List<KiamiFile> all) {
    var files = all
        .where((f) => fileCategoryForName(f.name) == widget.category)
        .toList();

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      files = files.where((f) => f.name.toLowerCase().contains(q)).toList();
    }

    if (widget.category == KiamiFileCategory.audio) {
      files = files
          .where((f) => _matchesAudioFilter(f, _audioFilter))
          .toList();
    }

    return sortKiamiFiles(files, _sortOption);
  }

  ({
    VoidCallback onDownload,
    VoidCallback onRename,
    VoidCallback onDelete,
    VoidCallback onShare,
  }) _fileActions(KiamiFile file) => (
        onDownload: () => downloadKiamiFile(file),
        onRename: () => renameKiamiFile(file),
        onDelete: () => deleteKiamiFile(file),
        onShare: () => shareKiamiFile(file),
      );

  int _gridCrossAxisCount(double width) => kiamiFileGridCrossAxisCount(width);

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(kiamiFilesProvider);
    final hPad = kiamiContentHorizontalPadding(context);
    final showBack = kiamiShowsShellBackButton(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KiamiPageHeader(
          title: widget.category.label,
          leading: showBack
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
          actions: [
            if (_selectionMode) ...[
              IconButton(
                tooltip: KiamiStrings.selectionDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  final files = _prepareFiles(
                    ref.read(kiamiFilesProvider).valueOrNull ?? [],
                  );
                  _deleteSelected(files);
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                }),
              ),
            ] else ...[
              IconButton(
                tooltip: KiamiStrings.selectionMode,
                icon: const Icon(Icons.checklist_rounded),
                onPressed: () => setState(() => _selectionMode = true),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: refreshKiamiFiles,
              ),
            ],
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  kiamiContentWidth(context, constraints);

              return RefreshIndicator(
            onRefresh: refreshKiamiFiles,
            child: filesAsync.when(
              data: (allFiles) {
                final files = _prepareFiles(allFiles);

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KiamiCategoryBanner(
                              category: widget.category,
                              fileCount: files.length,
                            ),
                            const SizedBox(height: KiamiSpacing.md),
                            KiamiSearchBar(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                            if (widget.category == KiamiFileCategory.audio) ...[
                              const SizedBox(height: KiamiSpacing.sm),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChip(
                                      label: Text(KiamiStrings.categoryFilterAll),
                                      selected: _audioFilter ==
                                          _AudioQuickFilter.all,
                                      onSelected: (_) => setState(
                                        () => _audioFilter =
                                            _AudioQuickFilter.all,
                                      ),
                                    ),
                                    const SizedBox(width: KiamiSpacing.sm),
                                    FilterChip(
                                      label: Text(KiamiStrings.audioFilterMusic),
                                      selected: _audioFilter ==
                                          _AudioQuickFilter.music,
                                      onSelected: (_) => setState(
                                        () => _audioFilter =
                                            _AudioQuickFilter.music,
                                      ),
                                    ),
                                    const SizedBox(width: KiamiSpacing.sm),
                                    FilterChip(
                                      label: Text(
                                        KiamiStrings.audioFilterRecordings,
                                      ),
                                      selected: _audioFilter ==
                                          _AudioQuickFilter.recordings,
                                      onSelected: (_) => setState(
                                        () => _audioFilter =
                                            _AudioQuickFilter.recordings,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: KiamiSpacing.md),
                            FileListToolbar(
                              viewMode: _viewMode,
                              sortOption: _sortOption,
                              fileCount: files.length,
                              onViewModeChanged: (mode) {
                                setState(() => _viewMode = mode);
                                _saveViewMode(mode);
                              },
                              onSortChanged: (sort) {
                                setState(() => _sortOption = sort);
                                _saveSort(sort);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (files.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: KiamiEmptyState(
                          icon: widget.category.icon,
                          title: _searchQuery.isNotEmpty ||
                                  _audioFilter != _AudioQuickFilter.all
                              ? KiamiStrings.categorySearchEmpty
                              : KiamiStrings.categoryFilesEmpty,
                          iconColor: widget.category.accentColor,
                          compact: true,
                        ),
                      )
                    else
                      _buildFilesSliver(files, contentWidth, hPad),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: kiamiBottomInset(context, 8),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, KiamiSpacing.xl, hPad, 0),
                  child: KiamiFileGridSkeleton(
                    crossAxisCount: _gridCrossAxisCount(contentWidth),
                  ),
                ),
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: kiamiScrollPadding(context, left: hPad, right: hPad),
                children: [
                  const SizedBox(height: 48),
                  Text(
                    kiamiApiErrorMessage(e),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton.icon(
                      onPressed: refreshKiamiFiles,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              ),
            ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilesSliver(
    List<KiamiFile> files,
    double width,
    double hPad,
  ) {
    final hPadding = EdgeInsets.symmetric(horizontal: hPad);
    switch (_viewMode) {
      case FileListViewMode.list:
        return SliverPadding(
          padding: hPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = files[index];
                final actions = _fileActions(file);
                return KiamiFileRow(
                  file: file,
                  selected: _selectedIds.contains(file.id),
                  onSelectToggle: _selectionMode
                      ? () => _toggleSelection(file.id)
                      : null,
                  onOpen: () => previewKiamiFile(
                    file,
                    filesInContext: files,
                  ),
                  onDownload: actions.onDownload,
                  onRename: actions.onRename,
                  onDelete: actions.onDelete,
                  onShare: actions.onShare,
                );
              },
              childCount: files.length,
            ),
          ),
        );
      case FileListViewMode.grid:
        return SliverPadding(
          padding: hPadding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCrossAxisCount(width),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = files[index];
                final actions = _fileActions(file);
                return KiamiFileGridTile(
                  file: file,
                  onOpen: () => previewKiamiFile(
                    file,
                    filesInContext: files,
                  ),
                  onDownload: actions.onDownload,
                  onRename: actions.onRename,
                  onDelete: actions.onDelete,
                  onShare: actions.onShare,
                );
              },
              childCount: files.length,
            ),
          ),
        );
      case FileListViewMode.details:
        return SliverPadding(
          padding: hPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = files[index];
                final actions = _fileActions(file);
                return KiamiFileDetailTile(
                  file: file,
                  onOpen: () => previewKiamiFile(
                    file,
                    filesInContext: files,
                  ),
                  onDownload: actions.onDownload,
                  onRename: actions.onRename,
                  onDelete: actions.onDelete,
                  onShare: actions.onShare,
                );
              },
              childCount: files.length,
            ),
          ),
        );
    }
  }
}
