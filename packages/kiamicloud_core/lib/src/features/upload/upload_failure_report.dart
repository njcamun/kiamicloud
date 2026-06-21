import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../api/kiami_api_config.dart';
import '../../api/kiami_api_exception.dart';
import '../../constants/kiami_strings.dart';
import '../../config/kiami_environment.dart';
import '../../firebase/kiami_firebase.dart';

/// Excepção de upload com relatório técnico copiável.
class UploadFailureException implements Exception {
  UploadFailureException({
    required this.stage,
    required this.fileName,
    required this.fileSizeBytes,
    required this.cause,
    this.stackTrace,
    this.fileId,
    this.requestUrl,
    this.httpMethod,
    this.statusCode,
    this.errorCode,
    this.responseBody,
  });

  final String stage;
  final String fileName;
  final int fileSizeBytes;
  final Object cause;
  final StackTrace? stackTrace;
  final String? fileId;
  final String? requestUrl;
  final String? httpMethod;
  final int? statusCode;
  final String? errorCode;
  final String? responseBody;

  String get userMessage {
    if (cause is KiamiApiException) {
      return (cause as KiamiApiException).message;
    }
    if (cause is UploadFailureException) {
      return (cause as UploadFailureException).userMessage;
    }
    return KiamiStrings.apiUnavailableBody(KiamiApiConfig.baseUrl);
  }

  String toReport() {
    final buffer = StringBuffer()
      ..writeln('=== KiamiCloud — relatório de upload ===')
      ..writeln('data: ${DateTime.now().toUtc().toIso8601String()}')
      ..writeln('plataforma: ${describePlatform()}')
      ..writeln('ambiente: ${KiamiEnvironment.label}')
      ..writeln('api: ${KiamiApiConfig.baseUrl}')
      ..writeln('ficheiro: $fileName')
      ..writeln('tamanho_bytes: $fileSizeBytes')
      ..writeln('fase: $stage');

    if (fileId != null) buffer.writeln('file_id: $fileId');
    if (httpMethod != null) buffer.writeln('metodo_http: $httpMethod');
    if (requestUrl != null) buffer.writeln('url: $requestUrl');
    if (statusCode != null) buffer.writeln('status_http: $statusCode');
    if (errorCode != null) buffer.writeln('codigo_erro: $errorCode');

    buffer.writeln('mensagem: $userMessage');

    if (KiamiFirebase.isConfigured) {
      final user = FirebaseAuth.instance.currentUser;
      buffer.writeln('utilizador_uid: ${user?.uid ?? '—'}');
      buffer.writeln('email_verificado: ${user?.emailVerified ?? false}');
    }

    if (responseBody != null && responseBody!.trim().isNotEmpty) {
      buffer.writeln('resposta_api: ${_truncate(responseBody!, 800)}');
    }

    buffer
      ..writeln('excepção: ${cause.runtimeType}')
      ..writeln('detalhe: ${_truncate(cause.toString(), 400)}');

    if (stackTrace != null) {
      buffer.writeln('stack:');
      final lines = stackTrace.toString().split('\n').take(12);
      for (final line in lines) {
        buffer.writeln('  $line');
      }
    }

    buffer.writeln('=== fim ===');
    return buffer.toString();
  }

  static String describePlatform() {
    if (kIsWeb) return 'web (${Uri.base.origin})';
    return defaultTargetPlatform.name;
  }

  static String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }
}

String buildUploadFailureReport({
  required String fileName,
  required int fileSizeBytes,
  required Object error,
  StackTrace? stackTrace,
  String stage = 'desconhecida',
}) {
  if (error is UploadFailureException) {
    return error.toReport();
  }

  if (error is KiamiApiException) {
    return UploadFailureException(
      stage: stage,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      cause: error,
      stackTrace: stackTrace,
      statusCode: error.statusCode,
      errorCode: error.errorCode,
    ).toReport();
  }

  return UploadFailureException(
    stage: stage,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    cause: error,
    stackTrace: stackTrace,
  ).toReport();
}
