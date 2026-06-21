import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

final _registry = <String, html.File>{};

bool isWebFileRegistryRef(String? ref) =>
    ref != null && ref.isNotEmpty && ref.startsWith('wf_');

String registerWebFile(html.File file) {
  final id =
      'wf_${DateTime.now().microsecondsSinceEpoch}_${file.name.hashCode}_${_registry.length}';
  _registry[id] = file;
  return id;
}

void discardWebFileRegistryRef(String ref) {
  _registry.remove(ref);
}

Future<List<int>?> readWebFileRegistryBytes(
  String ref, {
  required int maxBytes,
}) async {
  final file = _registry[ref];
  if (file == null) return null;
  final bytes = await _readFileAsBytes(file);
  if (bytes.isEmpty) return null;
  if (bytes.length > maxBytes) return null;
  return bytes;
}

void consumeWebFileRegistryRef(String ref) {
  _registry.remove(ref);
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
