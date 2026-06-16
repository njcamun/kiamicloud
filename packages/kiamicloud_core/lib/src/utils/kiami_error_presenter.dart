import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/kiami_api_exception.dart';
import '../constants/kiami_strings.dart';
import '../routing/kiami_routes.dart';
import '../features/files/providers/files_providers.dart';

/// Apresenta erros da API/rede com mensagem e acção sugerida.
class KiamiErrorPresenter {
  const KiamiErrorPresenter._();

  static String message(Object error) => kiamiApiErrorMessage(error);

  static void showSnackBar(BuildContext context, Object error) {
    final text = message(error);
    final action = _actionFor(context, error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: action,
      ),
    );
  }

  static SnackBarAction? _actionFor(BuildContext context, Object error) {
    if (error is! KiamiApiException) return null;

    return switch (error.errorCode) {
      'connection_failed' => SnackBarAction(
          label: KiamiStrings.navSettings,
          onPressed: () => context.push(KiamiRoutes.settings),
        ),
      'quota_exceeded' => SnackBarAction(
          label: KiamiStrings.quotaLimitUpgradeButton,
          onPressed: () => context.push(KiamiRoutes.billing),
        ),
      'invalid_token' || 'unauthorized' => SnackBarAction(
          label: 'Entrar',
          onPressed: () => context.go(KiamiRoutes.auth),
        ),
      _ => null,
    };
  }
}
