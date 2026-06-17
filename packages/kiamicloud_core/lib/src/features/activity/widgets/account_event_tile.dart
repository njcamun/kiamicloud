import 'package:flutter/material.dart';

import '../../../api/models/kiami_account_event.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';

class AccountEventTile extends StatelessWidget {
  const AccountEventTile({
    super.key,
    required this.event,
    this.readOnly = false,
    this.isAdminView = false,
    this.onAdminReactivate,
    this.onAdminManageSubscription,
  });

  final KiamiAccountEvent event;
  final bool readOnly;
  final bool isAdminView;
  final VoidCallback? onAdminReactivate;
  final VoidCallback? onAdminManageSubscription;

  IconData get _icon => switch (event.kind) {
        'billing_paid' => Icons.check_circle_outline,
        'billing_rejected' => Icons.error_outline,
        'billing_proof_submitted' => Icons.upload_file_outlined,
        'billing_checkout_created' => Icons.payment_outlined,
        'subscription_expiring' => Icons.schedule_outlined,
        'subscription_grace' => Icons.hourglass_top_outlined,
        'subscription_restricted' => Icons.cloud_upload_outlined,
        'subscription_suspended' => Icons.block_outlined,
        'subscription_pending_deletion' => Icons.delete_forever_outlined,
        'subscription_reactivated' => Icons.autorenew,
        'subscription_renewed' => Icons.verified_outlined,
        'subscription_deleted' => Icons.person_off_outlined,
        'quota_updated' => Icons.storage_outlined,
        _ => Icons.notifications_outlined,
      };

  Color? _accentColor(BuildContext context) {
    if (event.kind == 'billing_paid' ||
        event.kind == 'subscription_renewed' ||
        event.kind == 'subscription_reactivated') {
      return KiamiColors.success;
    }
    if (event.kind == 'billing_rejected' ||
        event.kind == 'subscription_suspended' ||
        event.kind == 'subscription_pending_deletion' ||
        event.kind == 'subscription_deleted') {
      return Theme.of(context).colorScheme.error;
    }
    if (event.kind == 'subscription_restricted' ||
        event.kind == 'subscription_grace' ||
        event.kind == 'subscription_expiring') {
      return KiamiColors.warning;
    }
    if (event.isUnread) return KiamiColors.primaryBlue;
    return null;
  }

  bool get _showAdminSubscriptionControl =>
      isAdminView &&
      !readOnly &&
      (event.isSubscription ||
          event.kind == 'billing_rejected' ||
          event.kind == 'billing_paid');

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: event.isUnread
          ? KiamiColors.primaryBlue.withValues(alpha: 0.06)
          : accent?.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _icon,
                  size: 18,
                  color: accent ?? scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        event.kindLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatWhen(event.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(event.body),
            if (_showAdminSubscriptionControl) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  if (onAdminManageSubscription != null)
                    TextButton(
                      onPressed: onAdminManageSubscription,
                      child: const Text(KiamiStrings.adminViewSubscriptions),
                    ),
                  if (onAdminReactivate != null &&
                      (event.isSubscription || event.kind == 'billing_rejected'))
                    FilledButton.tonal(
                      onPressed: onAdminReactivate,
                      child: const Text(KiamiStrings.adminSubscriptionReactivate),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatWhen(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso.length > 16 ? iso.substring(0, 16) : iso;
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m ${local.year} $h:$min';
}
