import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/kiami_file.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/format_bytes.dart';
import '../../utils/format_date.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/kiami_page_header.dart';
import '../files/providers/files_providers.dart';
import 'trash_providers.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashFilesProvider);
    final showBack = kiamiShowsShellBackButton(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KiamiPageHeader(
          title: KiamiStrings.trashTitle,
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        Expanded(
          child: trashAsync.when(
            data: (files) {
              if (files.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          KiamiStrings.trashEmpty,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          KiamiStrings.trashHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: kiamiScrollPadding(context, left: 24, right: 24),
                children: [
                  Text(
                    KiamiStrings.trashHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ...files.map(
                    (f) => _TrashTile(
                      file: f,
                      onRestore: () => _restore(context, ref, f),
                      onDeleteForever: () =>
                          _deleteForever(context, ref, f),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(kiamiApiErrorMessage(e)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    KiamiFile file,
  ) async {
    try {
      await ref.read(kiamiApiClientProvider).restoreFile(file.id);
      ref.invalidate(trashFilesProvider);
      ref.invalidate(kiamiFilesProvider);
      ref.invalidate(kiamiProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.fileRestored)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kiamiApiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _deleteForever(
    BuildContext context,
    WidgetRef ref,
    KiamiFile file,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(KiamiStrings.trashDeleteForever),
        content: const Text(KiamiStrings.trashDeleteForeverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(KiamiStrings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(KiamiStrings.trashDeleteForever),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(kiamiApiClientProvider).permanentDeleteFile(file.id);
      ref.invalidate(trashFilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.filePermanentDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kiamiApiErrorMessage(e))),
        );
      }
    }
  }
}

class _TrashTile extends StatelessWidget {
  const _TrashTile({
    required this.file,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final KiamiFile file;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: KiamiCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatBytes(file.sizeBytes)} · ${formatFileDate(file.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestore,
              child: const Text(KiamiStrings.trashRestore),
            ),
            IconButton(
              tooltip: KiamiStrings.trashDeleteForever,
              icon: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: onDeleteForever,
            ),
          ],
        ),
      ),
    );
  }
}
