import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_account_event.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../files/providers/files_providers.dart';
import '../../activity/providers/account_activity_providers.dart';

class AdminPlatformActivitySection extends ConsumerWidget {
  const AdminPlatformActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminAccountActivityProvider);

    return activityAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        final recent = events.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              KiamiStrings.adminActivityTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...recent.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AdminActivityTile(event: e, showUser: true),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class AdminUserActivitySection extends ConsumerWidget {
  const AdminUserActivitySection({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminUserAccountActivityProvider(uid));

    return activityAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              KiamiStrings.adminUserActivityTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AdminActivityTile(event: e, showUser: false),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(kiamiApiErrorMessage(e)),
      ),
    );
  }
}

class _AdminActivityTile extends StatelessWidget {
  const _AdminActivityTile({
    required this.event,
    required this.showUser,
  });

  final KiamiAccountEvent event;
  final bool showUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final userLabel = event.userDisplayName ?? event.userEmail ?? event.firebaseUid;

    return Card(
      color: event.isBilling
          ? KiamiColors.warning.withValues(alpha: 0.05)
          : KiamiColors.primaryBlue.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  event.isBilling
                      ? Icons.payment_outlined
                      : Icons.support_agent_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  event.createdAt,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (showUser && (userLabel?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Text(
                userLabel ?? '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${event.kindLabel} · ${event.body}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
