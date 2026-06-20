import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../../utils/kiami_layout.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';
import 'widgets/admin_user_list_tile.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
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
    ref.invalidate(adminUsersProvider(_query));
    ref.invalidate(adminStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text(KiamiStrings.adminUsersTitle),
        actions: [
          IconButton(
            tooltip: KiamiStrings.adminRetry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kiamiScrollPadding(
            context,
            left: 16,
            top: 12,
            right: 16,
            bottomExtra: 24,
          ),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: KiamiStrings.adminSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _search != null
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
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
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() {
                _search = v.trim().isEmpty ? null : v.trim();
                _offset = 0;
              }),
            ),
            const SizedBox(height: 16),
            usersAsync.when(
              data: (data) {
                if (data.users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        KiamiStrings.adminUsersEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${data.total} ${data.total == 1 ? KiamiStrings.adminUserSingular : KiamiStrings.adminUsersTitle.toLowerCase()}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    for (final user in data.users) AdminUserListTile(user: user),
                    if (data.total > _pageSize) _PaginationBar(
                      offset: _offset,
                      pageSize: _pageSize,
                      total: data.total,
                      pageCount: data.users.length,
                      onPrevious: _offset > 0
                          ? () => setState(
                                () => _offset =
                                    (_offset - _pageSize).clamp(0, 99999),
                              )
                          : null,
                      onNext: _offset + _pageSize < data.total
                          ? () => setState(() => _offset += _pageSize)
                          : null,
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      kiamiApiErrorMessage(e),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(KiamiStrings.adminRetry),
                    ),
                  ],
                ),
              ),
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
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int offset;
  final int pageSize;
  final int total;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${offset + 1}–${(offset + pageCount).clamp(0, total)} / $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
