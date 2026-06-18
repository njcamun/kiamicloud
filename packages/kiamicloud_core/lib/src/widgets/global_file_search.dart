import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../api/models/kiami_file.dart';
import '../constants/kiami_strings.dart';
import '../routing/kiami_routes.dart';
import '../utils/file_category.dart';
import '../utils/format_bytes.dart';
import 'kiami_empty_state.dart';
import 'kiami_file_thumbnail.dart';

/// Pesquisa global de ficheiros (atalho Ctrl+K / Cmd+K).
class GlobalFileSearchDelegate extends SearchDelegate<KiamiFile?> {
  GlobalFileSearchDelegate({required this.files});

  final List<KiamiFile> files;

  @override
  String get searchFieldLabel => KiamiStrings.dashboardSearchHint;

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return const BackButton();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = q.isEmpty
        ? files.take(20).toList()
        : files.where((f) => f.name.toLowerCase().contains(q)).toList();

    if (results.isEmpty) {
      return KiamiEmptyState(
        icon: Icons.search_off_rounded,
        title: KiamiStrings.categorySearchEmpty,
        compact: true,
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = results[index];
        final category = fileCategoryForName(file.name);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: SizedBox(
            width: 44,
            height: 44,
            child: KiamiFileThumbnail(file: file, height: 44),
          ),
          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${category.label} · ${formatBytes(file.sizeBytes)}',
          ),
          trailing: Icon(
            category.icon,
            color: category.accentColor,
            size: 20,
          ),
          onTap: () {
            close(context, file);
            context.push(KiamiRoutes.categoryFilesFor(category));
          },
        );
      },
    );
  }
}

/// Abre pesquisa global; regista atalho de teclado no [child].
class GlobalFileSearchLauncher extends StatelessWidget {
  const GlobalFileSearchLauncher({
    super.key,
    required this.files,
    required this.child,
  });

  final List<KiamiFile> files;
  final Widget child;

  Future<void> _open(BuildContext context) async {
    await showSearch<KiamiFile?>(
      context: context,
      delegate: GlobalFileSearchDelegate(files: files),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyK,
        ): const _OpenSearchIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.keyK,
        ): const _OpenSearchIntent(),
      },
      child: Actions(
        actions: {
          _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
            onInvoke: (_) {
              _open(context);
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }

  static IconButton toolbarButton({
    required BuildContext context,
    required List<KiamiFile> files,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: '${KiamiStrings.dashboardSearchHint} (Ctrl+K)',
      icon: const Icon(Icons.search_rounded),
      onPressed: () => showSearch<KiamiFile?>(
        context: context,
        delegate: GlobalFileSearchDelegate(files: files),
      ),
    );
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}
