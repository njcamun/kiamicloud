import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/kiami_billing_status.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/format_bytes.dart';
import '../../utils/kiami_layout.dart';
import '../../utils/kiami_support_contact.dart';
import '../../utils/quota_ui.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/subscription_banner.dart';
import '../activity/providers/account_activity_providers.dart';
import 'providers/billing_providers.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(KiamiStrings.billingTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(billingStatusProvider);
          ref.invalidate(accountActivityProvider);
          await ref.read(billingStatusProvider.future);
        },
        child: ListView(
          padding: kiamiScrollPadding(
            context,
            left: kiamiSettingsListHorizontalPadding,
            top: 20,
            right: kiamiSettingsListHorizontalPadding,
            bottomExtra: 24,
          ),
          children: [
            billingAsync.when(
              data: (b) => _CurrentPlanCard(
                key: ValueKey(b.plan.code),
                status: b,
                listHorizontalPadding: kiamiSettingsListHorizontalPadding,
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => KiamiApiUnavailableCard(
                error: e,
                compact: true,
                onRetry: () => ref.invalidate(billingStatusProvider),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              KiamiStrings.billingUpgradeTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              KiamiStrings.billingUpgradeHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            KiamiCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    KiamiStrings.planChangeSupportBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showPlanChangeSupportDialog(context),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: const Text(KiamiStrings.planChangeSupportAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    super.key,
    required this.status,
    required this.listHorizontalPadding,
  });

  final KiamiBillingStatus status;
  final double listHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final plan = status.plan;
    final used = status.storageUsedBytes;
    final quota = plan.quotaBytes;
    final fraction = quota > 0 ? (used / quota).clamp(0.0, 1.0) : 0.0;

    final card = KiamiCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              KiamiStrings.billingCurrentPlan,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color: QuotaUi.barColor(status.quota.status),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatBytes(used)} / ${formatBytes(quota)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plan.priceKzMonth > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${_formatKz(plan.priceKzMonth)}${KiamiStrings.billingPerMonth}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                KiamiStrings.billingFreePlan,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (status.subscription != null || status.access != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _SubscriptionSection(status: status),
            ],
          ],
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      child: LayoutBuilder(
        key: ValueKey(plan.code),
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth + 2 * listHorizontalPadding;
          return Transform.translate(
            offset: Offset(-listHorizontalPadding, 0),
            child: SizedBox(
              width: fullWidth,
              child: card,
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.status});

  final KiamiBillingStatus status;

  @override
  Widget build(BuildContext context) {
    final sub = status.subscription;
    final access = status.access;
    final effective = sub?.effectiveStatus ?? access?.effectiveStatus ?? 'active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          KiamiStrings.subscriptionStatusTitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subscriptionStatusLabel(effective),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (sub?.endsAt != null) ...[
          const SizedBox(height: 4),
          Text(
            '${KiamiStrings.subscriptionEndsAt}: ${_formatDate(sub!.endsAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (sub?.gracePeriodEndsAt != null) ...[
          const SizedBox(height: 4),
          Text(
            '${KiamiStrings.subscriptionGraceEndsAt}: ${_formatDate(sub!.gracePeriodEndsAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (sub?.deletionScheduledAt != null) ...[
          const SizedBox(height: 4),
          Text(
            '${KiamiStrings.subscriptionDeletionAt}: ${_formatDate(sub!.deletionScheduledAt!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
        if (access != null && access.needsAttention) ...[
          const SizedBox(height: 10),
          SubscriptionBanner(
            access: access,
            onRenew: () => showPlanChangeSupportDialog(context),
          ),
        ],
      ],
    );
  }
}

String _formatDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

String _formatKz(int amount) {
  final s = amount.toString();
  if (s.length <= 3) return '$s Kz';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${buf.toString()} Kz';
}
