import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_audit_action.dart';
import '../../../api/models/kiami_billing_status.dart';
import '../../../api/models/kiami_plan.dart';
import '../../files/providers/files_providers.dart';

final billingStatusProvider =
    FutureProvider.autoDispose<KiamiBillingStatus>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.getBillingStatus();
});

final upgradePlansProvider = FutureProvider.autoDispose<List<KiamiPlan>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  final plans = await api.listPlans();
  return plans.where((p) => p.code != 'basico' && p.priceKzMonth > 0).toList();
});

final auditActionsProvider =
    FutureProvider.autoDispose<List<KiamiAuditAction>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.listAuditActions(limit: 30);
});
