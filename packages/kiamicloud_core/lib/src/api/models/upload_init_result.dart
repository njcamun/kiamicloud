import 'kiami_file.dart';
import 'thumbnail_upload_info.dart';

class UploadInitResult {
  const UploadInitResult({
    required this.fileId,
    required this.file,
    required this.uploadUrl,
    required this.method,
    required this.localDevUpload,
    this.thumbnail,
  });

  final String fileId;
  final KiamiFile file;
  final String uploadUrl;
  final String method;
  final bool localDevUpload;
  final ThumbnailUploadInfo? thumbnail;

  factory UploadInitResult.fromJson(Map<String, dynamic> json) {
    final thumbJson = json['thumbnail'];
    return UploadInitResult(
      fileId: json['fileId'] as String,
      file: KiamiFile.fromJson(json['file'] as Map<String, dynamic>),
      uploadUrl: json['uploadUrl'] as String,
      method: json['method'] as String? ?? 'PUT',
      localDevUpload: json['localDevUpload'] as bool? ?? false,
      thumbnail: thumbJson is Map<String, dynamic>
          ? ThumbnailUploadInfo.fromJson(thumbJson)
          : null,
    );
  }
}
