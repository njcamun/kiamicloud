import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/kiami_user.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/legal/providers/legal_acceptance_providers.dart';

/// Notifica o GoRouter quando o estado de auth ou termos legais muda.
class KiamiRouterRefresh extends ChangeNotifier {
  KiamiRouterRefresh(Ref ref) {
    ref.listen<AsyncValue<KiamiUser?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
    ref.listen<bool>(legalAcceptanceGateProvider, (_, __) {
      notifyListeners();
    });
  }
}
