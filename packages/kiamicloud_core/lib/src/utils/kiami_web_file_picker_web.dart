import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Seleccionador de ficheiros via `<input type="file">` — fiável na Web.
Future<List<PlatformFile>?> pickFilesWithWebInput({
  bool allowMultiple = true,
}) async {
  final input = html.FileUploadInputElement()
    ..accept = '*/*'
    ..style.display = 'none';

  if (allowMultiple) {
    input.multiple = true;
    input.setAttribute('multiple', '');
  }

  html.document.body?.children.add(input);

  try {
    input.click();
    await input.onChange.first;

    final list = input.files;
    if (list == null || list.isEmpty) return null;

    final out = <PlatformFile>[];
    for (var i = 0; i < list.length; i++) {
      final file = list[i];
      final bytes = await _readFileAsBytes(file);
      if (bytes.isEmpty) continue;
      out.add(
        PlatformFile(
          name: file.name,
          size: bytes.length,
          bytes: bytes,
        ),
      );
    }

    return out.isEmpty ? null : out;
  } on TimeoutException {
    return null;
  } finally {
    input.remove();
  }
}

Future<Uint8List> _readFileAsBytes(html.File file) async {
  final reader = html.FileReader();
  final done = Completer<Uint8List>();
  reader.onLoad.listen((_) {
    final raw = reader.result;
    if (raw is ByteBuffer) {
      done.complete(raw.asUint8List());
    } else if (raw is Uint8List) {
      done.complete(raw);
    } else {
      done.complete(Uint8List(0));
    }
  });
  reader.onError.listen((_) => done.complete(Uint8List(0)));
  reader.readAsArrayBuffer(file);
  return done.future;
}
