import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../models/photo_album.dart';
import '../providers/photo_library_providers.dart';

Future<String?> showCreatePhotoAlbumDialog(
  BuildContext context, {
  int photoCount = 1,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(KiamiStrings.photoAlbumCreateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            KiamiStrings.photoAlbumCreateHint(photoCount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: KiamiStrings.photoAlbumNameLabel,
            ),
            onSubmitted: (v) {
              final name = v.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, name);
          },
          child: const Text(KiamiStrings.photoAlbumCreateAction),
        ),
      ],
    ),
  );
}

Future<void> showAddToPhotoAlbumSheet(
  BuildContext context,
  WidgetRef ref, {
  required KiamiFile file,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final library = ref.watch(photoLibraryProvider);
          return library.when(
            data: (state) => _AddToAlbumBody(
              albums: state.albums,
              onCreate: () async {
                Navigator.pop(context);
                final name = await showCreatePhotoAlbumDialog(context);
                if (name == null || name.isEmpty) return;
                await ref
                    .read(photoLibraryProvider.notifier)
                    .createAlbum(name, [file.id]);
              },
              onPick: (album) async {
                await ref
                    .read(photoLibraryProvider.notifier)
                    .addFilesToAlbum(album.id, [file.id]);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        KiamiStrings.photoAddedToAlbum(album.name),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(KiamiStrings.photoLibraryLoadError),
            ),
          );
        },
      );
    },
  );
}

class _AddToAlbumBody extends StatelessWidget {
  const _AddToAlbumBody({
    required this.albums,
    required this.onCreate,
    required this.onPick,
  });

  final List<PhotoAlbum> albums;
  final VoidCallback onCreate;
  final ValueChanged<PhotoAlbum> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              KiamiStrings.photoAddToAlbumTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text(KiamiStrings.photoAlbumCreateAction),
            onTap: onCreate,
          ),
          if (albums.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                KiamiStrings.photoAlbumEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return ListTile(
                    leading: const Icon(Icons.photo_album_outlined),
                    title: Text(album.name),
                    subtitle: Text(
                      KiamiStrings.photoAlbumPhotoCount(album.fileIds.length),
                    ),
                    onTap: () => onPick(album),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Future<double?> showPhotoAdjustSheet(
  BuildContext context, {
  required double initialBrightness,
}) {
  return showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      var brightness = initialBrightness;
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    KiamiStrings.photoAdjustTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    KiamiStrings.photoAdjustHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: brightness,
                    min: 0.4,
                    max: 1.6,
                    divisions: 24,
                    label: brightness.toStringAsFixed(2),
                    onChanged: (v) => setLocalState(() => brightness = v),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, brightness),
                    child: const Text(KiamiStrings.photoAdjustApply),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
