import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
}) async {
  final file = File(filePath);
  final httpClient = client ?? http.Client();
  final uri = Uri.parse(url);
  final request = http.StreamedRequest('PUT', uri);
  request.headers.addAll(headers);
  request.headers['Content-Type'] = contentType;
  request.contentLength = totalBytes;

  onProgress?.call(0, totalBytes);

  const chunkSize = 256 * 1024;

  Future<void> writeBody() async {
    final raf = await file.open();
    try {
      var offset = 0;
      while (offset < totalBytes) {
        final toRead = math.min(chunkSize, totalBytes - offset);
        final chunk = await raf.read(toRead);
        if (chunk.isEmpty) break;
        request.sink.add(chunk);
        offset += chunk.length;
        onProgress?.call(offset, totalBytes);
      }
    } finally {
      await raf.close();
    }
    await request.sink.close();
  }

  final responseFuture = httpClient.send(request);
  await writeBody();

  final streamed = timeout != null
      ? await responseFuture.timeout(timeout)
      : await responseFuture;
  final responseBody = await streamed.stream.bytesToString();

  return UploadPutResponse(
    statusCode: streamed.statusCode,
    body: responseBody,
  );
}

Future<UploadPutResponse> putUploadBytes({
  http.Client? client,
  required String url,
  required List<int> bytes,
  required String contentType,
  required Map<String, String> headers,
  UploadProgressCallback? onProgress,
  Duration? timeout,
  String httpMethod = 'PUT',
}) async {
  final httpClient = client ?? http.Client();
  final uri = Uri.parse(url);
  final request = http.StreamedRequest(httpMethod.toUpperCase(), uri);
  request.headers.addAll(headers);
  request.headers['Content-Type'] = contentType;

  final total = bytes.length;
  onProgress?.call(0, total);

  const chunkSize = 256 * 1024;

  Future<void> writeBody() async {
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = math.min(offset + chunkSize, bytes.length);
      request.sink.add(bytes.sublist(offset, end));
      onProgress?.call(end, total);
    }
    await request.sink.close();
  }

  final responseFuture = httpClient.send(request);
  await writeBody();

  final streamed = timeout != null
      ? await responseFuture.timeout(timeout)
      : await responseFuture;
  final responseBody = await streamed.stream.bytesToString();

  return UploadPutResponse(
    statusCode: streamed.statusCode,
    body: responseBody,
  );
}

Uint8List uploadBodyAsUint8List(List<int> bytes) {
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
