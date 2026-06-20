/// Resposta HTTP de um PUT de upload (corpo binário).
class UploadPutResponse {
  const UploadPutResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

typedef UploadProgressCallback = void Function(int sentBytes, int totalBytes);
