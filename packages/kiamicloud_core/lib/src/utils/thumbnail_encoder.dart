import 'dart:typed_data';

import 'package:image/image.dart' as img;

const int kThumbnailMaxSide = 320;
const int kThumbnailJpegQuality = 82;

/// Gera JPEG reduzido para miniatura na grelha. Devolve null se nao for imagem raster.
Uint8List? encodeThumbnailJpeg(List<int> bytes) {
  try {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? kThumbnailMaxSide : null,
      height: decoded.height > decoded.width ? kThumbnailMaxSide : null,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: kThumbnailJpegQuality),
    );
  } catch (_) {
    return null;
  }
}

bool canGenerateThumbnail(String fileName, [String? mimeType]) {
  final mime = mimeType?.toLowerCase() ?? '';
  if (mime == 'image/svg+xml') return false;
  if (mime.startsWith('image/')) return true;

  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  return switch (ext) {
    'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'bmp' || 'heic' || 'heif' =>
      true,
    _ => false,
  };
}
