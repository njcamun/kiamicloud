import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/admin_access_store.dart';
import '../../files/providers/files_providers.dart';

/// Admin confirmado alguma vez — mantém selector de API mesmo com servidor offline.
final adminCachedEligibleProvider = FutureProvider<bool>((ref) {
  return AdminAccessStore.isEligible();
});

final adminUiEligibleProvider = FutureProvider<bool>((ref) async {
  final cached = await AdminAccessStore.isEligible();
  try {
    final isAdmin = await ref.read(kiamiApiClientProvider).checkIsAdmin();
    if (isAdmin) {
      await AdminAccessStore.setEligible(true);
      ref.invalidate(adminCachedEligibleProvider);
      return true;
    }
    await AdminAccessStore.setEligible(false);
    ref.invalidate(adminCachedEligibleProvider);
    return false;
  } catch (_) {
    return cached;
  }
});

/// Secção admin em Definições — visível se admin confirmado ou cache local (API offline).
final adminSettingsSectionProvider = Provider<bool>((ref) {
  final cached = ref.watch(adminCachedEligibleProvider).valueOrNull ?? false;
  final live = ref.watch(adminUiEligibleProvider);
  return live.when(
    data: (eligible) => eligible,
    loading: () => cached,
    error: (_, __) => cached,
  );
});
