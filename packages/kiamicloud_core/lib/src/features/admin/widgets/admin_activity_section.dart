import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_account_event.dart';
import '../../../constants/kiami_strings.dart';
import '../../activity/widgets/account_event_tile.dart';
import '../../activity/providers/account_activity_providers.dart';
import 'admin_user_notifications_section.dart';

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
    return AdminUserNotificationsSection(uid: uid);
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
    final userLabel =
        event.userDisplayName ?? event.userEmail ?? event.firebaseUid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showUser && (userLabel?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              userLabel ?? '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        AccountEventTile(event: event),
      ],
    );
  }
}
