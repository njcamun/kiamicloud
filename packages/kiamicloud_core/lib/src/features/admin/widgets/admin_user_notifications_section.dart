import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/kiami_strings.dart';
import '../../activity/widgets/account_notifications_panel.dart';

/// Notificações do utilizador — mesma vista que o pop-up no dashboard.
class AdminUserNotificationsSection extends ConsumerWidget {
  const AdminUserNotificationsSection({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          KiamiStrings.adminUserActivityTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
          Text(
            KiamiStrings.notificationsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        AccountNotificationsPanel(adminUid: uid, compact: true),
        const SizedBox(height: 20),
      ],
    );
  }
}
