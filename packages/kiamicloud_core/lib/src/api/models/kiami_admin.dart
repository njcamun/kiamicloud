import '../../utils/kiami_quota_normalize.dart';

class KiamiAdminDashboard {
  const KiamiAdminDashboard({
    required this.stats,
    this.cloudflareUsage,
  });

  final KiamiAdminStats stats;
  final KiamiCloudflareUsage? cloudflareUsage;

  factory KiamiAdminDashboard.fromJson(Map<String, dynamic> json) {
    return KiamiAdminDashboard(
      stats: KiamiAdminStats.fromJson(json['stats'] as Map<String, dynamic>),
      cloudflareUsage: json['cloudflareUsage'] != null
          ? KiamiCloudflareUsage.fromJson(
              json['cloudflareUsage'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class KiamiAdminStats {
  const KiamiAdminStats({
    required this.usersCount,
    required this.activeFilesCount,
    required this.totalStorageUsedBytes,
    required this.pendingCheckoutsCount,
    required this.securityEventsLast24h,
    this.pendingFeedbackCount = 0,
  });

  final int usersCount;
  final int activeFilesCount;
  final int totalStorageUsedBytes;
  final int pendingCheckoutsCount;
  final int securityEventsLast24h;
  final int pendingFeedbackCount;

  factory KiamiAdminStats.fromJson(Map<String, dynamic> json) {
    return KiamiAdminStats(
      usersCount: (json['usersCount'] as num).toInt(),
      activeFilesCount: (json['activeFilesCount'] as num).toInt(),
      totalStorageUsedBytes: (json['totalStorageUsedBytes'] as num).toInt(),
      pendingCheckoutsCount: (json['pendingCheckoutsCount'] as num).toInt(),
      securityEventsLast24h: (json['securityEventsLast24h'] as num).toInt(),
      pendingFeedbackCount: (json['pendingFeedbackCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class KiamiAdminUser {
  const KiamiAdminUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.planCode,
    required this.planName,
    required this.quotaBytes,
    required this.planQuotaBytes,
    this.quotaOverrideBytes,
    required this.planMaxFileSizeBytes,
    required this.maxFileSizeBytes,
    this.transferOverrideBytes,
    required this.storageUsedBytes,
    required this.filesCount,
    this.pendingFeedbackCount = 0,
    this.pendingCheckoutsCount = 0,
    this.canSwitchApiEndpoint = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String planCode;
  final String planName;
  final int quotaBytes;
  final int planQuotaBytes;
  final int? quotaOverrideBytes;
  final int planMaxFileSizeBytes;
  final int maxFileSizeBytes;
  final int? transferOverrideBytes;
  final int storageUsedBytes;
  final int filesCount;
  final int pendingFeedbackCount;
  final int pendingCheckoutsCount;
  final bool canSwitchApiEndpoint;
  final String createdAt;
  final String updatedAt;

  bool get hasPendingFeedback => pendingFeedbackCount > 0;

  bool get hasPendingCheckouts => pendingCheckoutsCount > 0;

  int get pendingNotificationsCount =>
      pendingFeedbackCount + pendingCheckoutsCount;

  bool get hasPendingNotifications => pendingNotificationsCount > 0;

  bool get hasTransferOverride => transferOverrideBytes != null;

  bool get hasQuotaOverride => quotaOverrideBytes != null;

  double get storageUsageFraction =>
      quotaBytes > 0 ? (storageUsedBytes / quotaBytes).clamp(0.0, 1.0) : 0;

  factory KiamiAdminUser.fromJson(Map<String, dynamic> json) {
    final planMax = (json['planMaxFileSizeBytes'] as num?)?.toInt() ??
        (json['maxFileSizeBytes'] as num).toInt();
    final quotaRaw = (json['quotaBytes'] as num).toInt();
    final planQuotaRaw = (json['planQuotaBytes'] as num?)?.toInt() ?? quotaRaw;
    return KiamiAdminUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      planCode: json['planCode'] as String,
      planName: json['planName'] as String,
      quotaBytes: parseEffectiveQuotaBytes(quotaRaw),
      planQuotaBytes: parseEffectiveQuotaBytes(planQuotaRaw),
      quotaOverrideBytes: (json['quotaOverrideBytes'] as num?)?.toInt(),
      planMaxFileSizeBytes: planMax,
      maxFileSizeBytes: (json['maxFileSizeBytes'] as num).toInt(),
      transferOverrideBytes: (json['transferOverrideBytes'] as num?)?.toInt(),
      storageUsedBytes: (json['storageUsedBytes'] as num).toInt(),
      filesCount: (json['filesCount'] as num).toInt(),
      pendingFeedbackCount: (json['pendingFeedbackCount'] as num?)?.toInt() ?? 0,
      pendingCheckoutsCount:
          (json['pendingCheckoutsCount'] as num?)?.toInt() ?? 0,
      canSwitchApiEndpoint: json['canSwitchApiEndpoint'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class KiamiAdminUserList {
  const KiamiAdminUserList({
    required this.users,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<KiamiAdminUser> users;
  final int total;
  final int limit;
  final int offset;

  factory KiamiAdminUserList.fromJson(Map<String, dynamic> json) {
    final list = json['users'] as List<dynamic>? ?? [];
    return KiamiAdminUserList(
      users: list
          .map((e) => KiamiAdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );
  }
}

class KiamiAdminFeedback {
  const KiamiAdminFeedback({
    required this.id,
    this.firebaseUid,
    this.email,
    required this.message,
    this.appVersion,
    this.platform,
    required this.createdAt,
    this.reviewedAt,
  });

  final int id;
  final String? firebaseUid;
  final String? email;
  final String message;
  final String? appVersion;
  final String? platform;
  final String createdAt;
  final String? reviewedAt;

  bool get isPending => reviewedAt == null;

  factory KiamiAdminFeedback.fromJson(Map<String, dynamic> json) {
    return KiamiAdminFeedback(
      id: (json['id'] as num).toInt(),
      firebaseUid: json['firebaseUid'] as String?,
      email: json['email'] as String?,
      message: json['message'] as String,
      appVersion: json['appVersion'] as String?,
      platform: json['platform'] as String?,
      createdAt: json['createdAt'] as String,
      reviewedAt: json['reviewedAt'] as String?,
    );
  }
}

class KiamiCloudflareUsage {
  const KiamiCloudflareUsage({
    required this.periodDays,
    required this.workers,
    required this.d1,
    required this.r2,
    required this.costEstimateUsd,
    required this.disclaimer,
  });

  final int periodDays;
  final KiamiCfWorkersUsage workers;
  final KiamiCfD1Usage d1;
  final KiamiCfR2Usage r2;
  final KiamiCfCostEstimate costEstimateUsd;
  final String disclaimer;

  factory KiamiCloudflareUsage.fromJson(Map<String, dynamic> json) {
    return KiamiCloudflareUsage(
      periodDays: (json['periodDays'] as num).toInt(),
      workers: KiamiCfWorkersUsage.fromJson(
        json['workers'] as Map<String, dynamic>,
      ),
      d1: KiamiCfD1Usage.fromJson(json['d1'] as Map<String, dynamic>),
      r2: KiamiCfR2Usage.fromJson(json['r2'] as Map<String, dynamic>),
      costEstimateUsd: KiamiCfCostEstimate.fromJson(
        json['costEstimateUsd'] as Map<String, dynamic>,
      ),
      disclaimer: json['disclaimer'] as String,
    );
  }
}

class KiamiCfWorkersUsage {
  const KiamiCfWorkersUsage({
    required this.requestsEstimateMonth,
    required this.cpuMsEstimateMonth,
    required this.summary,
  });

  final int requestsEstimateMonth;
  final int cpuMsEstimateMonth;
  final String summary;

  factory KiamiCfWorkersUsage.fromJson(Map<String, dynamic> json) {
    return KiamiCfWorkersUsage(
      requestsEstimateMonth: (json['requestsEstimateMonth'] as num).toInt(),
      cpuMsEstimateMonth: (json['cpuMsEstimateMonth'] as num).toInt(),
      summary: json['summary'] as String,
    );
  }
}

class KiamiCfD1Usage {
  const KiamiCfD1Usage({
    required this.storageBytes,
    required this.rowsReadEstimateMonth,
    required this.rowsWrittenEstimateMonth,
    required this.summary,
  });

  final int storageBytes;
  final int rowsReadEstimateMonth;
  final int rowsWrittenEstimateMonth;
  final String summary;

  factory KiamiCfD1Usage.fromJson(Map<String, dynamic> json) {
    return KiamiCfD1Usage(
      storageBytes: (json['storageBytes'] as num).toInt(),
      rowsReadEstimateMonth: (json['rowsReadEstimateMonth'] as num).toInt(),
      rowsWrittenEstimateMonth: (json['rowsWrittenEstimateMonth'] as num).toInt(),
      summary: json['summary'] as String,
    );
  }
}

class KiamiCfR2Usage {
  const KiamiCfR2Usage({
    required this.storageBytes,
    required this.classAOpsEstimateMonth,
    required this.classBOpsEstimateMonth,
    required this.summary,
  });

  final int storageBytes;
  final int classAOpsEstimateMonth;
  final int classBOpsEstimateMonth;
  final String summary;

  factory KiamiCfR2Usage.fromJson(Map<String, dynamic> json) {
    return KiamiCfR2Usage(
      storageBytes: (json['storageBytes'] as num).toInt(),
      classAOpsEstimateMonth: (json['classAOpsEstimateMonth'] as num).toInt(),
      classBOpsEstimateMonth: (json['classBOpsEstimateMonth'] as num).toInt(),
      summary: json['summary'] as String,
    );
  }
}

class KiamiCfCostEstimate {
  const KiamiCfCostEstimate({
    required this.workers,
    required this.d1,
    required this.r2,
    required this.basePlan,
    required this.total,
  });

  final double workers;
  final double d1;
  final double r2;
  final double basePlan;
  final double total;

  factory KiamiCfCostEstimate.fromJson(Map<String, dynamic> json) {
    return KiamiCfCostEstimate(
      workers: (json['workers'] as num).toDouble(),
      d1: (json['d1'] as num).toDouble(),
      r2: (json['r2'] as num).toDouble(),
      basePlan: (json['basePlan'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class KiamiAdminCheckout {
  const KiamiAdminCheckout({
    required this.id,
    required this.firebaseUid,
    this.userEmail,
    required this.planCode,
    required this.amountKz,
    required this.reference,
    required this.status,
    this.hasProof = false,
    this.proofSubmittedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  final String id;
  final String firebaseUid;
  final String? userEmail;
  final String planCode;
  final int amountKz;
  final String reference;
  final String status;
  final bool hasProof;
  final String? proofSubmittedAt;
  final String? rejectionReason;
  final String createdAt;

  bool get isAwaitingReview => status == 'awaiting_review';

  factory KiamiAdminCheckout.fromJson(Map<String, dynamic> json) {
    return KiamiAdminCheckout(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String? ?? '',
      userEmail: json['userEmail'] as String?,
      planCode: json['planCode'] as String,
      amountKz: (json['amountKz'] as num).toInt(),
      reference: json['reference'] as String,
      status: json['status'] as String,
      hasProof: json['hasProof'] as bool? ?? false,
      proofSubmittedAt: json['proofSubmittedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class KiamiSecurityEvent {
  const KiamiSecurityEvent({
    required this.id,
    required this.eventType,
    this.firebaseUid,
    this.path,
    required this.createdAt,
  });

  final int id;
  final String eventType;
  final String? firebaseUid;
  final String? path;
  final String createdAt;

  factory KiamiSecurityEvent.fromJson(Map<String, dynamic> json) {
    return KiamiSecurityEvent(
      id: (json['id'] as num).toInt(),
      eventType: json['eventType'] as String,
      firebaseUid: json['firebaseUid'] as String?,
      path: json['path'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class KiamiAdminSubscription {
  const KiamiAdminSubscription({
    required this.id,
    required this.firebaseUid,
    required this.planCode,
    required this.status,
    required this.effectiveStatus,
    required this.startedAt,
    this.endsAt,
    this.gracePeriodEndsAt,
    this.deletionScheduledAt,
    this.autoRenew = false,
    this.email,
    this.displayName,
    this.storageUsedBytes = 0,
  });

  final String id;
  final String firebaseUid;
  final String planCode;
  final String status;
  final String effectiveStatus;
  final String startedAt;
  final String? endsAt;
  final String? gracePeriodEndsAt;
  final String? deletionScheduledAt;
  final bool autoRenew;
  final String? email;
  final String? displayName;
  final int storageUsedBytes;

  factory KiamiAdminSubscription.fromJson(Map<String, dynamic> json) {
    return KiamiAdminSubscription(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      planCode: json['planCode'] as String,
      status: json['status'] as String,
      effectiveStatus:
          json['effectiveStatus'] as String? ?? json['status'] as String,
      startedAt: json['startedAt'] as String,
      endsAt: json['endsAt'] as String?,
      gracePeriodEndsAt: json['gracePeriodEndsAt'] as String?,
      deletionScheduledAt: json['deletionScheduledAt'] as String?,
      autoRenew: json['autoRenew'] as bool? ?? false,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      storageUsedBytes: (json['storageUsedBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class KiamiAdminSubscriptionList {
  const KiamiAdminSubscriptionList({
    required this.items,
    required this.total,
  });

  final List<KiamiAdminSubscription> items;
  final int total;

  factory KiamiAdminSubscriptionList.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return KiamiAdminSubscriptionList(
      items: list
          .map((e) => KiamiAdminSubscription.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? list.length,
    );
  }
}
