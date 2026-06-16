import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/models/kiami_profile.dart';
import '../api/kiami_api_config.dart';
import '../constants/kiami_constants.dart';
import '../constants/kiami_strings.dart';
import '../routing/kiami_routes.dart';
import '../utils/format_bytes.dart';

/// Explica o armazenamento, quotas e upgrade de plano.
Future<void> showStorageHelpDialog(
  BuildContext context, {
  KiamiProfile? profile,
}) {
  final onLan = KiamiApiConfig.isLocalApiUrl;
  final maxLabel = profile != null
      ? formatTransferLimit(profile.maxFileSizeBytes)
      : KiamiConstants.maxUploadLabel;
  final planName =
      profile?.plan.name ?? KiamiStrings.billingFreePlan;
  final quotaLabel = onLan
      ? KiamiStrings.noTransferLimit
      : (profile != null
          ? formatBytes(profile.plan.quotaBytes)
          : '${KiamiConstants.basicoPlanQuotaGb} GB');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.help_outline_rounded,
            color: Theme.of(ctx).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text(KiamiStrings.storageHelpTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpSection(
              title: KiamiStrings.storageHelpUsageTitle,
              body: KiamiStrings.storageHelpUsageBody,
            ),
            _HelpSection(
              title: KiamiStrings.storageHelpPlanTitle(planName, quotaLabel),
              body: KiamiStrings.storageHelpPlanBody,
            ),
            _HelpSection(
              title: KiamiStrings.storageHelpUploadTitle(maxLabel),
              body: KiamiStrings.storageHelpUploadBody,
            ),
            _HelpSection(
              title: KiamiStrings.storageHelpAlertsTitle,
              body: onLan
                  ? KiamiStrings.localStorageHint
                  : KiamiStrings.storageHelpAlertsBody,
            ),
            if (!onLan)
              _HelpSection(
                title: KiamiStrings.storageHelpUpgradeTitle,
                body: KiamiStrings.storageHelpUpgradeBody,
                emphasized: true,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(KiamiStrings.closeButton),
        ),
        if (!onLan)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(KiamiRoutes.billing);
            },
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text(KiamiStrings.storageHelpUpgradeButton),
          ),
      ],
    ),
  );
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.body,
    this.emphasized = false,
  });

  final String title;
  final String body;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasized ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.bodyMedium?.copyWith(
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
