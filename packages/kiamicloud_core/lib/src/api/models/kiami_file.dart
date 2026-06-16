class KiamiFile {
  const KiamiFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.hasThumbnail = false,
  });

  final String id;
  final String name;
  final String? mimeType;
  final int sizeBytes;
  final String status;
  final String? folderId;
  final String createdAt;
  final String updatedAt;
  final bool hasThumbnail;

  factory KiamiFile.fromJson(Map<String, dynamic> json) {
    return KiamiFile(
      id: json['id'] as String,
      name: json['name'] as String,
      mimeType: json['mimeType'] as String?,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      status: json['status'] as String,
      folderId: json['folderId'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      hasThumbnail: json['hasThumbnail'] as bool? ?? false,
    );
  }
}
