import '../../../api/models/kiami_file.dart';

/// Modo de apresentação dos ficheiros.
enum FileListViewMode {
  list,
  grid,
  details,
}

/// Ordenação da lista de ficheiros.
enum FileListSortOption {
  nameAsc,
  nameDesc,
  sizeAsc,
  sizeDesc,
  dateAsc,
  dateDesc,
}

List<KiamiFile> sortKiamiFiles(List<KiamiFile> files, FileListSortOption sort) {
  final list = List<KiamiFile>.from(files);
  list.sort((a, b) {
    final cmp = switch (sort) {
      FileListSortOption.nameAsc || FileListSortOption.nameDesc =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      FileListSortOption.sizeAsc || FileListSortOption.sizeDesc =>
        a.sizeBytes.compareTo(b.sizeBytes),
      FileListSortOption.dateAsc || FileListSortOption.dateDesc =>
        _fileDate(a).compareTo(_fileDate(b)),
    };
    final asc = switch (sort) {
      FileListSortOption.nameAsc ||
      FileListSortOption.sizeAsc ||
      FileListSortOption.dateAsc =>
        true,
      FileListSortOption.nameDesc ||
      FileListSortOption.sizeDesc ||
      FileListSortOption.dateDesc =>
        false,
    };
    return asc ? cmp : -cmp;
  });
  return list;
}

DateTime _fileDate(KiamiFile file) {
  try {
    return DateTime.parse(file.createdAt);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
