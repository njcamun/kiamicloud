import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/legal_acceptance_store.dart';
import '../../auth/providers/auth_providers.dart';

/// `true` quando não há sessão ou os termos já foram aceites.
final legalAcceptanceGateProvider =
    StateNotifierProvider<LegalAcceptanceGateNotifier, bool>((ref) {
  return LegalAcceptanceGateNotifier(ref);
});

class LegalAcceptanceGateNotifier extends StateNotifier<bool> {
  LegalAcceptanceGateNotifier(this._ref) : super(false) {
    _ref.listen(authStateProvider, (_, next) {
      _reload(next.valueOrNull?.uid);
    });
    _reload(_ref.read(authStateProvider).valueOrNull?.uid);
  }

  final Ref _ref;

  Future<void> _reload(String? uid) async {
    if (uid == null) {
      state = true;
      return;
    }
    final accepted = await LegalAcceptanceStore.hasAccepted(uid);
    state = accepted;
  }

  Future<void> acceptForCurrentUser() async {
    final uid = _ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await LegalAcceptanceStore.markAccepted(uid);
    state = true;
  }
}
