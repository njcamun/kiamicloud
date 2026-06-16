import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_admin.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../activity/providers/account_activity_providers.dart';
import '../../files/providers/files_providers.dart';
import '../providers/admin_providers.dart';

class AdminUserFeedbackSection extends ConsumerWidget {
  const AdminUserFeedbackSection({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(adminUserFeedbackProvider(uid));

    return feedbackAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final pending = items.where((f) => f.isPending).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  KiamiStrings.adminFeedbackSection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (pending > 0) ...[
                  const SizedBox(width: 8),
                  Badge(
                    label: Text('$pending'),
                    backgroundColor: KiamiColors.primaryBlue,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (f) => _FeedbackTile(
                feedback: f,
                onReviewed: () {
                  ref.invalidate(adminUserFeedbackProvider(uid));
                  ref.invalidate(adminUserDetailProvider(uid));
                  ref.invalidate(adminUsersProvider);
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(adminUserAccountActivityProvider(uid));
                  ref.invalidate(adminAccountActivityProvider);
                },
              ),
            ),
            const SizedBox(height: 20),
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

class _FeedbackTile extends ConsumerStatefulWidget {
  const _FeedbackTile({
    required this.feedback,
    required this.onReviewed,
  });

  final KiamiAdminFeedback feedback;
  final VoidCallback onReviewed;

  @override
  ConsumerState<_FeedbackTile> createState() => _FeedbackTileState();
}

class _FeedbackTileState extends ConsumerState<_FeedbackTile> {
  bool _busy = false;

  Future<void> _markReviewed() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(kiamiApiClientProvider)
          .markAdminFeedbackReviewed(widget.feedback.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.adminFeedbackReviewed)),
      );
      widget.onReviewed();
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
    final f = widget.feedback;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: f.isPending
          ? KiamiColors.primaryBlue.withValues(alpha: 0.06)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  f.isPending
                      ? Icons.mark_chat_unread_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: f.isPending
                      ? KiamiColors.primaryBlue
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.createdAt,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (f.platform != null)
                  Text(
                    f.platform!,
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(f.message),
            if (f.isPending) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _busy ? null : _markReviewed,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(KiamiStrings.adminFeedbackMarkDone),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
