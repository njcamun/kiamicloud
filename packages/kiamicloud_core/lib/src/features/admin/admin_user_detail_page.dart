import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../../utils/kiami_layout.dart';
import '../auth/providers/auth_providers.dart';
import '../billing/providers/billing_providers.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';
import 'widgets/admin_user_edit_form.dart';
import 'widgets/admin_user_notifications_section.dart';

class AdminUserDetailPage extends ConsumerWidget {
  const AdminUserDetailPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(uid));
    final plansAsync = ref.watch(adminPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(
            user.displayName ?? user.email ?? KiamiStrings.adminUserDetailTitle,
          ),
          loading: () => const Text(KiamiStrings.adminUserDetailTitle),
          error: (_, __) => const Text(KiamiStrings.adminUserDetailTitle),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          final plans = plansAsync.valueOrNull ?? [];
          if (plans.isEmpty && plansAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: kiamiScrollPadding(context, left: 16, top: 16, right: 16),
            children: [
              if (user.email != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    user.email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              AdminUserNotificationsSection(uid: uid),
              AdminUserEditForm(
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(kiamiApiErrorMessage(e), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
