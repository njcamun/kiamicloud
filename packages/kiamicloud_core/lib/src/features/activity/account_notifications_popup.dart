import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../../widgets/kiami_unavailable.dart';
import '../connectivity/connectivity_provider.dart';
import '../files/providers/files_providers.dart';
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

  void _close(BuildContext context) => Navigator.pop(context);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(accountActivityProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    if (!isOnline) {
      return _issueDialog(context, const KiamiNoConnectCard(compact: true));
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: activityAsync.when(
          data: (activity) {
            final events = planNotificationEvents(activity.events);
            if (events.isEmpty) {
              return _NotificationsDialogShell(
                onClose: () => _close(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    KiamiStrings.notificationsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return _NotificationsDialogShell(
              onClose: () => _close(context),
              child: const AccountNotificationsPanel(),
            );
          },
          loading: () => _NotificationsDialogShell(
            onClose: () => _close(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => _issueDialog(
            context,
            kiamiApiErrorIsConnection(error)
                ? const KiamiNoConnectCard(compact: true)
                : const KiamiUnavailableCard(compact: true),
          ),
        ),
      ),
    );
  }

  Widget _issueDialog(BuildContext context, Widget imageCard) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => _close(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              imageCard,
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsDialogShell extends StatelessWidget {
  const _NotificationsDialogShell({
    required this.onClose,
    required this.child,
  });

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
