import '../../../api/models/kiami_file.dart';

/// Acções disponíveis na galeria de áudio (download, remover).
class AudioGalleryActions {
  const AudioGalleryActions({
    required this.onDelete,
    required this.onDownload,
  });

  final Future<void> Function(KiamiFile file) onDelete;
  final Future<void> Function(KiamiFile file) onDownload;
}
