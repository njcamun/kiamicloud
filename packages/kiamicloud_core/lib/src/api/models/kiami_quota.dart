enum QuotaStatus { ok, warning, critical, full }

class KiamiQuotaInfo {
  const KiamiQuotaInfo({
    required this.status,
    required this.usagePercent,
    required this.canUpload,
    required this.warningAtPercent,
    required this.criticalAtPercent,
    this.message,
  });

  final QuotaStatus status;
  final double usagePercent;
  final bool canUpload;
  final double warningAtPercent;
  final double criticalAtPercent;
  final String? message;

  factory KiamiQuotaInfo.fromJson(Map<String, dynamic> json) {
    return KiamiQuotaInfo(
      status: _parseStatus(json['status'] as String? ?? 'ok'),
      usagePercent: (json['usagePercent'] as num?)?.toDouble() ?? 0,
      canUpload: json['canUpload'] as bool? ?? true,
      warningAtPercent: (json['warningAtPercent'] as num?)?.toDouble() ?? 80,
      criticalAtPercent: (json['criticalAtPercent'] as num?)?.toDouble() ?? 95,
      message: json['message'] as String?,
    );
  }

  static QuotaStatus _parseStatus(String raw) {
    return switch (raw) {
      'warning' => QuotaStatus.warning,
      'critical' => QuotaStatus.critical,
      'full' => QuotaStatus.full,
      _ => QuotaStatus.ok,
    };
  }

  /// Fallback quando API antiga nao envia `quota`.
  factory KiamiQuotaInfo.fromUsage(int used, int quota) {
    if (quota <= 0) {
      return const KiamiQuotaInfo(
        status: QuotaStatus.ok,
        usagePercent: 0,
        canUpload: true,
        warningAtPercent: 80,
        criticalAtPercent: 95,
      );
    }
    final ratio = used / quota;
    final percent = (ratio * 1000).round() / 10;
    if (ratio >= 1) {
      return KiamiQuotaInfo(
        status: QuotaStatus.full,
        usagePercent: percent,
        canUpload: false,
        warningAtPercent: 80,
        criticalAtPercent: 95,
        message: 'Quota cheia.',
      );
    }
    if (ratio >= 0.95) {
      return KiamiQuotaInfo(
        status: QuotaStatus.critical,
        usagePercent: percent,
        canUpload: used < quota,
        warningAtPercent: 80,
        criticalAtPercent: 95,
        message: 'Quota quase cheia.',
      );
    }
    if (ratio >= 0.8) {
      return KiamiQuotaInfo(
        status: QuotaStatus.warning,
        usagePercent: percent,
        canUpload: true,
        warningAtPercent: 80,
        criticalAtPercent: 95,
        message: 'A usar mais de 80% da quota.',
      );
    }
    return KiamiQuotaInfo(
      status: QuotaStatus.ok,
      usagePercent: percent,
      canUpload: true,
      warningAtPercent: 80,
      criticalAtPercent: 95,
    );
  }
}
