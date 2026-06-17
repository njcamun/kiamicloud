import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import 'providers/account_activity_providers.dart';
import 'widgets/account_notifications_panel.dart';

/// Ícone de notificações com badge de não lidas.
class AccountNotificationsIconButton extends ConsumerWidget {
  const AccountNotificationsIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = planNotificationUnreadCount(
      ref.watch(accountActivityProvider).valueOrNull,
    );

    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: KiamiStrings.notificationsTooltip,
      onPressed: () => showAccountNotificationsPopup(context, ref),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

/// Pop-up de notificações (utilizador autenticado).
Future<void> showAccountNotificationsPopup(
  BuildContext context,
  WidgetRef ref,
) {
  ref.invalidate(accountActivityProvider);
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _AccountNotificationsDialog(),
  );
}

class _AccountNotificationsDialog extends ConsumerWidget {
  const _AccountNotificationsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(accountActivityProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: activityAsync.when(
          data: (activity) {
            final events = planNotificationEvents(activity.events);
            if (events.isEmpty) {
              return _EmptyNotificationsBody(onClose: () => Navigator.pop(context));
            }
            return _NotificationsBody(onClose: () => Navigator.pop(context));
          },
          loading: () => _EmptyNotificationsBody(
            onClose: () => Navigator.pop(context),
            loading: true,
          ),
          error: (_, __) => _NotificationsBody(onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }
}

class _EmptyNotificationsBody extends StatelessWidget {
  const _EmptyNotificationsBody({
    required this.onClose,
    this.loading = false,
  });

  final VoidCallback onClose;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Text(
                KiamiStrings.notificationsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  KiamiStrings.notificationsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            KiamiStrings.notificationsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const AccountNotificationsPanel(),
        ],
      ),
    );
  }
}
