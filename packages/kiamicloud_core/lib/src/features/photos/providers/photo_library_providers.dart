import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/photo_library_store.dart';
import '../models/photo_album.dart';

class PhotoLibraryState {
  const PhotoLibraryState({
    required this.favorites,
    required this.albums,
  });

  final Set<String> favorites;
  final List<PhotoAlbum> albums;

  bool isFavorite(String fileId) => favorites.contains(fileId);

  PhotoLibraryState copyWith({
    Set<String>? favorites,
    List<PhotoAlbum>? albums,
  }) {
    return PhotoLibraryState(
      favorites: favorites ?? this.favorites,
      albums: albums ?? this.albums,
    );
  }
}

final photoLibraryStoreProvider = FutureProvider<PhotoLibraryStore>((ref) {
  return PhotoLibraryStore.load();
});

final photoLibraryProvider =
    AsyncNotifierProvider<PhotoLibraryNotifier, PhotoLibraryState>(
  PhotoLibraryNotifier.new,
);

class PhotoLibraryNotifier extends AsyncNotifier<PhotoLibraryState> {
  PhotoLibraryStore? _store;

  @override
  Future<PhotoLibraryState> build() async {
    _store = await ref.watch(photoLibraryStoreProvider.future);
    return PhotoLibraryState(
      favorites: _store!.readFavorites(),
      albums: _store!.readAlbums(),
    );
  }

  Future<void> toggleFavorite(String fileId) async {
    final current = state.valueOrNull;
    if (current == null || _store == null) return;
    final next = Set<String>.from(current.favorites);
    if (next.contains(fileId)) {
      next.remove(fileId);
    } else {
      next.add(fileId);
    }
    await _store!.writeFavorites(next);
    state = AsyncData(current.copyWith(favorites: next));
  }

  Future<PhotoAlbum> createAlbum(String name, List<String> fileIds) async {
    final current = state.valueOrNull;
    if (current == null || _store == null) {
      throw StateError('Biblioteca de fotos indisponível');
    }
    final album = PhotoAlbum(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      fileIds: fileIds.toList(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    final albums = [...current.albums, album];
    await _store!.writeAlbums(albums);
    state = AsyncData(current.copyWith(albums: albums));
    return album;
  }

  Future<void> addFilesToAlbum(String albumId, List<String> fileIds) async {
    final current = state.valueOrNull;
    if (current == null || _store == null) return;
    final albums = current.albums.map((album) {
      if (album.id != albumId) return album;
      final merged = {...album.fileIds, ...fileIds}.toList();
      return album.copyWith(fileIds: merged);
    }).toList();
    await _store!.writeAlbums(albums);
    state = AsyncData(current.copyWith(albums: albums));
  }

  Future<void> removeFileReferences(String fileId) async {
    final current = state.valueOrNull;
    if (current == null || _store == null) return;
    final favorites = Set<String>.from(current.favorites)..remove(fileId);
    final albums = current.albums
        .map(
          (a) => a.copyWith(
            fileIds: a.fileIds.where((id) => id != fileId).toList(),
          ),
        )
        .where((a) => a.fileIds.isNotEmpty)
        .toList();
    await _store!.writeFavorites(favorites);
    await _store!.writeAlbums(albums);
    state = AsyncData(
      current.copyWith(favorites: favorites, albums: albums),
    );
  }
}
