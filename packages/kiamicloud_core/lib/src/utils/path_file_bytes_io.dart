import 'dart:io';

Future<List<int>?> readPathFileBytes(String path, int maxBytes) async {
  final file = File(path);
  final length = await file.length();
  if (length > maxBytes) return null;
  return file.readAsBytes();
}
