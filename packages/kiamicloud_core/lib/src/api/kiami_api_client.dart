import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/kiami_constants.dart';
import '../constants/kiami_strings.dart';
import '../features/auth/data/firebase_id_token.dart';
import 'kiami_api_config.dart';
import 'kiami_api_exception.dart';
import 'upload_put_client.dart';
import 'models/kiami_file.dart';
import 'models/kiami_account_event.dart';
import 'models/kiami_admin.dart';
import 'models/kiami_audit_action.dart';
import 'models/kiami_billing_status.dart';
import 'models/kiami_checkout.dart';
import 'models/kiami_plan.dart';
import 'models/kiami_profile.dart';
import 'models/file_thumbnail_url.dart';
import 'models/thumbnail_upload_info.dart';
import 'models/upload_init_result.dart';
import '../utils/thumbnail_encoder.dart';

class KiamiApiClient {
  KiamiApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  static Duration get _timeout =>
      kIsWeb ? const Duration(seconds: 45) : const Duration(seconds: 25);

  static const int _webRetryCount = 2;
  static const Duration _retryDelay = Duration(milliseconds: 900);

  /// Timeout proporcional ao tamanho (mín. 2 min, máx. 30 min) —
  /// ficheiros grandes (ex.: 300 MB) demoram vários minutos em Wi-Fi.
  static Duration _transferTimeout(int sizeBytes) {
    const minSeconds = 120;
    const maxSeconds = 1800;
    // Débito mínimo assumido: ~512 KB/s + folga de 60 s.
    final estimated = 60 + (sizeBytes / (512 * 1024)).ceil();
    return Duration(seconds: estimated.clamp(minSeconds, maxSeconds));
  }

  Uri _uri(String path) => Uri.parse('${KiamiApiConfig.baseUrl}$path');

  static KiamiApiException connectionError() {
    return KiamiApiException(
      KiamiStrings.apiUnavailableBody(KiamiApiConfig.baseUrl),
      errorCode: 'connection_failed',
    );
  }

  Future<http.Response> _run(
    Future<http.Response> Function() request, {
    Duration? timeout,
    int retries = 0,
  }) async {
    final effectiveRetries =
        kIsWeb ? (retries > 0 ? retries : _webRetryCount) : retries;

    for (var attempt = 0; attempt <= effectiveRetries; attempt++) {
      try {
        return await request().timeout(timeout ?? _timeout);
      } on TimeoutException {
        if (attempt >= effectiveRetries) {
          throw KiamiApiException(
            KiamiStrings.apiUnavailableTimeout,
            errorCode: 'connection_failed',
          );
        }
      } on KiamiApiException {
        rethrow;
      } on http.ClientException {
        if (attempt >= effectiveRetries) {
          throw connectionError();
        }
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('SocketException') ||
            msg.contains('Connection') ||
            msg.contains('connection abort') ||
            msg.contains('Failed to fetch') ||
            msg.contains('NetworkError')) {
          if (attempt >= effectiveRetries) {
            throw connectionError();
          }
        } else {
          rethrow;
        }
      }

      await Future<void>.delayed(_retryDelay * (attempt + 1));
    }

