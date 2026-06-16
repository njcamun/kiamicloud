class KiamiFileShare {
  const KiamiFileShare({
    required this.id,
    required this.token,
    required this.fileId,
    required this.fileName,
    required this.expiresAt,
    required this.accessCount,
    required this.createdAt,
    required this.active,
    this.revokedAt,
  });

  final String id;
  final String token;
  final String fileId;
  final String fileName;
  final String expiresAt;
  final String? revokedAt;
  final int accessCount;
  final String createdAt;
  final bool active;

  factory KiamiFileShare.fromJson(Map<String, dynamic> json) {
    return KiamiFileShare(
      id: json['id'] as String,
      token: json['token'] as String,
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      expiresAt: json['expiresAt'] as String,
      revokedAt: json['revokedAt'] as String?,
      accessCount: (json['accessCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String,
      active: json['active'] as bool? ?? false,
    );
  }
}

class CreateFileShareResult {
  const CreateFileShareResult({
    required this.share,
    required this.shareUrl,
  });

  final KiamiFileShare share;
  final String shareUrl;

  factory CreateFileShareResult.fromJson(Map<String, dynamic> json) {
    return CreateFileShareResult(
      share: KiamiFileShare.fromJson(json['share'] as Map<String, dynamic>),
      shareUrl: json['shareUrl'] as String,
    );
  }
}
