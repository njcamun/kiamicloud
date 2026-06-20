import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/kiami_admin.dart';
import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/format_bytes.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/subscription_banner.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';

class AdminSubscriptionsPage extends ConsumerStatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  ConsumerState<AdminSubscriptionsPage> createState() =>
      _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends ConsumerState<AdminSubscriptionsPage> {
  String? _statusFilter;
  int _offset = 0;
  static const _pageSize = 25;

  AdminSubscriptionsQuery get _query => AdminSubscriptionsQuery(
        status: _statusFilter,
        limit: _pageSize,
        offset: _offset,
      );

  void _refresh() {
    ref.invalidate(adminSubscriptionsProvider(_query));
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(adminSubscriptionsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text(KiamiStrings.adminSubscriptionsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kiamiScrollPadding(context, left: 16, top: 12, right: 16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: KiamiStrings.adminSubscriptionsFilterAll,
                  selected: _statusFilter == null,
                  onSelected: () => setState(() {
                    _statusFilter = null;
                    _offset = 0;
                  }),
                ),
                for (final s in const [
                  'grace_period',
                  'restricted',
                  'suspended',
                  'pending_deletion',
                ])
                  _FilterChip(
                    label: subscriptionStatusLabel(s),
                    selected: _statusFilter == s,
                    onSelected: () => setState(() {
                      _statusFilter = s;
                      _offset = 0;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            listAsync.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(KiamiStrings.adminSubscriptionsEmpty),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...data.items.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SubscriptionCard(
                          subscription: s,
                          onChanged: _refresh,
                        ),
                      ),
                    ),
                    if (data.total > _pageSize) _PaginationBar(
                      offset: _offset,
                      pageSize: _pageSize,
                      total: data.total,
                      onPrev: _offset > 0
                          ? () => setState(() => _offset -= _pageSize)
                          : null,
                      onNext: _offset + _pageSize < data.total
                          ? () => setState(() => _offset += _pageSize)
                          : null,
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 24),
                child: KiamiApiUnavailableCard(
                  error: e,
                  onRetry: _refresh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _SubscriptionCard extends ConsumerStatefulWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onChanged,
  });

  final KiamiAdminSubscription subscription;
  final VoidCallback onChanged;

  @override
  ConsumerState<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _busy = false;

  Future<void> _reactivate() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(kiamiApiClientProvider);
      await api.reactivateAdminSubscription(widget.subscription.firebaseUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.adminSubscriptionReactivated)),
      );
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _adjustEndsAt() async {
    final controller = TextEditingController(
      text: widget.subscription.endsAt?.substring(0, 10) ?? '',
    );
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(KiamiStrings.adminSubscriptionAdjustEnds),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'YYYY-MM-DD',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(KiamiStrings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (picked == null || picked.isEmpty) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(kiamiApiClientProvider);
      await api.adjustAdminSubscriptionEndsAt(
        uid: widget.subscription.firebaseUid,
        endsAt: picked.contains('T') ? picked : '${picked}T23:59:59.000Z',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(KiamiStrings.adminSubscriptionEndsAtUpdated),
        ),
      );
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscription;
    final label = s.email ?? s.displayName ?? s.firebaseUid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text(subscriptionStatusLabel(s.effectiveStatus)),
                  backgroundColor:
                      KiamiColors.primaryBlue.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${s.planCode} · ${formatBytes(s.storageUsedBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (s.endsAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${KiamiStrings.subscriptionEndsAt}: ${s.endsAt!.substring(0, 10)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: _busy ? null : () => context.push(
                        KiamiRoutes.adminUserFor(s.firebaseUid),
                      ),
                  child: const Text('Utilizador'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _busy ? null : _adjustEndsAt,
                  child: const Text(KiamiStrings.adminSubscriptionAdjustEnds),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _reactivate,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(KiamiStrings.adminSubscriptionReactivate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.offset,
    required this.pageSize,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int offset;
  final int pageSize;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final from = offset + 1;
    final to = (offset + pageSize).clamp(0, total);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$from–$to / $total'),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
