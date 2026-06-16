class ThumbnailUploadInfo {
  const ThumbnailUploadInfo({
    required this.uploadUrl,
    required this.method,
    required this.r2ObjectKey,
    required this.localDevUpload,
    this.expiresAt,
    this.expiresInSeconds,
  });

  final String uploadUrl;
  final String method;
  final String r2ObjectKey;
  final bool localDevUpload;
  final String? expiresAt;
  final int? expiresInSeconds;

  factory ThumbnailUploadInfo.fromJson(Map<String, dynamic> json) {
    return ThumbnailUploadInfo(
      uploadUrl: json['uploadUrl'] as String,
      method: json['method'] as String? ?? 'PUT',
      r2ObjectKey: json['r2ObjectKey'] as String,
      localDevUpload: json['localDevUpload'] as bool? ?? false,
      expiresAt: json['expiresAt'] as String?,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt(),
    );
  }
}
