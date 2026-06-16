import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_account_event.dart';
import '../../../api/models/kiami_checkout.dart';
import '../../files/providers/kiami_api_provider.dart';

final accountActivityProvider =
    FutureProvider.autoDispose<KiamiAccountActivity>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.getAccountActivity();
});

final adminAccountActivityProvider =
    FutureProvider.autoDispose<List<KiamiAccountEvent>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.listAdminAccountActivity();
});

final adminUserAccountActivityProvider =
    FutureProvider.autoDispose.family<List<KiamiAccountEvent>, String>(
  (ref, uid) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.listAdminAccountActivity(uid: uid);
  },
);

final adminUserCheckoutsHistoryProvider =
    FutureProvider.autoDispose.family<List<KiamiCheckout>, String>(
  (ref, uid) async {
    final api = ref.watch(kiamiApiClientProvider);
    return api.listAdminUserCheckouts(uid);
  },
);
