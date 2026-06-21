import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/upload/upload_debug.dart';
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
  String httpMethod = 'PUT',
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
  String httpMethod = 'POST',
}) async {
  final payload = uploadBodyAsUint8List(bytes);
  final method = httpMethod.toUpperCase() == 'PUT' ? 'PUT' : 'POST';
  final requestHeaders = <String, String>{
    ...headers,
    'Content-Type': contentType,
  };

  UploadDebug.log(
    'transfer $method ${payload.length} bytes → $url',
  );

  onProgress?.call(0, payload.length);

  try {
    return await _xhrUpload(
      method: method,
      url: url,
      headers: requestHeaders,
      body: payload,
      timeout: timeout,
      onProgress: onProgress,
    );
  } on TimeoutException {
    UploadDebug.log('transfer timeout');
    return const UploadPutResponse(statusCode: 0, body: '');
  } catch (e, st) {
    UploadDebug.fail('transfer_xhr', e, stackTrace: st);
    final msg = e.toString();
    if (msg.contains('Failed to fetch') ||
        msg.contains('NetworkError') ||
        msg.contains('Connection')) {
      return const UploadPutResponse(statusCode: 0, body: '');
    }
    rethrow;
  }
}

Future<UploadPutResponse> _xhrUpload({
  required String method,
  required String url,
  required Map<String, String> headers,
  required Uint8List body,
  Duration? timeout,
  UploadProgressCallback? onProgress,
}) async {
  final xhr = html.HttpRequest();
  xhr.open(method, url);

  for (final entry in headers.entries) {
    try {
      xhr.setRequestHeader(entry.key, entry.value);
    } catch (_) {
      // Alguns headers são geridos pelo browser (ex.: Content-Length).
    }
  }

  if (timeout != null) {
    xhr.timeout = timeout.inMilliseconds;
  }

  final completer = Completer<UploadPutResponse>();

  void finish(UploadPutResponse response) {
    if (completer.isCompleted) return;
    UploadDebug.log(
      'transfer resposta status=${response.statusCode} '
      'body=${response.body.length} chars',
    );
    if (kDebugMode && response.statusCode == 0) {
      UploadDebug.log(
        'transfer status=0 — verifique CORS/rede no separador Network (F12)',
      );
    }
    completer.complete(response);
  }

  xhr.upload.onProgress.listen((event) {
    if (!event.lengthComputable || onProgress == null) return;
    onProgress(event.loaded!, event.total!);
  });

  xhr.onReadyStateChange.listen((_) {
    if (xhr.readyState != html.HttpRequest.DONE) return;
    finish(
      UploadPutResponse(
        statusCode: xhr.status ?? 0,
        body: xhr.responseText ?? '',
      ),
    );
  });

  xhr.onError.listen((_) {
    finish(const UploadPutResponse(statusCode: 0, body: ''));
  });

  xhr.onTimeout.listen((_) {
    finish(const UploadPutResponse(statusCode: 0, body: ''));
  });

  xhr.send(html.Blob([body]));

  if (timeout != null) {
    return completer.future.timeout(
      timeout,
      onTimeout: () => const UploadPutResponse(statusCode: 0, body: ''),
    );
  }

  return completer.future;
}

Uint8List uploadBodyAsUint8List(List<int> bytes) {
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
