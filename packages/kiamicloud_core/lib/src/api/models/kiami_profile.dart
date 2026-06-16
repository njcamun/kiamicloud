import 'kiami_plan.dart';
import 'kiami_quota.dart';
import '../../utils/kiami_quota_normalize.dart';

class KiamiProfile {
  const KiamiProfile({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.plan,
    required this.storageUsedBytes,
    required this.storageAvailableBytes,
    required this.maxFileSizeBytes,
    required this.quota,
    this.canSwitchApiEndpoint = false,
  });

  final String uid;
  final String? email;
  final bool emailVerified;
  final String? displayName;
  final KiamiPlan plan;
  final int storageUsedBytes;
  final int storageAvailableBytes;
  final int maxFileSizeBytes;
  final KiamiQuotaInfo quota;
  final bool canSwitchApiEndpoint;

  factory KiamiProfile.fromJson(Map<String, dynamic> json) {
    final used = (json['storageUsedBytes'] as num).toInt();
    final planRaw = KiamiPlan.fromJson(json['plan'] as Map<String, dynamic>);
    final quotaRaw =
        (json['quotaBytes'] as num?)?.toInt() ?? planRaw.quotaBytes;
    final maxFileRaw =
        (json['maxFileSizeBytes'] as num?)?.toInt() ?? planRaw.maxFileSizeBytes;
    final quotaBytes = parseEffectiveQuotaBytes(quotaRaw);
    final maxFile = parseEffectiveMaxFileBytes(maxFileRaw);
    final plan = KiamiPlan(
      code: planRaw.code,
      name: planRaw.name,
      quotaBytes: quotaBytes,
      priceKzMonth: planRaw.priceKzMonth,
      maxFileSizeBytes: maxFile,
    );
    final availableRaw = json['storageAvailableBytes'] as num?;
    final available = availableRaw != null
        ? availableRaw.toInt().clamp(0, quotaRaw > 0 ? quotaRaw : quotaBytes)
        : normalizedStorageAvailable(used, quotaBytes);
    final quotaJson = json['quota'];
    final quotaInfo = quotaJson is Map<String, dynamic>
        ? KiamiQuotaInfo.fromJson(quotaJson)
        : KiamiQuotaInfo.fromUsage(used, quotaBytes);
    return KiamiProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      displayName: json['displayName'] as String?,
      plan: plan,
      storageUsedBytes: used,
      storageAvailableBytes: available,
      maxFileSizeBytes: maxFile,
      quota: quotaInfo,
      canSwitchApiEndpoint: json['canSwitchApiEndpoint'] as bool? ?? false,
    );
  }
}
