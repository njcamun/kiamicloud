import 'dart:async';

import 'dart:typed_data';



import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../api/kiami_api_config.dart';

import '../../api/models/kiami_profile.dart';

import '../../constants/kiami_constants.dart';
import '../../constants/kiami_strings.dart';

import '../../utils/kiami_api_limits.dart';

import '../../utils/format_bytes.dart';

import '../../utils/kiami_web_file_registry.dart';

import '../../utils/upload_file_reader.dart';

import '../../widgets/kiami_unavailable.dart';

import '../files/providers/files_providers.dart';

import 'upload_debug.dart';

import 'upload_diagnostic.dart';

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

  if (pickedFiles.isEmpty) {

    UploadDebug.log('handleFiles: lista vazia');

    return;

  }



  UploadDebug.log(

    'handleFiles: ${pickedFiles.length} ficheiro(s) — api=${KiamiApiConfig.baseUrl}',

  );



  _notify(showMessage, context, KiamiStrings.uploadPreparing);



  KiamiProfile? profile = ref.read(kiamiProfileProvider).valueOrNull;

  if (KiamiApiLimits.enforced) {

    UploadDebug.log('handleFiles: a actualizar perfil (/me)...');

    ref.invalidate(kiamiProfileProvider);

    try {

      profile = await ref

          .read(kiamiProfileProvider.future)

          .timeout(const Duration(seconds: 25));

      UploadDebug.log(

        'handleFiles: perfil OK uid=${profile.uid} '

        'disponível=${formatBytes(profile.storageAvailableBytes)}',

      );

    } on TimeoutException catch (e, st) {

      UploadDebug.fail('profile_timeout', e, stackTrace: st);

      if (!context.mounted) return;

      final report = buildEarlyUploadReport(

        stage: 'profile_timeout',

        message: 'Timeout ao carregar perfil (/me).',

        error: e,

        stackTrace: st,

      );

      await presentUploadDiagnostic(context, report: report, ref: ref);

      await showKiamiNoConnectDialog(context);

      return;

    } catch (e, st) {

      UploadDebug.fail('profile_load', e, stackTrace: st);

      if (!context.mounted) return;

      final report = buildEarlyUploadReport(

        stage: 'profile_load',

        message: kiamiApiErrorMessage(e),

        error: e,

        stackTrace: st,

      );

      await presentUploadDiagnostic(context, report: report, ref: ref);

      await showKiamiNoConnectDialog(context);

      return;

    }

  }



  if (profile != null && profile.emailVerified == false) {

    UploadDebug.log('handleFiles: e-mail não verificado');

    if (!context.mounted) return;

    final report = buildEarlyUploadReport(

      stage: 'email_not_verified',

      message: KiamiStrings.emailVerificationRequired,

    );

    await presentUploadDiagnostic(context, report: report, ref: ref);

    _notify(showMessage, context, KiamiStrings.emailVerificationRequired);

    return;

  }



  if (KiamiApiLimits.enforced && profile != null) {

    final access = profile.access;

    if (access != null && !access.canUpload) {

      UploadDebug.log('handleFiles: subscrição bloqueia upload');

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

      UploadDebug.log('handleFiles: quota cheia');

      if (!context.mounted) return;

      await onQuotaBlocked(profile);

      return;

    }

  }



  final maxFileBytes = KiamiApiLimits.maxUploadFileBytes(

    profileMax: profile?.maxFileSizeBytes,

  );

  final batchTotalBytes = pickedFiles.fold<int>(

    0,

    (sum, f) => sum + (f.size > 0 ? f.size : (f.bytes?.length ?? 0)),

  );

  final maxPerFileLabel = formatTransferLimit(
    (profile?.maxFileSizeBytes ?? 0) > 0
        ? profile!.maxFileSizeBytes
        : (maxFileBytes >= (1 << 62)
            ? KiamiConstants.maxUploadBytes
            : maxFileBytes),
  );

  UploadDebug.log(

    'handleFiles: lote=${pickedFiles.length} ficheiro(s) '

    '(${formatBytes(batchTotalBytes)} total, máx/ficheiro=$maxPerFileLabel)',

  );



  final skippedTooLarge = <String>[];

  final skippedNoBytes = <String>[];



  final notifier = ref.read(uploadQueueProvider.notifier);

  final toEnqueue = <UploadQueueRequest>[];



  for (final file in pickedFiles) {

    UploadDebug.log(

      'handleFiles: ficheiro "${file.name}" size=${file.size} '

      'bytes=${file.bytes?.length ?? 0}',

    );



    var normalized = file;

    if (!platformFileHasSource(file) || platformFileShouldPreloadBytes(file)) {

      UploadDebug.log('handleFiles: a ler bytes de ${file.name}...');

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

      checkStorageQuota: false,

    );



    switch (outcome) {

      case UploadFileReady(:final name):

        final path = _uploadPathForPlatformFile(normalized);

        List<int>? inMemory = normalized.bytes != null && normalized.bytes!.isNotEmpty

            ? List<int>.from(normalized.bytes!)

            : null;

        if (inMemory == null &&

            path == null &&

            normalized.readStream != null) {

          final bytes =

              await readPlatformFileBytes(normalized, maxBytes: maxFileBytes);

          if (bytes == null || bytes.isEmpty) {

            skippedNoBytes.add(name);

            continue;

          }

          inMemory = bytes;

        }

        if (inMemory == null || inMemory.isEmpty) {

          UploadDebug.log('handleFiles: sem bytes para $name');

          skippedNoBytes.add(name);

          continue;

        }

        final reserved = inMemory.length;

        UploadDebug.log('handleFiles: aceite $name ($reserved bytes)');

        toEnqueue.add(

          (

            name: name,

            sizeBytes: inMemory.length,

            path: path,

            bytes: inMemory,

          ),

        );

      case UploadFileRejected(:final name, :final reason):

        UploadDebug.log('handleFiles: rejeitado $name — $reason');

        switch (reason) {

          case UploadFileRejectReason.tooLargePerFile:

            skippedTooLarge.add(name);

          case UploadFileRejectReason.exceedsQuota:

            skippedTooLarge.add(name);

          case UploadFileRejectReason.unreadable:

            skippedNoBytes.add(name);

        }

    }

  }



  if (!context.mounted) return;



  final enqueued = toEnqueue.length;

  if (enqueued > 0) {

    UploadDebug.log('handleFiles: enfileirar $enqueued ficheiro(s) — processQueue');

    notifier.enqueueAll(toEnqueue);

    _notify(showMessage, context, KiamiStrings.uploadBackgroundStarted(enqueued));

  }



  if (enqueued == 0) {

    UploadDebug.log(

      'handleFiles: nada enfileirado — '

      'noBytes=${skippedNoBytes.length} large=${skippedTooLarge.length}',

    );

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

      final report = buildEarlyUploadReport(

        stage: 'read_bytes',

        message: KiamiStrings.uploadNoBytesMultiple(skippedNoBytes.length),

        fileName: skippedNoBytes.first,

      );

      await presentUploadDiagnostic(context, report: report, ref: ref);

      _notify(

        showMessage,

        context,

        KiamiStrings.uploadNoBytesMultiple(skippedNoBytes.length),

      );

      return;

    }

    final report = buildEarlyUploadReport(

      stage: 'enqueue',

      message: KiamiStrings.uploadNothingEnqueued,

    );

    await presentUploadDiagnostic(context, report: report, ref: ref);

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



String? _uploadPathForPlatformFile(PlatformFile file) {
  if (!kIsWeb) {
    final path = file.path;
    if (path != null && path.isNotEmpty) return path;
  }
  if (kIsWeb && isWebFileRegistryRef(file.identifier)) {
    return file.identifier;
  }
  return null;
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

  if (skippedTooLarge.isEmpty && skippedNoBytes.isEmpty) {

    return;

  }

  if (!context.mounted) return;

  final maxLabel =

      formatTransferLimit(maxFileBytes >= (1 << 62) ? 0 : maxFileBytes);

  final failed = skippedTooLarge.length + skippedNoBytes.length;

  if (skippedTooLarge.isNotEmpty && skippedNoBytes.isEmpty) {

    showMessage?.call(

      KiamiStrings.uploadPartialSuccessWithLimit(uploaded, failed, maxLabel),

    );

    return;

  }

  showMessage?.call(KiamiStrings.uploadPartialSuccess(uploaded, failed));

}


