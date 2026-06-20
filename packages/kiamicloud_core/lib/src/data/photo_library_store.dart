import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/photos/models/photo_album.dart';

/// Persistência local de favoritos e álbuns de fotos.
class PhotoLibraryStore {
  PhotoLibraryStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _favoritesKey = 'photo_favorites_v1';
  static const _albumsKey = 'photo_albums_v1';

  static Future<PhotoLibraryStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PhotoLibraryStore._(prefs);
  }

  Set<String> readFavorites() {
    final raw = _prefs.getStringList(_favoritesKey);
    if (raw == null) return {};
    return raw.toSet();
  }

  Future<void> writeFavorites(Set<String> ids) {
    return _prefs.setStringList(_favoritesKey, ids.toList());
  }

  List<PhotoAlbum> readAlbums() {
    final raw = _prefs.getString(_albumsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PhotoAlbum.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeAlbums(List<PhotoAlbum> albums) {
    final encoded = jsonEncode(albums.map((a) => a.toJson()).toList());
    return _prefs.setString(_albumsKey, encoded);
  }
}
