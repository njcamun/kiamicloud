import 'kiami_checkout.dart';
import 'kiami_payment_instructions.dart';
import 'kiami_plan.dart';
import 'kiami_quota.dart';
import '../../utils/kiami_quota_normalize.dart';

class KiamiSubscription {
  const KiamiSubscription({
    required this.id,
    required this.planCode,
    required this.status,
    required this.startedAt,
    this.endsAt,
  });

  final String id;
  final String planCode;
  final String status;
  final String startedAt;
  final String? endsAt;

  factory KiamiSubscription.fromJson(Map<String, dynamic> json) {
    return KiamiSubscription(
      id: json['id'] as String,
      planCode: json['planCode'] as String,
      status: json['status'] as String,
      startedAt: json['startedAt'] as String,
      endsAt: json['endsAt'] as String?,
    );
  }
}

class KiamiBillingStatus {
  const KiamiBillingStatus({
    required this.plan,
    required this.storageUsedBytes,
    required this.storageAvailableBytes,
    required this.quota,
    this.subscription,
    required this.pendingCheckouts,
    required this.recentRejectedCheckouts,
    required this.paymentsEnabled,
    required this.provider,
    required this.paymentInstructions,
  });

  final KiamiPlan plan;
  final int storageUsedBytes;
  final int storageAvailableBytes;
  final KiamiQuotaInfo quota;
  final KiamiSubscription? subscription;
  final List<KiamiCheckout> pendingCheckouts;
  final List<KiamiCheckout> recentRejectedCheckouts;
  final bool paymentsEnabled;
  final String provider;
  final KiamiPaymentInstructions paymentInstructions;

  KiamiCheckout? get activeCheckout {
    for (final c in pendingCheckouts) {
      if (c.isActive) return c;
    }
    return null;
  }

  factory KiamiBillingStatus.fromJson(Map<String, dynamic> json) {
    final pending = json['pendingCheckouts'] as List<dynamic>? ?? [];
    final rejected = json['recentRejectedCheckouts'] as List<dynamic>? ?? [];
    final subJson = json['subscription'];
    final instructionsJson = json['paymentInstructions'] as Map<String, dynamic>?;
    final planRaw = KiamiPlan.fromJson(json['plan'] as Map<String, dynamic>);
    final plan = KiamiPlan(
      code: planRaw.code,
      name: planRaw.name,
      quotaBytes: parseEffectiveQuotaBytes(planRaw.quotaBytes),
      priceKzMonth: planRaw.priceKzMonth,
      maxFileSizeBytes: parseEffectiveMaxFileBytes(planRaw.maxFileSizeBytes),
    );
    return KiamiBillingStatus(
      plan: plan,
      storageUsedBytes: (json['storageUsedBytes'] as num).toInt(),
      storageAvailableBytes: (json['storageAvailableBytes'] as num).toInt(),
      quota: KiamiQuotaInfo.fromJson(json['quota'] as Map<String, dynamic>),
      subscription: subJson != null
          ? KiamiSubscription.fromJson(subJson as Map<String, dynamic>)
          : null,
      pendingCheckouts: pending
          .map((e) => KiamiCheckout.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentRejectedCheckouts: rejected
          .map((e) => KiamiCheckout.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentsEnabled: json['paymentsEnabled'] as bool? ?? true,
      provider: json['provider'] as String? ?? 'manual',
      paymentInstructions: instructionsJson != null
          ? KiamiPaymentInstructions.fromJson(instructionsJson)
          : const KiamiPaymentInstructions(
              holderName: 'KiamiCloud',
              iban: '',
              mbWay: '',
              note: '',
              reviewSlaHours: 6,
            ),
    );
  }
}

class KiamiCheckoutResult {
  const KiamiCheckoutResult({
    required this.planName,
    this.checkout,
    this.message = '',
    this.immediate = false,
    this.plan,
    this.paymentInstructions,
  });

  final bool immediate;
  final KiamiCheckout? checkout;
  final String planName;
  final String message;
  final KiamiPlan? plan;
  final KiamiPaymentInstructions? paymentInstructions;

  factory KiamiCheckoutResult.fromJson(Map<String, dynamic> json) {
    if (json['immediate'] == true) {
      return KiamiCheckoutResult(
        immediate: true,
        planName: json['planName'] as String,
        plan: KiamiPlan.fromJson(json['plan'] as Map<String, dynamic>),
        message: json['message'] as String? ?? '',
      );
    }
    final pi = json['paymentInstructions'] as Map<String, dynamic>?;
    return KiamiCheckoutResult(
      checkout: KiamiCheckout.fromJson(
        json['checkout'] as Map<String, dynamic>,
      ),
      planName: json['planName'] as String,
      message: json['message'] as String? ?? '',
      paymentInstructions: pi != null
          ? KiamiPaymentInstructions.fromJson(pi)
          : null,
    );
  }
}
