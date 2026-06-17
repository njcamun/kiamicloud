import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/kiami_api_exception.dart';
import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../../../data/offline_cache.dart';
import '../../../data/offline_mutation_queue.dart';
import '../../../utils/docx_preview.dart';
import '../../../utils/pdf_preview.dart';
import '../../../utils/text_preview.dart';
import '../../connectivity/connectivity_provider.dart';
import '../providers/files_providers.dart';
import '../../../utils/kiami_error_presenter.dart';
import 'file_actions_dialogs.dart';
import 'file_gallery_page.dart';
import 'file_preview_page.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> downloadKiamiFile(KiamiFile file) async {
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
      loadBytes: (KiamiFile f) async => Uint8List.fromList(
        await ref.read(kiamiApiClientProvider).downloadFileBytes(f.id),
      ),
      loadMediaSource: (KiamiFile f) =>
          ref.read(kiamiApiClientProvider).getFileDownloadInfo(f.id),
      onDownload: downloadKiamiFile,
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

  Future<void> shareKiamiFile(KiamiFile file) async {
    try {
      final result = await ref
          .read(kiamiApiClientProvider)
          .createFileShare(file.id);
      await Clipboard.setData(ClipboardData(text: result.shareUrl));
      if (!mounted) return;
      showKiamiMessage(KiamiStrings.fileShareCreated);
    } catch (e) {
      if (!mounted) return;
      KiamiErrorPresenter.showSnackBar(context, e);
    }
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
