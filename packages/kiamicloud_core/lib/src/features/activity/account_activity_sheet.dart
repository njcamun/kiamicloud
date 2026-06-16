import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/kiami_account_event.dart';
import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../beta/beta_feedback_sheet.dart';
import '../files/providers/files_providers.dart';
import 'providers/account_activity_providers.dart';

class AccountActivitySheet extends ConsumerStatefulWidget {
  const AccountActivitySheet({super.key});

  @override
  ConsumerState<AccountActivitySheet> createState() =>
      _AccountActivitySheetState();
}

class _AccountActivitySheetState extends ConsumerState<AccountActivitySheet> {
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshKiamiProfile(ref);
      _markUnreadIfNeeded();
    });
  }

  Future<void> _markUnreadIfNeeded() async {
    final activity = ref.read(accountActivityProvider).valueOrNull;
    if (activity == null || activity.unreadCount == 0 || _markingRead) return;
    setState(() => _markingRead = true);
    try {
      await ref.read(kiamiApiClientProvider).markAllAccountActivityRead();
      ref.invalidate(accountActivityProvider);
    } catch (_) {
      // Ignorar — historico continua visivel.
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _openFeedback() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const BetaFeedbackSheet(),
    );
    ref.invalidate(accountActivityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(accountActivityProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  KiamiStrings.accountActivityTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            KiamiStrings.accountActivityHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: activityAsync.when(
              data: (activity) {
                if (activity.events.isEmpty) {
                  return Center(
                    child: Text(
                      KiamiStrings.accountActivityEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: activity.events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _AccountEventTile(event: activity.events[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(kiamiApiErrorMessage(e)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openFeedback,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(KiamiStrings.accountActivityNewMessage),
          ),
        ],
      ),
    );
  }
}

class _AccountEventTile extends StatelessWidget {
  const _AccountEventTile({required this.event});

  final KiamiAccountEvent event;

  IconData get _icon => switch (event.kind) {
        'billing_paid' => Icons.check_circle_outline,
        'billing_rejected' => Icons.error_outline,
        'billing_proof_submitted' => Icons.upload_file_outlined,
        'billing_checkout_created' => Icons.payment_outlined,
        'support_sent' => Icons.send_outlined,
        'support_reviewed' => Icons.support_agent_outlined,
        _ => Icons.notifications_outlined,
      };

  Color? _accentColor(BuildContext context) {
    if (event.kind == 'billing_paid' || event.kind == 'support_reviewed') {
      return KiamiColors.success;
    }
    if (event.kind == 'billing_rejected') {
      return Theme.of(context).colorScheme.error;
    }
    if (event.isUnread) return KiamiColors.primaryBlue;
    return null;
  }

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
                  event.createdAt,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(event.body),
            if (event.kind == 'billing_paid' ||
                event.kind == 'billing_checkout_created') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(KiamiRoutes.billing);
                  },
                  child: const Text(KiamiStrings.billingTitle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