    throw connectionError();
  }

  Future<Map<String, String>> _authHeaders({bool jsonBody = false}) async {
    final token = await FirebaseIdTokenService.getIdToken();
    if (token == null) {
      throw KiamiApiException('Sessão expirada. Inicie sessão novamente.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }

  /// Headers Bearer para pedidos de conteudo binario (download / miniatura).
  Future<Map<String, String>> _authHeadersForBinary() async {
    final headers = await _authHeaders();
    headers['Accept'] = '*/*';
    return headers;
  }

  /// Flutter Web: pede URLs via proxy Worker (evita CORS do R2).
  void _applyWebWorkerHeaders(
    Map<String, String> headers, {
    bool media = false,
    bool upload = false,
  }) {
    if (!kIsWeb) return;
    if (media) headers['X-Kiami-Media-Via'] = 'worker';
    if (upload) headers['X-Kiami-Upload-Via'] = 'worker';
  }

  Never _throwFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body['message'] as String? ?? 'Erro na API (${response.statusCode}).';
      throw KiamiApiException(
        message,
        statusCode: response.statusCode,
        errorCode: body['error'] as String?,
        maxFileSizeBytes: (body['maxFileSizeBytes'] as num?)?.toInt(),
      );
    } catch (e) {
      if (e is KiamiApiException) rethrow;
      throw KiamiApiException(
        'Erro na API (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> pingHealth({Duration? timeout}) async {
    return pingHealthAt(KiamiApiConfig.baseUrl, timeout: timeout);
  }

  static Future<Map<String, dynamic>> pingHealthAt(
    String baseUrl, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ??
        (kIsWeb ? const Duration(seconds: 15) : const Duration(seconds: 8));
    final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalized/health/ping');
    final client = http.Client();
    try {
      final response = await client.get(uri).timeout(effectiveTimeout);
      if (response.statusCode != 200) {
        throw KiamiApiException(
          'Erro na API (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw connectionError();
    } on KiamiApiException {
      rethrow;
    } on http.ClientException {
      throw connectionError();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection') ||
          msg.contains('connection abort')) {
        throw connectionError();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getBetaInfo() async {
    final response = await _run(
      () => _http.get(_uri('/beta/info')),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> sendBetaFeedback({
    required String message,
    String? appVersion,
    String? platform,
    String? apiBaseUrl,
  }) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/beta/feedback'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          if (appVersion != null) 'appVersion': appVersion,
          if (platform != null) 'platform': platform,
          if (apiBaseUrl != null) 'apiBaseUrl': apiBaseUrl,
        }),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
  }

  Future<KiamiProfile> getMe() async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/me'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return KiamiProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteAccount() async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.delete(
        _uri('/me'),
        headers: headers,
        body: jsonEncode({'confirm': 'APAGAR'}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
  }

  Future<List<KiamiFile>> listFiles() async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/files'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['files'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UploadInitResult> initUpload({
    required String name,
    required int sizeBytes,
    String? mimeType,
  }) async {
    final headers = await _authHeaders(jsonBody: true);
    _applyWebWorkerHeaders(headers, upload: true);
    final body = jsonEncode({
      'name': name,
      'sizeBytes': sizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
    });
    final response = await _run(
      () => _http.post(_uri('/files/upload/init'), headers: headers, body: body),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return UploadInitResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<KiamiFile> uploadFile({
    required String name,
    required List<int> bytes,
    String? mimeType,
    UploadProgressCallback? onProgress,
  }) async {
    final resolvedMime = mimeType ?? 'application/octet-stream';
    final init = await initUpload(
      name: name,
      sizeBytes: bytes.length,
      mimeType: resolvedMime,
    );

    final viaWorker = kIsWeb || init.localDevUpload;
    final putUrl = viaWorker
        ? _uri('/files/upload/direct/${init.fileId}').toString()
        : init.uploadUrl;

    final putResponse = await _putUploadBytes(
      url: putUrl,
      bytes: bytes,
      contentType: resolvedMime,
      useAuth: viaWorker,
      onProgress: onProgress,
    );

    if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
      _throwUploadPutFailure(putResponse);
    }

    KiamiFile file;
    if (viaWorker) {
      file = _parseUploadPutFile(putResponse);
    } else {
      file = await completeUpload(init.fileId);
    }

    if (init.thumbnail != null &&
        canGenerateThumbnail(name, resolvedMime) &&
        bytes.length <= KiamiConstants.maxUploadBytes) {
      final thumbBytes = await encodeThumbnailJpegAsync(bytes);
      if (thumbBytes != null) {
        try {
          file = await _uploadThumbnail(
            fileId: init.fileId,
            thumb: init.thumbnail!,
            bytes: thumbBytes,
          );
        } catch (_) {
          // Miniatura opcional — o ficheiro principal ja foi guardado.
        }
      }
    }

    return file;
  }

  Future<KiamiFile> uploadFilePath({
    required String name,
    required String filePath,
    required int sizeBytes,
    String? mimeType,
    UploadProgressCallback? onProgress,
  }) async {
    final resolvedMime = mimeType ?? 'application/octet-stream';
    final init = await initUpload(
      name: name,
      sizeBytes: sizeBytes,
      mimeType: resolvedMime,
    );

    final viaWorker = kIsWeb || init.localDevUpload;
    final putUrl = viaWorker
        ? _uri('/files/upload/direct/${init.fileId}').toString()
        : init.uploadUrl;

    final putResponse = await _putUploadFile(
      path: filePath,
      sizeBytes: sizeBytes,
      url: putUrl,
      contentType: resolvedMime,
      useAuth: viaWorker,
      onProgress: onProgress,
    );

    if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
      _throwUploadPutFailure(putResponse);
    }

    KiamiFile uploaded;
    if (viaWorker) {
      uploaded = _parseUploadPutFile(putResponse);
    } else {
      uploaded = await completeUpload(init.fileId);
    }

    return uploaded;
  }

  Future<http.Response> _putUploadFile({
    required String path,
    required int sizeBytes,
    required String url,
    required String contentType,
    required bool useAuth,
    UploadProgressCallback? onProgress,
  }) async {
    final headers = <String, String>{};
    if (useAuth) {
      final token = await FirebaseIdTokenService.getIdToken();
      if (token == null) {
        throw KiamiApiException('Sessão expirada. Inicie sessão novamente.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final result = await putUploadFile(
        client: _http,
        url: url,
        filePath: path,
        totalBytes: sizeBytes,
        contentType: contentType,
        headers: headers,
        onProgress: onProgress,
        timeout: _transferTimeout(sizeBytes),
      );

      if (result.statusCode == 0) {
        throw connectionError();
      }

      return http.Response(
        result.body,
        result.statusCode,
        headers: const {},
      );
    } on TimeoutException {
      throw KiamiApiException(
        KiamiStrings.apiUnavailableTimeout,
        errorCode: 'connection_failed',
      );
    } on KiamiApiException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection') ||
          msg.contains('Failed to fetch') ||
          msg.contains('NetworkError')) {
        throw connectionError();
      }
      rethrow;
    }
  }

  Future<http.Response> _putUploadBytes({
    required String url,
    required List<int> bytes,
    required String contentType,
    required bool useAuth,
    UploadProgressCallback? onProgress,
  }) async {
    final headers = <String, String>{};
    if (useAuth) {
      final token = await FirebaseIdTokenService.getIdToken();
      if (token == null) {
        throw KiamiApiException('Sessão expirada. Inicie sessão novamente.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final result = await putUploadBytes(
        client: _http,
        url: url,
        bytes: bytes,
        contentType: contentType,
        headers: headers,
        onProgress: onProgress,
        timeout: _transferTimeout(bytes.length),
      );

      if (result.statusCode == 0) {
        throw connectionError();
      }

      return http.Response(
        result.body,
        result.statusCode,
        headers: const {},
      );
    } on TimeoutException {
      throw KiamiApiException(
        KiamiStrings.apiUnavailableTimeout,
        errorCode: 'connection_failed',
      );
    } on KiamiApiException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection') ||
          msg.contains('Failed to fetch') ||
          msg.contains('NetworkError')) {
        throw connectionError();
      }
      rethrow;
    }
  }

  KiamiFile _parseUploadPutFile(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return KiamiFile.fromJson(json['file'] as Map<String, dynamic>);
    } catch (_) {
      throw KiamiApiException(
        'Resposta invalida do servidor apos upload.',
        statusCode: response.statusCode,
      );
    }
  }

  Never _throwUploadPutFailure(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body['message'] as String? ??
          'Falha ao enviar ficheiro (${response.statusCode}).';
      throw KiamiApiException(
        message,
        statusCode: response.statusCode,
        errorCode: body['error'] as String?,
      );
    } catch (e) {
      if (e is KiamiApiException) throw e;
      throw KiamiApiException(
        kIsWeb
            ? 'Falha ao enviar ficheiro (${response.statusCode}). Verifique a ligacao e tente novamente.'
            : 'Falha ao enviar ficheiro (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
  }

  Future<KiamiFile> _uploadThumbnail({
    required String fileId,
    required ThumbnailUploadInfo thumb,
    required List<int> bytes,
  }) async {
    final viaWorker = kIsWeb || thumb.localDevUpload;
    final putUrl = viaWorker
        ? _uri('/files/upload/thumb/direct/$fileId').toString()
        : thumb.uploadUrl;

    final response = await _putUploadBytes(
      url: putUrl,
      bytes: bytes,
      contentType: 'image/jpeg',
      useAuth: viaWorker,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwUploadPutFailure(response);
    }

    if (viaWorker) {
      return _parseUploadPutFile(response);
    }

    return completeThumbnailUpload(fileId);
  }

  Future<KiamiFile> completeThumbnailUpload(String fileId) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/files/upload/thumb/complete'),
        headers: headers,
        body: jsonEncode({'fileId': fileId}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiFile.fromJson(json['file'] as Map<String, dynamic>);
  }

  Future<FileThumbnailUrl?> getFileThumbnailUrl(String fileId) async {
    final headers = await _authHeaders();
    _applyWebWorkerHeaders(headers, media: true);
    final response = await _run(
      () => _http.get(_uri('/files/$fileId/thumbnail'), headers: headers),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) _throwFromResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final localDev = json['localDevThumbnail'] as bool? ?? false;
    final mediaToken = json['mediaAccessToken'] as bool? ?? false;
    final url = json['thumbnailUrl'] as String;
    final expiresRaw = json['expiresAt'] as String?;
    DateTime? expiresAt;
    if (expiresRaw != null) {
      expiresAt = DateTime.tryParse(expiresRaw);
    }

    return FileThumbnailUrl(
      url: url,
      localDev: localDev,
      headers: localDev && !mediaToken ? await _authHeadersForBinary() : const {},
      expiresAt: expiresAt,
      mediaAccessToken: mediaToken,
    );
  }

  /// GET autenticado (miniaturas / media via proxy Worker na Web).
  Future<Uint8List> fetchAuthenticatedBytes(
    String url, {
    Map<String, String>? headers,
    int? sizeBytes,
  }) async {
    final resolvedHeaders = <String, String>{
      if (headers != null) ...headers,
    };
    if (!resolvedHeaders.containsKey('Authorization')) {
      resolvedHeaders.addAll(await _authHeaders());
    }
    if (!resolvedHeaders.containsKey('Accept')) {
      resolvedHeaders['Accept'] = '*/*';
    } else if (resolvedHeaders['Accept'] == 'application/json') {
      resolvedHeaders['Accept'] = '*/*';
    }
    final response = await _run(
      () => _http.get(Uri.parse(url), headers: resolvedHeaders),
      timeout: sizeBytes != null && sizeBytes > 0
          ? _transferTimeout(sizeBytes)
          : const Duration(seconds: 60),
    );
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw KiamiApiException(
        'Falha ao carregar recurso (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  Future<KiamiFile> completeUpload(String fileId) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/files/upload/complete'),
        headers: headers,
        body: jsonEncode({'fileId': fileId}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiFile.fromJson(json['file'] as Map<String, dynamic>);
  }

  /// URL (+ headers) para reprodução directa de média — evita descarregar
  /// o ficheiro inteiro para memória.
  Future<({String url, Map<String, String> headers})> getFileDownloadInfo(
    String fileId,
  ) async {
    final authHeaders = await _authHeaders();
    _applyWebWorkerHeaders(authHeaders, media: true);
    final metaResponse = await _run(
      () => _http.get(_uri('/files/$fileId/download'), headers: authHeaders),
    );
    if (metaResponse.statusCode != 200) _throwFromResponse(metaResponse);

    final meta = jsonDecode(metaResponse.body) as Map<String, dynamic>;
    final downloadUrl = meta['downloadUrl'] as String;
    final localDev = meta['localDevDownload'] as bool? ?? false;
    final mediaToken = meta['mediaAccessToken'] as bool? ?? false;
    return (
      url: downloadUrl,
      headers: localDev && !mediaToken
          ? await _authHeadersForBinary()
          : <String, String>{},
    );
  }

  Future<List<int>> downloadFileBytes(String fileId) async {
    final authHeaders = await _authHeaders();
    _applyWebWorkerHeaders(authHeaders, media: true);
    final metaResponse = await _run(
      () => _http.get(_uri('/files/$fileId/download'), headers: authHeaders),
    );
    if (metaResponse.statusCode != 200) _throwFromResponse(metaResponse);

    final meta = jsonDecode(metaResponse.body) as Map<String, dynamic>;
    final downloadUrl = meta['downloadUrl'] as String;
    final localDev = meta['localDevDownload'] as bool? ?? false;
    final mediaToken = meta['mediaAccessToken'] as bool? ?? false;

    final headers = localDev && !mediaToken
        ? await _authHeadersForBinary()
        : <String, String>{};
    final sizeBytes =
        ((meta['file'] as Map<String, dynamic>?)?['sizeBytes'] as num?)
                ?.toInt() ??
            (meta['sizeBytes'] as num?)?.toInt() ??
            0;
    final fileResponse = await _run(
      () => _http.get(Uri.parse(downloadUrl), headers: headers),
      timeout: sizeBytes > 0
          ? _transferTimeout(sizeBytes)
          : const Duration(minutes: 15),
    );

    if (fileResponse.statusCode != 200) {
      throw KiamiApiException(
        'Falha ao descarregar (${fileResponse.statusCode}).',
        statusCode: fileResponse.statusCode,
      );
    }
    return fileResponse.bodyBytes;
  }

  Future<KiamiFile> renameFile({
    required String fileId,
    required String newName,
  }) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.patch(
        _uri('/files/$fileId'),
        headers: headers,
        body: jsonEncode({'name': newName}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiFile.fromJson(json['file'] as Map<String, dynamic>);
  }

  Future<void> deleteFile(String fileId) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.delete(_uri('/files/$fileId'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
  }

  Future<List<KiamiFile>> listTrashFiles() async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/files/trash'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['files'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KiamiFile> restoreFile(String fileId) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/files/$fileId/restore'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiFile.fromJson(json['file'] as Map<String, dynamic>);
  }

  Future<void> permanentDeleteFile(String fileId) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.delete(_uri('/files/$fileId/permanent'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
  }

  Future<List<KiamiPlan>> listPlans() async {
    final response = await _run(
      () => _http.get(_uri('/plans'), headers: {'Accept': 'application/json'}),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['plans'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KiamiBillingStatus> getBillingStatus() async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/billing/status'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return KiamiBillingStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<KiamiCheckoutResult> createCheckout(String planCode) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/billing/checkout'),
        headers: headers,
        body: jsonEncode({'planCode': planCode}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return KiamiCheckoutResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<KiamiCheckout> submitCheckoutProof({
    required String checkoutId,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = mimeType;
    final response = await _run(
      () => _http.put(
        _uri('/billing/checkout/$checkoutId/proof'),
        headers: headers,
        body: bytes,
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiCheckout.fromJson(json['checkout'] as Map<String, dynamic>);
  }

  Future<KiamiPlan> simulateCheckoutPayment(String checkoutId) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/billing/checkout/$checkoutId/simulate-pay'),
        headers: headers,
        body: '{}',
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiPlan.fromJson(json['plan'] as Map<String, dynamic>);
  }

  Future<bool> checkIsAdmin() async {
    try {
      final headers = await _authHeaders();
      final response = await _run(
        () => _http.get(_uri('/admin/me'), headers: headers),
      );
      return response.statusCode == 200;
    } on KiamiApiException catch (e) {
      if (e.statusCode == 403) return false;
      rethrow;
    }
  }

  Future<KiamiCloudflareUsage> getAdminCloudflareUsage() async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/admin/cloudflare-usage'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiCloudflareUsage.fromJson(
      json['usage'] as Map<String, dynamic>,
    );
  }

  Future<KiamiAdminDashboard> getAdminDashboard() async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/admin/stats'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return KiamiAdminDashboard.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<KiamiAdminStats> getAdminStats() async {
    final dashboard = await getAdminDashboard();
    return dashboard.stats;
  }

  Future<KiamiAdminUserList> listAdminUsers({
    String? search,
    int limit = 25,
    int offset = 0,
  }) async {
    final headers = await _authHeaders();
    final q = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (search != null && search.isNotEmpty) 'q': search,
    };
    final uri = _uri('/admin/users').replace(queryParameters: q);
    final response = await _run(() => _http.get(uri, headers: headers));
    if (response.statusCode != 200) _throwFromResponse(response);
    return KiamiAdminUserList.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<KiamiAdminFeedback>> listAdminUserFeedback(String uid) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/admin/users/$uid/feedback'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['feedback'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiAdminFeedback.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KiamiAdminFeedback> markAdminFeedbackReviewed(int feedbackId) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/admin/feedback/$feedbackId/review'),
        headers: headers,
        body: '{}',
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiAdminFeedback.fromJson(
      json['feedback'] as Map<String, dynamic>,
    );
  }

  Future<KiamiAdminUser> getAdminUser(String uid) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/admin/users/$uid'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiAdminUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<List<KiamiAdminCheckout>> listAdminCheckouts({
    int limit = 50,
    String? status,
  }) async {
    final headers = await _authHeaders();
    final q = <String, String>{
      'limit': '$limit',
      if (status != null) 'status': status,
    };
    final uri = _uri('/admin/checkouts').replace(queryParameters: q);
    final response = await _run(() => _http.get(uri, headers: headers));
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['checkouts'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiAdminCheckout.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KiamiAdminCheckout> rejectAdminCheckout(
    String checkoutId,
    String reason,
  ) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/admin/checkouts/$checkoutId/reject'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiAdminCheckout.fromJson(
      json['checkout'] as Map<String, dynamic>,
    );
  }

  Future<({Uint8List bytes, String mimeType})> fetchAdminCheckoutProof(
    String checkoutId,
  ) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/admin/checkouts/$checkoutId/proof'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final mimeType =
        response.headers['content-type']?.split(';').first.trim() ??
            'application/octet-stream';
    return (bytes: response.bodyBytes, mimeType: mimeType);
  }

  Future<KiamiAdminCheckout> confirmAdminCheckout(String checkoutId) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/admin/checkouts/$checkoutId/confirm'),
        headers: headers,
        body: '{}',
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiAdminCheckout.fromJson(
      json['checkout'] as Map<String, dynamic>,
    );
  }

  Future<KiamiAdminUser> updateAdminUser({
    required String uid,
    String? planCode,
    int? quotaBytesOverride,
    bool clearQuotaOverride = false,
    int? maxFileSizeBytesOverride,
    bool clearTransferOverride = false,
    bool? canSwitchApiEndpoint,
  }) async {
    final headers = await _authHeaders(jsonBody: true);
    final body = <String, dynamic>{
      if (planCode != null) 'planCode': planCode,
      if (clearQuotaOverride) 'clearQuotaOverride': true,
      if (quotaBytesOverride != null) 'quotaBytesOverride': quotaBytesOverride,
      if (clearTransferOverride) 'clearTransferOverride': true,
      if (maxFileSizeBytesOverride != null)
        'maxFileSizeBytesOverride': maxFileSizeBytesOverride,
      if (canSwitchApiEndpoint != null)
        'canSwitchApiEndpoint': canSwitchApiEndpoint,
    };
    final response = await _run(
      () => _http.patch(
        _uri('/admin/users/$uid'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KiamiAdminUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchAdminFeedback({int limit = 20}) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/admin/feedback?limit=$limit'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['feedback'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<KiamiSecurityEvent>> listAdminSecurityEvents({
    int limit = 20,
  }) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(
        _uri('/admin/security-events?limit=$limit'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['events'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiSecurityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KiamiAccountActivity> getAccountActivity({int limit = 40}) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(_uri('/me/activity?limit=$limit'), headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['events'] as List<dynamic>? ?? [];
    return KiamiAccountActivity(
      events: list
          .map((e) => KiamiAccountEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> markAllAccountActivityRead() async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.post(
        _uri('/me/activity/read-all'),
        headers: headers,
        body: '{}',
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return 0;
  }

  Future<List<KiamiAccountEvent>> listAdminAccountActivity({
    String? uid,
    int limit = 40,
  }) async {
    final headers = await _authHeaders();
    final path = uid != null
        ? '/admin/users/$uid/activity?limit=$limit'
        : '/admin/activity?limit=$limit';
    final response = await _run(() => _http.get(_uri(path), headers: headers));
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['events'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiAccountEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<KiamiCheckout>> listAdminUserCheckouts(
    String uid, {
    int limit = 30,
  }) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(
        _uri('/admin/users/$uid/checkouts?limit=$limit'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['checkouts'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiCheckout.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<KiamiAuditAction>> listAuditActions({int limit = 30}) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(
        _uri('/me/audit?limit=$limit'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['actions'] as List<dynamic>? ?? [];
    return list
        .map((e) => KiamiAuditAction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KiamiAdminSubscriptionList> listAdminSubscriptions({
    String? status,
    int limit = 25,
    int offset = 0,
  }) async {
    final headers = await _authHeaders();
    final q = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (status != null && status.isNotEmpty) q['status'] = status;
    final uri = _uri('/admin/subscriptions').replace(queryParameters: q);
    final response = await _run(
      () => _http.get(uri, headers: headers),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
    return KiamiAdminSubscriptionList.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> reactivateAdminSubscription(
    String uid, {
    int? endsAtDays,
  }) async {
    final headers = await _authHeaders(jsonBody: true);
    final body = <String, dynamic>{};
    if (endsAtDays != null) body['endsAtDays'] = endsAtDays;
    final response = await _run(
      () => _http.post(
        _uri('/admin/subscriptions/$uid/reactivate'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
  }

  Future<KiamiAdminSubscription?> getAdminUserSubscription(String uid) async {
    final headers = await _authHeaders();
    final response = await _run(
      () => _http.get(
        _uri('/admin/users/$uid/subscription'),
        headers: headers,
      ),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) _throwFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final sub = json['subscription'];
    if (sub == null) return null;
    return KiamiAdminSubscription.fromJson(sub as Map<String, dynamic>);
  }

  Future<void> adjustAdminSubscriptionEndsAt({
    required String uid,
    required String endsAt,
  }) async {
    final headers = await _authHeaders(jsonBody: true);
    final response = await _run(
      () => _http.patch(
        _uri('/admin/subscriptions/$uid'),
        headers: headers,
        body: jsonEncode({'endsAt': endsAt}),
      ),
    );
    if (response.statusCode != 200) _throwFromResponse(response);
  }
}
