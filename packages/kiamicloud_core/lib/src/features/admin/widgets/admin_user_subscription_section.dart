import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_decorations.dart';
import '../../../utils/format_date.dart';
import '../../../widgets/kiami_api_unavailable_card.dart';
import '../../../widgets/kiami_card.dart';
import '../../../widgets/subscription_banner.dart';
import '../../files/providers/files_providers.dart';
import '../providers/admin_providers.dart';

/// Gestão da subscrição de um utilizador (admin).
class AdminUserSubscriptionSection extends ConsumerStatefulWidget {
  const AdminUserSubscriptionSection({
    super.key,
    required this.uid,
    this.onChanged,
  });

  final String uid;
  final VoidCallback? onChanged;

  @override
  ConsumerState<AdminUserSubscriptionSection> createState() =>
      _AdminUserSubscriptionSectionState();
}

class _AdminUserSubscriptionSectionState
    extends ConsumerState<AdminUserSubscriptionSection> {
  bool _busy = false;

  Future<void> _reactivate() async {
    setState(() => _busy = true);
    try {
      await ref.read(kiamiApiClientProvider).reactivateAdminSubscription(
            widget.uid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(KiamiStrings.adminSubscriptionReactivated),
        ),
      );
      ref.invalidate(adminUserSubscriptionProvider(widget.uid));
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _adjustEndsAt(String? currentEndsAt) async {
    final controller = TextEditingController(
      text: currentEndsAt != null && currentEndsAt.length >= 10
          ? currentEndsAt.substring(0, 10)
          : '',
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
            child: const Text(KiamiStrings.adminSave),
          ),
        ],
      ),
    );
    if (picked == null || picked.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(kiamiApiClientProvider).adjustAdminSubscriptionEndsAt(
            uid: widget.uid,
            endsAt: picked.contains('T') ? picked : '${picked}T23:59:59.000Z',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(KiamiStrings.adminSubscriptionEndsAtUpdated),
        ),
      );
      ref.invalidate(adminUserSubscriptionProvider(widget.uid));
      widget.onChanged?.call();
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
    final subAsync = ref.watch(adminUserSubscriptionProvider(widget.uid));
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          KiamiStrings.adminSubscriptionSection,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        subAsync.when(
          data: (subscription) {
            if (subscription == null) {
              return KiamiCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      KiamiStrings.adminSubscriptionNone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: secondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _busy ? null : _reactivate,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(KiamiStrings.adminSubscriptionReactivate),
                    ),
                  ],
                ),
              );
            }

            final needsAttention = subscription.effectiveStatus != 'active';
            final statusColor = needsAttention
                ? KiamiColors.warning
                : KiamiColors.primaryBlue;

            return KiamiCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subscriptionStatusLabel(
                            subscription.effectiveStatus,
                          ),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            KiamiDecorations.radiusSm,
                          ),
                        ),
                        child: Text(
                          subscription.planCode,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (subscription.endsAt != null)
                    _DetailRow(
                      icon: Icons.event_outlined,
                      label: KiamiStrings.subscriptionEndsAt,
                      value: formatFileDate(subscription.endsAt!),
                    ),
                  if (subscription.gracePeriodEndsAt != null)
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: KiamiStrings.subscriptionGraceEndsAt,
                      value: formatFileDate(subscription.gracePeriodEndsAt!),
                    ),
                  if (subscription.deletionScheduledAt != null)
                    _DetailRow(
                      icon: Icons.delete_outline_rounded,
                      label: KiamiStrings.subscriptionDeletionAt,
                      value: formatFileDate(subscription.deletionScheduledAt!),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _adjustEndsAt(subscription.endsAt),
                          child: const Text(
                            KiamiStrings.adminSubscriptionAdjustEnds,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _reactivate,
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  KiamiStrings.adminSubscriptionReactivate,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => KiamiApiUnavailableCard(
            error: e,
            onRetry: () => ref.invalidate(adminUserSubscriptionProvider(widget.uid)),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: secondary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
