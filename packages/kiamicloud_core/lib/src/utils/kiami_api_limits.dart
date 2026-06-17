import '../api/kiami_api_config.dart';
import '../api/models/kiami_plan.dart';
import '../api/models/kiami_profile.dart';
import '../api/models/kiami_quota.dart';
import '../api/models/kiami_subscription_access.dart';
import '../constants/kiami_constants.dart';
import 'kiami_quota_normalize.dart';

/// Limites de quota/transferência — aplicados apenas na API Cloudflare.
abstract final class KiamiApiLimits {
  static bool get enforced => KiamiApiConfig.isCloudEndpoint;

  /// Perfil com limites relaxados quando ligado ao servidor local (LAN).
  static KiamiProfile relaxForCurrentApi(KiamiProfile profile) {
    if (enforced) return profile;

    final unlimitedQuota = kLegacyUnlimitedQuotaBytes;
    final plan = KiamiPlan(
      code: profile.plan.code,
      name: profile.plan.name,
      quotaBytes: unlimitedQuota,
      priceKzMonth: profile.plan.priceKzMonth,
      maxFileSizeBytes: 0,
    );

    return KiamiProfile(
      uid: profile.uid,
      email: profile.email,
      emailVerified: profile.emailVerified,
      displayName: profile.displayName,
      plan: plan,
      storageUsedBytes: profile.storageUsedBytes,
      storageAvailableBytes:
          (unlimitedQuota - profile.storageUsedBytes).clamp(0, unlimitedQuota),
      maxFileSizeBytes: 0,
      quota: const KiamiQuotaInfo(
        status: QuotaStatus.ok,
        usagePercent: 0,
        canUpload: true,
        warningAtPercent: 80,
        criticalAtPercent: 95,
      ),
      subscription: profile.subscription,
      access: const KiamiSubscriptionAccess(
        canUpload: true,
        canDownload: true,
        canShare: true,
        status: 'active',
        effectiveStatus: 'active',
      ),
      canSwitchApiEndpoint: profile.canSwitchApiEndpoint,
    );
  }

  static int maxUploadFileBytes({int? profileMax}) {
    if (!enforced) return 1 << 62;
    final limit = profileMax ?? KiamiConstants.maxUploadBytes;
    final normalized = normalizeMaxFileBytes(limit);
    return normalized <= 0 ? (1 << 62) : normalized;
  }

  static int availableStorageBytes({required int? profileAvailable}) {
    if (!enforced) return 1 << 62;
    return profileAvailable ?? KiamiConstants.maxUploadBytes;
  }
}
