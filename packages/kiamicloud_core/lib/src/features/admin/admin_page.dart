import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/format_bytes.dart';
import '../../utils/kiami_layout.dart';
import '../../api/models/kiami_admin.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';
import 'widgets/admin_cloudflare_usage_section.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  final _searchController = TextEditingController();
  String? _search;
  int _offset = 0;
  static const _pageSize = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AdminUsersQuery get _query => AdminUsersQuery(
        search: _search,
        limit: _pageSize,
        offset: _offset,
      );

  void _refresh() {
    ref.invalidate(adminDashboardProvider);
    ref.invalidate(adminUsersProvider(_query));
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final usersAsync = ref.watch(adminUsersProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text(KiamiStrings.adminTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: kiamiScrollPadding(
            context,
            left: 16,
            top: 16,
            right: 16,
            bottomExtra: 24,
          ),
          children: [
            statsAsync.when(
              data: (s) => _OverviewSection(stats: s),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorText(error: e),
            ),
            const SizedBox(height: 8),
            const AdminCloudflareUsageSection(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(KiamiRoutes.adminSubscriptions),
                icon: const Icon(Icons.subscriptions_outlined, size: 18),
                label: const Text(KiamiStrings.adminViewSubscriptions),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: KiamiStrings.adminSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _search != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _search = null;
                            _offset = 0;
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => setState(() {
                _search = v.trim().isEmpty ? null : v.trim();
                _offset = 0;
              }),
            ),
            const SizedBox(height: 12),
            Text(
              KiamiStrings.adminUsersTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            usersAsync.when(
              data: (data) => Column(
                children: [
                  ...data.users.map((u) => _UserListTile(user: u)),
                  if (data.total > _pageSize)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _offset > 0
                                ? () => setState(
                                      () => _offset = (_offset - _pageSize)
                                          .clamp(0, 99999),
                                    )
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '${_offset + 1}–${(_offset + data.users.length).clamp(0, data.total)} / ${data.total}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            onPressed: _offset + _pageSize < data.total
                                ? () =>
                                    setState(() => _offset += _pageSize)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorText(error: e),
            ),
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
                  onTap: stats.pendingCheckoutsCount > 0
                      ? () => context.push(KiamiRoutes.adminCheckouts)
                      : null,
                ),
              ),
            ],
          ),
        ),
        if (stats.pendingCheckoutsCount > 0) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push(KiamiRoutes.adminCheckouts),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text(KiamiStrings.adminViewPendingPayments),
          ),
        ],
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Card(
      elevation: highlight ? 1 : 0,
      color: highlight
          ? KiamiColors.primaryBlue.withValues(alpha: 0.08)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
    return child;
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.user});

  final KiamiAdminUser user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName ?? user.email ?? user.uid;
    final subtitle = user.displayName != null && user.email != null
        ? user.email!
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: user.hasPendingNotifications
          ? KiamiColors.primaryBlue.withValues(alpha: 0.06)
          : null,
      child: ListTile(
        leading: user.hasPendingNotifications
            ? Badge(
                label: Text('${user.pendingNotificationsCount}'),
                child: Icon(
                  user.hasPendingCheckouts
                      ? Icons.payment_outlined
                      : Icons.support_agent_outlined,
                ),
              )
            : null,
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${formatBytes(user.storageUsedBytes)} / ${formatBytes(user.quotaBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: user.storageUsageFraction,
                minHeight: 4,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(KiamiRoutes.adminUserFor(user.uid)),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(kiamiApiErrorMessage(error)),
    );
  }
}
