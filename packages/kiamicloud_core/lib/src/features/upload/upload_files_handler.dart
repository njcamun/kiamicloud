import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/kiami_profile.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/kiami_api_limits.dart';
import '../../utils/format_bytes.dart';
import '../../utils/upload_file_reader.dart';
import '../../widgets/kiami_unavailable.dart';
import '../files/providers/files_providers.dart';
import 'upload_queue.dart';

/// Processa ficheiros seleccionados/arrastados e envia para a fila.
Future<void> handleFilesForUpload({
  required BuildContext context,
  required WidgetRef ref,
  required List<PlatformFile> pickedFiles,
  required Future<void> Function(KiamiProfile profile) onQuotaBlocked,
  required Future<void> Function({
    required KiamiProfile profile,
    required String fileName,
    int? fileSizeBytes,
  }) onFileExceedsQuota,
  void Function(String message)? showMessage,
}) async {
  if (pickedFiles.isEmpty) return;

  _notify(showMessage, context, KiamiStrings.uploadPreparing);

  KiamiProfile? profile = ref.read(kiamiProfileProvider).valueOrNull;
  if (KiamiApiLimits.enforced && profile == null) {
    try {
      profile = await ref
          .read(kiamiProfileProvider.future)
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      if (!context.mounted) return;
      await showKiamiNoConnectDialog(context);
      return;
    } catch (e) {
      if (!context.mounted) return;
      await showKiamiNoConnectDialog(context);
      return;
    }
  }

  if (KiamiApiLimits.enforced && profile != null) {
    final access = profile.access;
    if (access != null && !access.canUpload) {
      _notify(
        showMessage,
        context,
        KiamiStrings.subscriptionMessageFor(
          effectiveStatus: access.effectiveStatus,
          blockReason: access.blockReason,
        ),
      );
      return;
    }
    if (!profile.quota.canUpload) {
      if (!context.mounted) return;
      await onQuotaBlocked(profile);
      return;
    }
  }

  final maxFileBytes = KiamiApiLimits.maxUploadFileBytes(
    profileMax: profile?.maxFileSizeBytes,
  );
  var availableBytes = KiamiApiLimits.availableStorageBytes(
    profileAvailable: profile?.storageAvailableBytes,
  );

  final skippedTooLarge = <String>[];
  final skippedQuota = <String>[];
  final skippedNoBytes = <String>[];
  final queue = <UploadQueueRequest>[];
  String? firstQuotaFileName;
  int? firstQuotaFileSize;

  final notifier = ref.read(uploadQueueProvider.notifier);
  var enqueued = 0;

  for (final file in pickedFiles) {
    if (kIsWeb) {
      final read = await readPlatformFileForUpload(
        file: file,
        maxFileBytes: maxFileBytes,
        storageAvailableBytes: availableBytes,
      );
      switch (read) {
        case UploadFileReady(:final name, :final bytes):
          queue.add((
            name: name,
            sizeBytes: bytes.length,
            path: null,
            bytes: Uint8List.fromList(bytes),
          ));
          availableBytes = (availableBytes - bytes.length).clamp(0, 1 << 62);
        case UploadFileRejected(:final name, :final reason, :final sizeBytes):
          switch (reason) {
            case UploadFileRejectReason.tooLargePerFile:
              skippedTooLarge.add(name);
            case UploadFileRejectReason.exceedsQuota:
              skippedQuota.add(name);
              firstQuotaFileName ??= name;
              firstQuotaFileSize ??= sizeBytes;
            case UploadFileRejectReason.unreadable:
              skippedNoBytes.add(name);
          }
      }
      continue;
    }

    var normalized = file;
    if (!platformFileHasSource(file) ||
        ((file.path == null || file.path!.isEmpty) &&
            (file.bytes == null || file.bytes!.isEmpty))) {
      final bytes = await readPlatformFileBytes(file, maxBytes: maxFileBytes);
      if (bytes != null && bytes.isNotEmpty) {
        normalized = PlatformFile(
          name: file.name,
          size: bytes.length,
          bytes: Uint8List.fromList(bytes),
        );
      }
    }

    final outcome = validatePlatformFileForUpload(
      file: normalized,
      maxFileBytes: maxFileBytes,
      storageAvailableBytes: availableBytes,
    );

    switch (outcome) {
      case UploadFileReady(:final name):
        final size = platformFileEffectiveSize(normalized);
        final path = normalized.path != null && normalized.path!.isNotEmpty
            ? normalized.path
            : null;
        final inMemory = normalized.bytes != null && normalized.bytes!.isNotEmpty
            ? List<int>.from(normalized.bytes!)
            : null;
        queue.add((
          name: name,
          sizeBytes: size > 0 ? size : normalized.size,
          path: path,
          bytes: inMemory,
        ));
        final reserved = size > 0 ? size : normalized.size;
        if (reserved > 0) {
          availableBytes = (availableBytes - reserved).clamp(0, 1 << 62);
        }
      case UploadFileRejected(:final name, :final reason, :final sizeBytes):
        switch (reason) {
          case UploadFileRejectReason.tooLargePerFile:
            skippedTooLarge.add(name);
          case UploadFileRejectReason.exceedsQuota:
            skippedQuota.add(name);
            firstQuotaFileName ??= name;
            firstQuotaFileSize ??= sizeBytes;
          case UploadFileRejectReason.unreadable:
            skippedNoBytes.add(name);
        }
    }
  }

  if (queue.isNotEmpty) {
    notifier.enqueueAll(queue);
    enqueued = queue.length;
  }

  if (!context.mounted) return;

  if (enqueued > 0) {
    _notify(showMessage, context, KiamiStrings.uploadBackgroundStarted(enqueued));
  }

  if (enqueued == 0) {
    if (skippedQuota.isNotEmpty && profile != null) {
      await onFileExceedsQuota(
        profile: profile,
        fileName: firstQuotaFileName ?? skippedQuota.first,
        fileSizeBytes: firstQuotaFileSize,
      );
      return;
    }
    if (skippedTooLarge.isNotEmpty) {
      _notify(
        showMessage,
        context,
        KiamiStrings.uploadSkippedTooLarge(
          skippedTooLarge.length,
          formatTransferLimit(profile?.maxFileSizeBytes ?? 0),
        ),
      );
      return;
    }
    if (skippedNoBytes.isNotEmpty) {
      _notify(
        showMessage,
        context,
        KiamiStrings.uploadNoBytesMultiple(skippedNoBytes.length),
      );
      return;
    }
    _notify(showMessage, context, KiamiStrings.uploadNothingEnqueued);
    return;
  }

  _showPartialResult(
    showMessage: showMessage,
    context: context,
    uploaded: enqueued,
    skippedTooLarge: skippedTooLarge,
    skippedNoBytes: skippedNoBytes,
    maxFileBytes: maxFileBytes,
  );
}

void _notify(
  void Function(String message)? showMessage,
  BuildContext context,
  String text,
) {
  if (!context.mounted) return;
  showMessage?.call(text);
}

void _showPartialResult({
  void Function(String message)? showMessage,
  required BuildContext context,
  required int uploaded,
  required List<String> skippedTooLarge,
  required List<String> skippedNoBytes,
  required int maxFileBytes,
}) {
  if (skippedTooLarge.isEmpty && skippedNoBytes.isEmpty) return;
  if (!context.mounted) return;
  final maxLabel =
      formatTransferLimit(maxFileBytes >= (1 << 62) ? 0 : maxFileBytes);
  final failed = skippedTooLarge.length + skippedNoBytes.length;
  if (skippedTooLarge.isNotEmpty && skippedNoBytes.isEmpty) {
    showMessage?.call(
      KiamiStrings.uploadPartialSuccessWithLimit(uploaded, failed, maxLabel),
    );
  } else {
    showMessage?.call(
      KiamiStrings.uploadPartialSuccess(uploaded, failed),
    );
  }
}
