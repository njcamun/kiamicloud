import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'path_file_bytes.dart';

/// Motivo pelo qual um ficheiro seleccionado não pode ser enviado.
enum UploadFileRejectReason {
  tooLargePerFile,
  exceedsQuota,
  unreadable,
}

/// Resultado da validação/leitura de um ficheiro para upload.
sealed class UploadFilePickOutcome {}

class UploadFileReady extends UploadFilePickOutcome {
  UploadFileReady({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

class UploadFileRejected extends UploadFilePickOutcome {
  UploadFileRejected({
    required this.name,
    required this.reason,
    this.sizeBytes,
  });

  final String name;
  final UploadFileRejectReason reason;
  final int? sizeBytes;
}

int platformFileEffectiveSize(PlatformFile file) {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes!.length;
  }
  return file.size;
}

bool platformFileHasSource(PlatformFile file) {
  return (file.bytes != null && file.bytes!.isNotEmpty) ||
      file.readStream != null ||
      (!kIsWeb && file.path != null && file.path!.isNotEmpty);
}

/// Valida tamanho sem ler o ficheiro (multi-upload — evita OOM).
UploadFilePickOutcome validatePlatformFileForUpload({
  required PlatformFile file,
  required int maxFileBytes,
  required int storageAvailableBytes,
}) {
  final name = file.name;

  if (!platformFileHasSource(file)) {
    return UploadFileRejected(
      name: name,
      reason: UploadFileRejectReason.unreadable,
      sizeBytes: file.size,
    );
  }

  final effectiveSize = platformFileEffectiveSize(file);
  if (effectiveSize <= 0) {
    // Web: bytes ainda por carregar (stream) — validar depois da leitura.
    if (file.readStream != null || (file.bytes != null && file.bytes!.isEmpty)) {
      return UploadFileReady(name: name, bytes: const []);
    }
    return UploadFileRejected(
      name: name,
      reason: UploadFileRejectReason.unreadable,
      sizeBytes: effectiveSize,
    );
  }

  if (effectiveSize > maxFileBytes) {
    return UploadFileRejected(
      name: name,
      reason: UploadFileRejectReason.tooLargePerFile,
      sizeBytes: effectiveSize,
    );
  }
  if (effectiveSize > storageAvailableBytes) {
    return UploadFileRejected(
      name: name,
      reason: UploadFileRejectReason.exceedsQuota,
      sizeBytes: effectiveSize,
    );
  }

  return UploadFileReady(name: name, bytes: const []);
}

/// Lê bytes de um [PlatformFile] só depois de validar o tamanho (evita OOM).
Future<UploadFilePickOutcome> readPlatformFileForUpload({
  required PlatformFile file,
  required int maxFileBytes,
  required int storageAvailableBytes,
}) async {
  final name = file.name;
  final reportedSize = platformFileEffectiveSize(file);

  if (reportedSize > 0) {
    if (reportedSize > maxFileBytes) {
      return UploadFileRejected(
        name: name,
        reason: UploadFileRejectReason.tooLargePerFile,
        sizeBytes: reportedSize,
      );
    }
    if (reportedSize > storageAvailableBytes) {
      return UploadFileRejected(
        name: name,
        reason: UploadFileRejectReason.exceedsQuota,
        sizeBytes: reportedSize,
      );
    }
  }

  try {
    final bytes = await _loadBytes(file, maxFileBytes);
    if (bytes == null || bytes.isEmpty) {
      return UploadFileRejected(
        name: name,
        reason: UploadFileRejectReason.unreadable,
        sizeBytes: reportedSize,
      );
    }

    if (bytes.length > maxFileBytes) {
      return UploadFileRejected(
        name: name,
        reason: UploadFileRejectReason.tooLargePerFile,
        sizeBytes: bytes.length,
      );
    }
    if (bytes.length > storageAvailableBytes) {
      return UploadFileRejected(
        name: name,
        reason: UploadFileRejectReason.exceedsQuota,
        sizeBytes: bytes.length,
      );
    }

    return UploadFileReady(name: name, bytes: bytes);
  } catch (_) {
    return UploadFileRejected(
      name: name,
      reason: UploadFileRejectReason.unreadable,
      sizeBytes: reportedSize,
    );
  }
}

Future<List<int>?> _loadBytes(PlatformFile file, int maxBytes) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes;
  }

  if (kIsWeb && file.readStream != null) {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in file.readStream!) {
      total += chunk.length;
      if (total > maxBytes) return null;
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
    return readPathFileBytes(file.path!, maxBytes);
  }

  final stream = file.readStream;
  if (stream != null) {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in stream) {
      total += chunk.length;
      if (total > maxBytes) return null;
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  return null;
}

/// Lê bytes de um [PlatformFile] (memória, path ou stream).
Future<List<int>?> readPlatformFileBytes(
  PlatformFile file, {
  required int maxBytes,
}) =>
    _loadBytes(file, maxBytes);
