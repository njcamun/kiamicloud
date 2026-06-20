import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/kiami_api_client.dart';
import '../../../api/kiami_api_exception.dart';
import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../../../data/offline_cache.dart';
import '../../../data/offline_mutation_queue.dart';
import '../../../utils/docx_preview.dart';
import '../../../utils/file_category.dart';
import '../../photos/presentation/photo_album_dialogs.dart';
import '../../photos/presentation/photo_gallery_actions.dart';
import '../../photos/providers/photo_library_providers.dart';
import '../../../utils/pdf_preview.dart';
import '../../../utils/text_preview.dart';
import '../../connectivity/connectivity_provider.dart';
import '../providers/files_providers.dart';
import '../../../utils/kiami_error_presenter.dart';
import 'audio_gallery_actions.dart';
import 'file_actions_dialogs.dart';
import 'file_gallery_page.dart';
import 'file_preview_page.dart';
import 'video_gallery_actions.dart';
import '../../../widgets/kiami_unavailable.dart';

/// Acções partilhadas (download, renomear, apagar) em listas de ficheiros.
mixin KiamiFileListActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Future<void> refreshKiamiFiles() async {
    refreshKiamiProfile(ref);
    ref.invalidate(kiamiFilesProvider);
    await Future.wait([
      ref.read(kiamiProfileProvider.future),
      ref.read(kiamiFilesProvider.future),
    ]);
  }

  void showKiamiMessage(String text) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> downloadKiamiFile(KiamiFile file) async {
    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) return;

    try {
      final bytes =
          await ref.read(kiamiApiClientProvider).downloadFileBytes(file.id);
      if (!mounted) return;

      final saved = await FilePicker.platform.saveFile(
        fileName: file.name,
        bytes: Uint8List.fromList(bytes),
      );

      if (!mounted) return;
      if (saved != null) showKiamiMessage(KiamiStrings.downloadSaved);
    } catch (e) {
      if (!mounted) return;
      if (kiamiApiErrorIsConnection(e) || _isConnectionError(e)) return;
      KiamiErrorPresenter.showSnackBar(context, e);
    }
  }

  Future<void> previewKiamiFile(
    KiamiFile file, {
    List<KiamiFile>? filesInContext,
  }) async {
    final contextFiles = filesInContext ?? [file];
    final index = contextFiles.indexWhere((f) => f.id == file.id);
    if (index < 0) return;

    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online && !FilePreviewPage.canPreview(file)) {
      if (!mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        pageBuilder: (_, __, ___) => const Material(
          type: MaterialType.transparency,
          child: KiamiPreviewIssueOverlay(connectionError: true),
        ),
      );
      return;
    }

    if (FilePreviewPage.canPreview(file)) {
      if (canPreviewTextFileName(file.name) &&
          file.sizeBytes > kTextPreviewMaxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.previewTextTooLarge)),
        );
        return;
      }
      if (canPreviewPdfFileName(file.name) &&
          file.sizeBytes > kPdfPreviewMaxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.previewPdfTooLarge)),
        );
        return;
      }
      if (canPreviewDocxFileName(file.name) &&
          file.sizeBytes > kDocxPreviewMaxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.previewDocxTooLarge)),
        );
        return;
      }
    }

    await FileGalleryPage.open(
      context,
      files: contextFiles,
      initialIndex: index,
      loadBytes: _previewLoadBytes,
      loadMediaSource: _previewLoadMediaSource,
      onDownload: downloadKiamiFile,
      downloadEnabled: ref.read(isOnlineProvider).valueOrNull ?? true,
      photoActions: _photoGalleryActions(contextFiles),
      videoActions: _videoGalleryActions(contextFiles),
      audioActions: _audioGalleryActions(contextFiles),
    );
  }

  Future<Uint8List> _previewLoadBytes(KiamiFile file) async {
    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) throw KiamiApiClient.connectionError();
    return Uint8List.fromList(
      await ref.read(kiamiApiClientProvider).downloadFileBytes(file.id),
    );
  }

  Future<MediaSource> _previewLoadMediaSource(KiamiFile file) async {
    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) throw KiamiApiClient.connectionError();
    return ref.read(kiamiApiClientProvider).getFileDownloadInfo(file.id);
  }

  AudioGalleryActions? _audioGalleryActions(List<KiamiFile> files) {
    if (files.isEmpty) return null;
    final allAudio = files.every(
      (f) => fileCategoryForName(f.name) == KiamiFileCategory.audio,
    );
    if (!allAudio) return null;

    return AudioGalleryActions(
      onDelete: deleteKiamiFile,
      onDownload: downloadKiamiFile,
    );
  }

  VideoGalleryActions? _videoGalleryActions(List<KiamiFile> files) {
    if (files.isEmpty) return null;
    final allVideos = files.every(
      (f) => fileCategoryForName(f.name) == KiamiFileCategory.video,
    );
    if (!allVideos) return null;

    return VideoGalleryActions(
      onDelete: deleteKiamiFile,
      onDownload: downloadKiamiFile,
    );
  }

  PhotoGalleryActions? _photoGalleryActions(List<KiamiFile> files) {
    if (files.isEmpty) return null;
    final allPhotos = files.every(
      (f) => fileCategoryForName(f.name) == KiamiFileCategory.images,
    );
    if (!allPhotos) return null;

    return PhotoGalleryActions(
      isFavorite: (id) =>
          ref.read(photoLibraryProvider).valueOrNull?.isFavorite(id) ?? false,
      onToggleFavorite: (file) =>
          ref.read(photoLibraryProvider.notifier).toggleFavorite(file.id),
      onDelete: (file) async {
        await deleteKiamiFile(file);
        await ref
            .read(photoLibraryProvider.notifier)
            .removeFileReferences(file.id);
      },
      onAddToAlbum: (file) =>
          showAddToPhotoAlbumSheet(context, ref, file: file),
    );
  }

  Future<void> _removeFileFromLocalCache(String fileId) async {
    final cache = await ref.read(offlineCacheProvider.future);
    final files = cache.readFiles();
    if (files == null) return;
    await cache.saveFiles(files.where((f) => f.id != fileId).toList());
    ref.invalidate(kiamiFilesProvider);
  }

  Future<void> _renameFileInLocalCache(String fileId, String newName) async {
    final cache = await ref.read(offlineCacheProvider.future);
    final files = cache.readFiles();
    if (files == null) return;
    await cache.saveFiles(
      files.map((f) {
        if (f.id != fileId) return f;
        return KiamiFile(
          id: f.id,
          name: newName,
          mimeType: f.mimeType,
          sizeBytes: f.sizeBytes,
          status: f.status,
          folderId: f.folderId,
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
          hasThumbnail: f.hasThumbnail,
        );
      }).toList(),
    );
    ref.invalidate(kiamiFilesProvider);
  }

  bool _isConnectionError(Object e) {
    return e is KiamiApiException && e.statusCode == null;
  }

  Future<void> renameKiamiFile(KiamiFile file) async {
    final newName = await showRenameFileDialog(
      context,
      currentName: file.name,
    );
    if (newName == null || newName.isEmpty || newName == file.name) return;

    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) {
      final queue = await ref.read(offlineMutationQueueProvider.future);
      await queue.enqueueRename(file.id, newName);
      await _renameFileInLocalCache(file.id, newName);
      if (!mounted) return;
      showKiamiMessage(KiamiStrings.offlineRenameQueued);
      return;
    }

    try {
      await ref.read(kiamiApiClientProvider).renameFile(
            fileId: file.id,
            newName: newName,
          );
      if (!mounted) return;
      showKiamiMessage(KiamiStrings.fileRenamed);
      await refreshKiamiFiles();
    } catch (e) {
      if (_isConnectionError(e)) {
        final queue = await ref.read(offlineMutationQueueProvider.future);
        await queue.enqueueRename(file.id, newName);
        await _renameFileInLocalCache(file.id, newName);
        if (!mounted) return;
        showKiamiMessage(KiamiStrings.offlineRenameQueued);
        return;
      }
      if (!mounted) return;
      KiamiErrorPresenter.showSnackBar(context, e);
    }
  }

  Future<void> deleteKiamiFile(KiamiFile file) async {
    final confirm = await showDeleteFileDialog(context);
    if (!confirm || !mounted) return;

    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) {
      final queue = await ref.read(offlineMutationQueueProvider.future);
      await queue.enqueueDelete(file.id);
      await _removeFileFromLocalCache(file.id);
      if (!mounted) return;
      showKiamiMessage(KiamiStrings.offlineDeleteQueued);
      return;
    }

    try {
      await ref.read(kiamiApiClientProvider).deleteFile(file.id);
      if (!mounted) return;
      showKiamiMessage(KiamiStrings.fileDeleted);
      await refreshKiamiFiles();
    } catch (e) {
      if (_isConnectionError(e)) {
        final queue = await ref.read(offlineMutationQueueProvider.future);
        await queue.enqueueDelete(file.id);
        await _removeFileFromLocalCache(file.id);
        if (!mounted) return;
        showKiamiMessage(KiamiStrings.offlineDeleteQueued);
        return;
      }
      if (!mounted) return;
      KiamiErrorPresenter.showSnackBar(context, e);
    }
  }

  Future<void> deleteKiamiFiles(Iterable<KiamiFile> files) async {
    final confirm = await showDeleteFileDialog(context);
    if (!confirm || !mounted) return;

    var ok = 0;
    for (final file in files) {
      try {
        await ref.read(kiamiApiClientProvider).deleteFile(file.id);
        ok++;
      } catch (e) {
        if (!mounted) return;
        KiamiErrorPresenter.showSnackBar(context, e);
      }
    }
    if (!mounted) return;
    if (ok > 0) {
      showKiamiMessage(
        ok == 1 ? KiamiStrings.fileDeleted : '$ok ficheiros na lixeira.',
      );
      await refreshKiamiFiles();
    }
  }
}
