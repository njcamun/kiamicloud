import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/kiami_api_exception.dart';
import '../constants/kiami_strings.dart';
import '../routing/kiami_routes.dart';
import '../features/files/providers/files_providers.dart';
import '../utils/kiami_support_contact.dart';
import '../widgets/kiami_unavailable.dart';

/// Apresenta erros da API/rede com mensagem e acção sugerida.
class KiamiErrorPresenter {
  const KiamiErrorPresenter._();

  static String message(Object error) => kiamiApiErrorMessage(error);

  static void showSnackBar(BuildContext context, Object error) {
    final text = message(error);
    final connection = kiamiApiErrorIsConnection(error);
    final fileIssue = _useFileUnavailableIllustration(error);
    final action = _actionFor(context, error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: connection
            ? KiamiNoConnectSnackContent(message: text)
            : fileIssue
                ? KiamiUnavailableSnackContent(message: text)
                : Text(text),
        action: action,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: connection || fileIssue ? 6 : 4),
      ),
    );
  }

  static bool _useFileUnavailableIllustration(Object error) {
    if (error is! KiamiApiException) return false;
    return switch (error.errorCode) {
      'connection_failed' => false,
      'quota_exceeded' => false,
      'subscription_restricted' => false,
      'subscription_suspended' => false,
      'storage_over_quota' => false,
      'invalid_token' || 'unauthorized' => false,
      _ => true,
    };
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
          onPressed: () => showPlanChangeSupportDialog(context),
        ),
      'subscription_restricted' ||
      'subscription_suspended' ||
      'storage_over_quota' =>
        SnackBarAction(
          label: KiamiStrings.subscriptionBannerAction,
          onPressed: () => showPlanChangeSupportDialog(context),
        ),
      'invalid_token' || 'unauthorized' => SnackBarAction(
          label: 'Entrar',
          onPressed: () => context.go(KiamiRoutes.auth),
        ),
      _ => null,
    };
  }
}
