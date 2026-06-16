class KiamiApiException implements Exception {
  KiamiApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.maxFileSizeBytes,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  /// Limite por ficheiro do plano (resposta API `file_too_large`).
  final int? maxFileSizeBytes;

  @override
  String toString() => message;
}
