import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_admin.dart';
import '../../../api/models/kiami_plan.dart';
import '../../files/providers/files_providers.dart';

final adminPlansProvider = FutureProvider.autoDispose<List<KiamiPlan>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.listPlans();
});

final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.checkIsAdmin();
});

final adminUserFeedbackProvider =
    FutureProvider.autoDispose.family<List<KiamiAdminFeedback>, String>(
  (ref, uid) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.listAdminUserFeedback(uid);
  },
);

final adminUserDetailProvider =
    FutureProvider.autoDispose.family<KiamiAdminUser, String>(
  (ref, uid) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.getAdminUser(uid);
  },
);

final adminCheckoutsProvider =
    FutureProvider.autoDispose.family<List<KiamiAdminCheckout>, String?>(
  (ref, status) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.listAdminCheckouts(status: status);
  },
);

class AdminSubscriptionsQuery {
  const AdminSubscriptionsQuery({
    this.status,
    this.limit = 25,
    this.offset = 0,
  });

  final String? status;
  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is AdminSubscriptionsQuery &&
      other.status == status &&
      other.limit == limit &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(status, limit, offset);
}

final adminSubscriptionsProvider = FutureProvider.autoDispose
    .family<KiamiAdminSubscriptionList, AdminSubscriptionsQuery>(
  (ref, query) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.listAdminSubscriptions(
      status: query.status,
      limit: query.limit,
      offset: query.offset,
    );
  },
);

final adminDashboardProvider =
    FutureProvider.autoDispose<KiamiAdminDashboard>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.getAdminDashboard();
});

final adminCloudflareUsageProvider =
    FutureProvider.autoDispose<KiamiCloudflareUsage>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  final dashboard = await ref.watch(adminDashboardProvider.future);
  if (dashboard.cloudflareUsage != null) {
    return dashboard.cloudflareUsage!;
  }
  return api.getAdminCloudflareUsage();
});

final adminStatsProvider =
    FutureProvider.autoDispose<KiamiAdminStats>((ref) async {
  return (await ref.watch(adminDashboardProvider.future)).stats;
});

final adminUsersProvider =
    FutureProvider.autoDispose.family<KiamiAdminUserList, AdminUsersQuery>(
  (ref, query) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.listAdminUsers(
      search: query.search,
      limit: query.limit,
      offset: query.offset,
    );
  },
);

class KiamiBetaFeedbackItem {
  const KiamiBetaFeedbackItem({
    required this.id,
    this.firebaseUid,
    this.email,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String? firebaseUid;
  final String? email;
  final String message;
  final String createdAt;

  factory KiamiBetaFeedbackItem.fromJson(Map<String, dynamic> json) {
    return KiamiBetaFeedbackItem(
      id: (json['id'] as num).toInt(),
      firebaseUid: json['firebaseUid'] as String?,
      email: json['email'] as String?,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

final adminFeedbackProvider =
    FutureProvider.autoDispose<List<KiamiBetaFeedbackItem>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  final list = await api.fetchAdminFeedback();
  return list.map(KiamiBetaFeedbackItem.fromJson).toList();
});

final adminSecurityEventsProvider =
    FutureProvider.autoDispose<List<KiamiSecurityEvent>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.listAdminSecurityEvents(limit: 15);
});

class AdminUsersQuery {
  const AdminUsersQuery({
    this.search,
    this.limit = 25,
    this.offset = 0,
  });

  final String? search;
  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is AdminUsersQuery &&
      other.search == search &&
      other.limit == limit &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(search, limit, offset);
}
