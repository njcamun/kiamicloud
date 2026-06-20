import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/models/kiami_admin.dart';
import '../../../routing/kiami_routes.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_decorations.dart';
import '../../../utils/format_bytes.dart';
import '../../../widgets/kiami_card.dart';

/// Linha de utilizador na listagem administrativa.
class AdminUserListTile extends StatelessWidget {
  const AdminUserListTile({super.key, required this.user});

  final KiamiAdminUser user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName ?? user.email ?? user.uid;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return KiamiCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push(KiamiRoutes.adminUserFor(user.uid)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: KiamiColors.primaryBlue.withValues(alpha: 0.12),
            foregroundColor: KiamiColors.primaryBlue,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (user.hasPendingNotifications)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KiamiColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${user.pendingNotificationsCount}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: KiamiColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
                if (user.displayName != null && user.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: secondary,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PlanChip(label: user.planName),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${formatBytes(user.storageUsedBytes)} / ${formatBytes(user.quotaBytes)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: secondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: user.storageUsageFraction,
                    minHeight: 4,
                    backgroundColor:
                        KiamiColors.primaryBlue.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: secondary, size: 22),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusSm),
        border: Border.all(
          color: KiamiColors.primaryBlue.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: KiamiColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
