import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/api/models/kiami_file.dart';
import 'package:kiamicloud_core/src/features/files/presentation/file_list_sort.dart';

void main() {
  final files = [
    const KiamiFile(
      id: '1',
      name: 'zebra.txt',
      mimeType: 'text/plain',
      sizeBytes: 100,
      status: 'active',
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    ),
    const KiamiFile(
      id: '2',
      name: 'alpha.txt',
      mimeType: 'text/plain',
      sizeBytes: 500,
      status: 'active',
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    ),
  ];

  test('sortKiamiFiles by name ascending', () {
    final sorted = sortKiamiFiles(files, FileListSortOption.nameAsc);
    expect(sorted.first.name, 'alpha.txt');
  });

  test('sortKiamiFiles by size descending', () {
    final sorted = sortKiamiFiles(files, FileListSortOption.sizeDesc);
    expect(sorted.first.sizeBytes, 500);
  });
}
