import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/kiami_profile.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/kiami_api_limits.dart';
import '../../utils/format_bytes.dart';
import '../../utils/upload_file_reader.dart';
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
  final profile = ref.read(kiamiProfileProvider).valueOrNull;
  if (KiamiApiLimits.enforced && profile != null && !profile.quota.canUpload) {
    await onQuotaBlocked(profile);
    return;
  }

  final maxFileLimit = KiamiApiLimits.maxUploadFileBytes(
    profileMax: profile?.maxFileSizeBytes,
  );
  final maxFileBytes = maxFileLimit;
  var availableBytes = KiamiApiLimits.availableStorageBytes(
    profileAvailable: profile?.storageAvailableBytes,
  );

  final skippedTooLarge = <String>[];
  final skippedQuota = <String>[];
  final skippedNoBytes = <String>[];
  final queue = <UploadQueueRequest>[];
  final acceptedMeta = <({String name, int sizeBytes})>[];
  String? firstQuotaFileName;
  int? firstQuotaFileSize;

  for (final file in pickedFiles) {
    final outcome = validatePlatformFileForUpload(
      file: file,
      maxFileBytes: maxFileBytes,
      storageAvailableBytes: availableBytes,
    );

    switch (outcome) {
      case UploadFileReady(:final name):
        final size = file.size;
        final path = !kIsWeb && file.path != null && file.path!.isNotEmpty
            ? file.path
            : null;
        queue.add((
          name: name,
          sizeBytes: size,
          path: path,
          bytes: null,
        ));
        acceptedMeta.add((name: name, sizeBytes: size));
        availableBytes = (availableBytes - size).clamp(0, 1 << 62);
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

  if (queue.isEmpty) {
    if (!context.mounted) return;
    if (skippedQuota.isNotEmpty && profile != null) {
      await onFileExceedsQuota(
        profile: profile,
        fileName: firstQuotaFileName ?? skippedQuota.first,
        fileSizeBytes: firstQuotaFileSize,
      );
    } else if (skippedTooLarge.isNotEmpty) {
      showMessage?.call(
        KiamiStrings.uploadSkippedTooLarge(
          skippedTooLarge.length,
          formatTransferLimit(
            profile?.maxFileSizeBytes ?? 0,
          ),
        ),
      );
    } else if (skippedNoBytes.isNotEmpty) {
      showMessage?.call(
        KiamiStrings.uploadNoBytesMultiple(skippedNoBytes.length),
      );
    }
    return;
  }

  final notifier = ref.read(uploadQueueProvider.notifier);

  if (kIsWeb) {
    var enqueued = 0;
    for (final meta in acceptedMeta) {
      final file = pickedFiles.firstWhere(
        (f) => f.name == meta.name,
        orElse: () => pickedFiles.first,
      );
      final read = await readPlatformFileForUpload(
        file: file,
        maxFileBytes: maxFileBytes,
        storageAvailableBytes: availableBytes,
      );
      switch (read) {
        case UploadFileReady(:final name, :final bytes):
          notifier.enqueueAll([
            (name: name, sizeBytes: bytes.length, path: null, bytes: bytes),
          ]);
          enqueued += 1;
          availableBytes = (availableBytes - bytes.length).clamp(0, 1 << 62);
        case UploadFileRejected(:final name, :final reason):
          switch (reason) {
            case UploadFileRejectReason.tooLargePerFile:
              skippedTooLarge.add(name);
            case UploadFileRejectReason.exceedsQuota:
              skippedQuota.add(name);
            case UploadFileRejectReason.unreadable:
              skippedNoBytes.add(name);
          }
      }
    }
    if (enqueued > 0) {
      showMessage?.call(KiamiStrings.uploadBackgroundStarted(enqueued));
    }
    _showPartialResult(
      showMessage: showMessage,
      uploaded: enqueued,
      skippedTooLarge: skippedTooLarge,
      skippedNoBytes: skippedNoBytes,
      maxFileBytes: maxFileBytes,
    );
    return;
  }

  notifier.enqueueAll(queue);
  showMessage?.call(KiamiStrings.uploadBackgroundStarted(queue.length));

  _showPartialResult(
    showMessage: showMessage,
    uploaded: queue.length,
    skippedTooLarge: skippedTooLarge,
    skippedNoBytes: skippedNoBytes,
    maxFileBytes: maxFileBytes,
  );
}

void _showPartialResult({
  void Function(String message)? showMessage,
  required int uploaded,
  required List<String> skippedTooLarge,
  required List<String> skippedNoBytes,
  required int maxFileBytes,
}) {
  if (skippedTooLarge.isEmpty && skippedNoBytes.isEmpty) return;
  final maxLabel = formatTransferLimit(maxFileBytes >= (1 << 62) ? 0 : maxFileBytes);
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
