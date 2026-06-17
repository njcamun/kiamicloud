import 'package:flutter/material.dart';

import '../api/models/kiami_subscription_access.dart';
import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';

class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({
    super.key,
    required this.access,
    this.onRenew,
  });

  final KiamiSubscriptionAccess access;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    if (!access.needsAttention) return const SizedBox.shrink();

    final isCritical = access.effectiveStatus == 'suspended' ||
        access.effectiveStatus == 'pending_deletion' ||
        access.effectiveStatus == 'deleted';

    final fg = isCritical ? KiamiColors.error : KiamiColors.warning;
    final bg = fg.withValues(alpha: 0.1);
    final message = KiamiStrings.subscriptionMessageFor(
      effectiveStatus: access.effectiveStatus,
      blockReason: access.blockReason,
    );

    final content = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
            color: fg,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (onRenew != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    KiamiStrings.subscriptionBannerAction,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fg.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onRenew != null)
            Icon(Icons.chevron_right_rounded, color: fg),
        ],
      ),
    );

    if (onRenew == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRenew,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

String subscriptionStatusLabel(String effectiveStatus) {
  return switch (effectiveStatus) {
    'active' => KiamiStrings.subscriptionStatusActive,
    'grace_period' => KiamiStrings.subscriptionStatusGrace,
    'restricted' => KiamiStrings.subscriptionStatusRestricted,
    'suspended' => KiamiStrings.subscriptionStatusSuspended,
    'pending_deletion' => KiamiStrings.subscriptionStatusPendingDeletion,
    'cancelled' => KiamiStrings.subscriptionStatusCancelled,
    _ => effectiveStatus,
  };
}
