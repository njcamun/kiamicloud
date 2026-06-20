import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'upload_put_response.dart';

Future<UploadPutResponse> putUploadFile({
  http.Client? client,
  required String url,
  required String filePath,
  required int totalBytes,
  required String contentType,
  required Map<String, String> headers,
  UploadProgressCallback? onProgress,
  Duration? timeout,
}) {
  throw UnsupportedError('putUploadFile is not supported on web.');
}

Future<UploadPutResponse> putUploadBytes({
  http.Client? client,
  required String url,
  required List<int> bytes,
  required String contentType,
  required Map<String, String> headers,
  UploadProgressCallback? onProgress,
  Duration? timeout,
}) async {
  final xhr = html.HttpRequest();
  xhr.open('PUT', url);
  xhr.setRequestHeader('Content-Type', contentType);
  for (final entry in headers.entries) {
    xhr.setRequestHeader(entry.key, entry.value);
  }

  final completer = Completer<UploadPutResponse>();
  Timer? timer;

  void complete(UploadPutResponse result) {
    timer?.cancel();
    if (!completer.isCompleted) completer.complete(result);
  }

  if (timeout != null) {
    timer = Timer(timeout, () {
      xhr.abort();
      complete(const UploadPutResponse(statusCode: 0, body: ''));
    });
  }

  xhr.upload.onProgress.listen((event) {
    if (event.lengthComputable) {
      onProgress?.call(event.loaded!, event.total!);
    }
  });

  xhr.onLoad.listen((_) {
    complete(
      UploadPutResponse(
        statusCode: xhr.status ?? 0,
        body: xhr.responseText ?? '',
      ),
    );
  });

  xhr.onError.listen((_) {
    complete(const UploadPutResponse(statusCode: 0, body: ''));
  });

  xhr.onAbort.listen((_) {
    complete(const UploadPutResponse(statusCode: 0, body: ''));
  });

  final payload = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  onProgress?.call(0, payload.length);
  xhr.send(payload);

  return completer.future;
}

Uint8List uploadBodyAsUint8List(List<int> bytes) {
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
