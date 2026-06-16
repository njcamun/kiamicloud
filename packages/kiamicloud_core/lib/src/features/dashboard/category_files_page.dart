import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/kiami_file.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/file_category.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/category_illustration.dart';
import '../../widgets/file_list_toolbar.dart';
import '../../widgets/kiami_file_detail_tile.dart';
import '../../widgets/kiami_file_grid_tile.dart';
import '../../widgets/kiami_file_row.dart';
import '../../widgets/kiami_page_header.dart';
import '../files/presentation/file_list_actions.dart';
import '../files/presentation/file_list_sort.dart';
import '../files/presentation/file_preview_page.dart';
import '../files/providers/files_providers.dart';
import '../../data/file_list_preferences.dart';

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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: CategoryIllustration(
                                  category: widget.category,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: KiamiStrings.dashboardSearchHint,
                                prefixIcon:
                                    const Icon(Icons.search_rounded),
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        icon:
                                            const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                              ),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                            const SizedBox(height: 12),
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
                        child: _CategoryEmptyState(
                          hasSearch: _searchQuery.isNotEmpty,
                          category: widget.category,
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
              loading: () => const Center(child: CircularProgressIndicator()),
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
                  onOpen: FilePreviewPage.canPreview(file)
                      ? () => previewKiamiFile(file)
                      : actions.onDownload,
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
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = files[index];
                final actions = _fileActions(file);
                return KiamiFileGridTile(
                  file: file,
                  onDownload: FilePreviewPage.canPreview(file)
                      ? () => previewKiamiFile(file)
                      : actions.onDownload,
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

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState({
    required this.hasSearch,
    required this.category,
  });

  final bool hasSearch;
  final KiamiFileCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category.icon,
            size: 48,
            color: category.accentColor.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? KiamiStrings.categorySearchEmpty
                : KiamiStrings.categoryFilesEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
