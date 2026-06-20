import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/format_bytes.dart';
import '../../utils/kiami_layout.dart';
import '../../api/models/kiami_admin.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/kiami_unavailable.dart';
import '../connectivity/connectivity_provider.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';
import 'widgets/admin_cloudflare_usage_section.dart';
import 'widgets/admin_nav_card.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminDashboardProvider);
    ref.invalidate(adminStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final statsConnectionError = statsAsync.hasError &&
        kiamiApiErrorIsConnection(statsAsync.error!);
    final showNoConnectOverview = !isOnline || statsConnectionError;
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(KiamiStrings.adminTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kiamiScrollPadding(
            context,
            left: 16,
            top: 16,
            right: 16,
            bottomExtra: 24,
          ),
          children: [
            if (showNoConnectOverview) ...[
              Text(
                KiamiStrings.adminOverviewTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              const KiamiNoConnectCard(),
            ] else
              statsAsync.when(
                data: (s) => _OverviewSection(stats: s),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorText(
                  error: e,
                  onRetry: () => _refresh(ref),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              KiamiStrings.adminManageSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                AdminNavCard(
                  icon: Icons.people_outline_rounded,
                  title: KiamiStrings.adminManageUsers,
                  subtitle: KiamiStrings.adminManageUsersHint,
                  badge: stats != null ? '${stats.usersCount}' : null,
                  onTap: () => context.push(KiamiRoutes.adminUsers),
                ),
                const SizedBox(height: 8),
                AdminNavCard(
                  icon: Icons.payment_outlined,
                  title: KiamiStrings.adminCheckoutsTitle,
                  subtitle: KiamiStrings.adminViewPendingPayments,
                  badge: stats != null && stats.pendingCheckoutsCount > 0
                      ? '${stats.pendingCheckoutsCount}'
                      : null,
                  highlight:
                      stats != null && stats.pendingCheckoutsCount > 0,
                  onTap: () => context.push(KiamiRoutes.adminCheckouts),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AdminCloudflareUsageSection(),
          ],
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.stats});

  final KiamiAdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          KiamiStrings.adminOverviewTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.people_outline,
                  label: KiamiStrings.adminStatUsers,
                  value: '${stats.usersCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.folder_outlined,
                  label: KiamiStrings.adminStatFiles,
                  value: '${stats.activeFilesCount}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.storage_outlined,
                  label: KiamiStrings.adminStatStorage,
                  value: formatBytes(stats.totalStorageUsedBytes),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.payment_outlined,
                  label: KiamiStrings.adminStatPending,
                  value: '${stats.pendingCheckoutsCount}',
                  highlight: stats.pendingCheckoutsCount > 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlight ? 1 : 0,
      color: highlight
          ? KiamiColors.primaryBlue.withValues(alpha: 0.08)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: KiamiColors.primaryBlue),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: KiamiApiUnavailableCard(
        error: error,
        onRetry: onRetry,
        compact: true,
      ),
    );
  }
}
