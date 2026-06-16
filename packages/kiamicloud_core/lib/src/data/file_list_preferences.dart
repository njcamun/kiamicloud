import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/files/presentation/file_list_sort.dart';

/// Preferências de vista/ordenação por categoria (persistidas localmente).
class FileListPreferences {
  FileListPreferences._(this._prefs);

  final SharedPreferences _prefs;

  static const _viewPrefix = 'file_view_';
  static const _sortPrefix = 'file_sort_';

  static Future<FileListPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return FileListPreferences._(prefs);
  }

  FileListViewMode getViewMode(String categoryId) {
    final raw = _prefs.getString('$_viewPrefix$categoryId');
    return FileListViewMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => FileListViewMode.list,
    );
  }

  Future<void> setViewMode(String categoryId, FileListViewMode mode) {
    return _prefs.setString('$_viewPrefix$categoryId', mode.name);
  }

  FileListSortOption getSortOption(String categoryId) {
    final raw = _prefs.getString('$_sortPrefix$categoryId');
    return FileListSortOption.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => FileListSortOption.nameAsc,
    );
  }

  Future<void> setSortOption(String categoryId, FileListSortOption sort) {
    return _prefs.setString('$_sortPrefix$categoryId', sort.name);
  }
}

final fileListPreferencesProvider = FutureProvider<FileListPreferences>((ref) {
  return FileListPreferences.load();
});
