import '../../../api/models/kiami_file.dart';

/// Acções disponíveis na galeria de vídeos (download, remover).
class VideoGalleryActions {
  const VideoGalleryActions({
    required this.onDelete,
    required this.onDownload,
  });

  final Future<void> Function(KiamiFile file) onDelete;
  final Future<void> Function(KiamiFile file) onDownload;
}
