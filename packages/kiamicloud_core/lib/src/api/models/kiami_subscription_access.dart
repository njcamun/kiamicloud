class KiamiSubscriptionAccess {
  const KiamiSubscriptionAccess({
    required this.canUpload,
    required this.canDownload,
    required this.status,
    required this.effectiveStatus,
    this.blockReason,
    this.storageOverQuota = false,
  });

  final bool canUpload;
  final bool canDownload;
  final String status;
  final String effectiveStatus;
  final String? blockReason;
  final bool storageOverQuota;

  bool get needsAttention =>
      effectiveStatus != 'active' || storageOverQuota;

  factory KiamiSubscriptionAccess.fromJson(Map<String, dynamic> json) {
    return KiamiSubscriptionAccess(
      canUpload: json['canUpload'] as bool? ?? true,
      canDownload: json['canDownload'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      effectiveStatus: json['effectiveStatus'] as String? ?? 'active',
      blockReason: json['blockReason'] as String?,
      storageOverQuota: json['storageOverQuota'] as bool? ?? false,
    );
  }
}
