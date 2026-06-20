import '../../../api/models/kiami_file.dart';

/// Acções disponíveis na galeria de fotos (favorito, álbum, remover).
class PhotoGalleryActions {
  const PhotoGalleryActions({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onAddToAlbum,
  });

  final bool Function(String fileId) isFavorite;
  final Future<void> Function(KiamiFile file) onToggleFavorite;
  final Future<void> Function(KiamiFile file) onDelete;
  final Future<void> Function(KiamiFile file) onAddToAlbum;
}
