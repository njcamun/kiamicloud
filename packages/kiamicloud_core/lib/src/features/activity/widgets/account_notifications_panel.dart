import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/models/kiami_account_event.dart';
import '../../../constants/kiami_strings.dart';
import '../../../routing/kiami_routes.dart';
import '../../files/providers/files_providers.dart';
import '../providers/account_activity_providers.dart';
import 'account_event_tile.dart';

List<KiamiAccountEvent> planNotificationEvents(List<KiamiAccountEvent> events) {
  return events.where((e) => e.isPlanNotification).toList();
}

int planNotificationUnreadCount(KiamiAccountActivity? activity) {
  if (activity == null) return 0;
  return planNotificationEvents(activity.events)
      .where((e) => e.isUnread)
      .length;
}

/// Lista de notificações de plano — só leitura para o utilizador.
class AccountNotificationsPanel extends ConsumerStatefulWidget {
  const AccountNotificationsPanel({
    super.key,
    this.adminUid,
    this.onClose,
    this.compact = false,
  });

  final String? adminUid;
  final VoidCallback? onClose;
  final bool compact;

  bool get isAdminView => adminUid != null;

  @override
  ConsumerState<AccountNotificationsPanel> createState() =>
      _AccountNotificationsPanelState();
}

class _AccountNotificationsPanelState
    extends ConsumerState<AccountNotificationsPanel> {
  bool _markingRead = false;
  bool _reactivating = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isAdminView) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markUnreadIfNeeded());
    }
  }

  Future<void> _markUnreadIfNeeded() async {
    final activity = ref.read(accountActivityProvider).valueOrNull;
    if (activity == null ||
        planNotificationUnreadCount(activity) == 0 ||
        _markingRead) {
      return;
    }
    setState(() => _markingRead = true);
    try {
      await ref.read(kiamiApiClientProvider).markAllAccountActivityRead();
      ref.invalidate(accountActivityProvider);
    } catch (_) {
      // Historico continua visivel.
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _markAllRead() async {
    if (widget.isAdminView || _markingRead) return;
    setState(() => _markingRead = true);
    try {
      await ref.read(kiamiApiClientProvider).markAllAccountActivityRead();
      ref.invalidate(accountActivityProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _adminReactivate(String uid) async {
    if (_reactivating) return;
    setState(() => _reactivating = true);
    try {
      final api = ref.read(kiamiApiClientProvider);
      await api.reactivateAdminSubscription(uid);
      ref.invalidate(adminUserAccountActivityProvider(uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.adminSubscriptionReactivated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _reactivating = false);
    }
  }

  void _adminManageSubscription() {
    widget.onClose?.call();
    context.push(KiamiRoutes.adminSubscriptions);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAdminView) {
      final eventsAsync =
          ref.watch(adminUserAccountActivityProvider(widget.adminUid!));
      return eventsAsync.when(
        data: (events) =>
            _buildList(context, planNotificationEvents(events)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(kiamiApiErrorMessage(e)),
      );
    }

    final activityAsync = ref.watch(accountActivityProvider);
    return activityAsync.when(
      data: (activity) =>
          _buildList(context, planNotificationEvents(activity.events)),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(kiamiApiErrorMessage(e)),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<KiamiAccountEvent> events,
  ) {
    final unread = widget.isAdminView
        ? 0
        : planNotificationUnreadCount(
            ref.watch(accountActivityProvider).valueOrNull,
          );

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          KiamiStrings.notificationsEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final maxH = widget.compact
        ? 360.0
        : MediaQuery.sizeOf(context).height * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.isAdminView && unread > 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _markingRead ? null : _markAllRead,
              child: const Text(KiamiStrings.notificationsMarkAllRead),
            ),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final event = events[i];
              return AccountEventTile(
                event: event,
                readOnly: !widget.isAdminView,
                isAdminView: widget.isAdminView,
                onAdminReactivate: widget.isAdminView
                    ? () => _adminReactivate(widget.adminUid!)
                    : null,
                onAdminManageSubscription: widget.isAdminView
                    ? _adminManageSubscription
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
