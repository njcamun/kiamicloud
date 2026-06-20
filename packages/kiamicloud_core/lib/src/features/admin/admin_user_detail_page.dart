import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../../theme/kiami_colors.dart';
import '../../theme/kiami_decorations.dart';
import '../../utils/format_bytes.dart';
import '../../utils/format_date.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/kiami_card.dart';
import '../auth/providers/auth_providers.dart';
import '../billing/providers/billing_providers.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';
import 'widgets/admin_user_edit_form.dart';
import 'widgets/admin_user_notifications_section.dart';
import 'widgets/admin_user_subscription_section.dart';

class AdminUserDetailPage extends ConsumerWidget {
  const AdminUserDetailPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(uid));
    final plansAsync = ref.watch(adminPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(KiamiStrings.adminUserDetailTitle),
      ),
      body: userAsync.when(
        data: (user) {
          final plans = plansAsync.valueOrNull ?? [];
          if (plans.isEmpty && plansAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final name = user.displayName ?? user.email ?? user.uid;
          final initial =
              name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

          return ListView(
            padding: kiamiScrollPadding(
              context,
              left: 16,
              top: 16,
              right: 16,
              bottomExtra: 28,
            ),
            children: [
              KiamiCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          KiamiColors.primaryBlue.withValues(alpha: 0.12),
                      foregroundColor: KiamiColors.primaryBlue,
                      child: Text(
                        initial,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.email!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: KiamiColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(KiamiDecorations.radiusMd),
                      ),
                      child: Text(
                        user.planName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: KiamiColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          KiamiStrings.adminStorageInUse,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${formatBytes(user.storageUsedBytes)} / ${formatBytes(user.quotaBytes)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: user.storageUsageFraction,
                        minHeight: 6,
                        backgroundColor:
                            KiamiColors.primaryBlue.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${user.filesCount} ${KiamiStrings.adminUserFiles.toLowerCase()} · ${KiamiStrings.adminMemberSince} ${formatFileDate(user.createdAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (user.hasPendingNotifications) ...[
                const SizedBox(height: 16),
                AdminUserNotificationsSection(uid: uid),
              ],
              const SizedBox(height: 16),
              AdminUserSubscriptionSection(
                uid: uid,
                onChanged: () {
                  ref.invalidate(adminUserDetailProvider(uid));
                  ref.invalidate(adminUsersProvider);
                  final currentUid =
                      ref.read(authStateProvider).valueOrNull?.uid;
                  if (currentUid != null && currentUid == uid) {
                    refreshKiamiProfile(ref);
                    ref.invalidate(billingStatusProvider);
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                KiamiStrings.adminPlanAndLimits,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              KiamiCard(
                padding: const EdgeInsets.all(16),
                child: AdminUserEditForm(
                  user: user,
                  plans: plans,
                  onSaved: (updated) {
                    ref.invalidate(adminUserDetailProvider(uid));
                    ref.invalidate(adminUsersProvider);
                    ref.invalidate(adminStatsProvider);
                    final currentUid =
                        ref.read(authStateProvider).valueOrNull?.uid;
                    if (currentUid != null && currentUid == updated.uid) {
                      refreshKiamiProfile(ref);
                      ref.invalidate(billingStatusProvider);
                    }
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: KiamiApiUnavailableCard(
              error: e,
              onRetry: () {
                ref.invalidate(adminUserDetailProvider(uid));
                ref.invalidate(adminPlansProvider);
              },
            ),
          ),
        ),
      ),
    );
  }
}
