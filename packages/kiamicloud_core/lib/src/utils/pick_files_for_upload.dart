import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'kiami_web_file_picker.dart';

/// Seleccionador multi-ficheiro unificado — Web, Android e desktop.
Future<List<PlatformFile>?> pickFilesForUpload({
  bool allowMultiple = true,
}) async {
  if (kIsWeb) {
    return pickFilesWithWebInput(allowMultiple: allowMultiple);
  }

  final picked = await FilePicker.platform.pickFiles(
    allowMultiple: allowMultiple,
    type: FileType.any,
    withData: false,
    withReadStream: true,
  );

  if (picked == null || picked.files.isEmpty) return null;
  return picked.files;
}
