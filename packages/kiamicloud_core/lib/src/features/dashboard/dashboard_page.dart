import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/kiami_routes.dart';

import '../../constants/kiami_constants.dart';
import '../../constants/kiami_strings.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/file_category.dart';
import '../../widgets/file_category_grid.dart';
import '../files/presentation/file_list_actions.dart';
import '../../utils/format_bytes.dart';
import '../../theme/kiami_decorations.dart';
import '../../widgets/global_file_search.dart';
import '../../widgets/upload_drop_target.dart';
import '../../widgets/upload_queue_panel.dart';
import '../upload/upload_files_handler.dart';
import '../upload/upload_queue.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/kiami_page_header.dart';
import '../../widgets/kiami_upload_zone.dart';
import '../../widgets/quota_banner.dart';
import '../../widgets/quota_limit_dialog.dart';
import '../../utils/kiami_support_contact.dart';
import '../../utils/kiami_layout.dart';
import '../../utils/kiami_platform.dart';
import '../../utils/kiami_api_limits.dart';
import '../../utils/quota_ui.dart';
import '../activity/providers/profile_quota_sync_provider.dart';
import '../backup/device_backup_flow.dart';
import '../backup/device_backup_restore_flow.dart';
import '../files/providers/files_providers.dart';
import '../../api/models/kiami_file.dart';
import '../../api/models/kiami_profile.dart';

/// Dashboard — quota, upload e grelha de categorias.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with KiamiFileListActions {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshKiamiProfile(ref);
    });
  }

  Future<void> _showQuotaBlockedDialog(KiamiProfile profile) {
    return showQuotaLimitDialog(
      context,
      title: KiamiStrings.quotaLimitDialogTitle,
      message: KiamiStrings.quotaUploadBlocked,
      availableBytes: profile.storageAvailableBytes,
    );
  }

  Future<void> _showFileExceedsQuotaDialog({
    required KiamiProfile profile,
    required String fileName,
    int? fileSizeBytes,
  }) {
    return showQuotaLimitDialog(
      context,
      title: KiamiStrings.quotaLimitDialogTitle,
      message: KiamiStrings.quotaFileTooBigForQuotaDetail,
      fileSizeBytes: fileSizeBytes,
      availableBytes: profile.storageAvailableBytes,
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
        withReadStream: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      await _handlePickedFiles(picked.files);
    } catch (e) {
      if (!mounted) return;
      showKiamiMessage(kiamiApiErrorMessage(e));
    }
  }

  Future<void> _handlePickedFiles(List<PlatformFile> files) async {
    await handleFilesForUpload(
      context: context,
      ref: ref,
      pickedFiles: files,
      onQuotaBlocked: _showQuotaBlockedDialog,
      onFileExceedsQuota: ({
        required profile,
        required fileName,
        fileSizeBytes,
      }) =>
          _showFileExceedsQuotaDialog(
        profile: profile,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
      ),
      showMessage: showKiamiMessage,
    );
  }

  String _headerTitle(KiamiProfile? profile) {
    final name = profile?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return '${KiamiStrings.dashboardGreeting}, $name';
    }
    return KiamiStrings.dashboardTitle;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileQuotaSyncProvider);
    final profileAsync = ref.watch(kiamiProfileProvider);
    final filesAsync = ref.watch(kiamiFilesProvider);
    final queueState = ref.watch(uploadQueueProvider);
    final allFiles = filesAsync.valueOrNull ?? const <KiamiFile>[];
    final isWide = kiamiIsWideLayout(context);
    final isNativeDesktop = kiamiIsNativeDesktop();
    final hPad = kiamiContentHorizontalPadding(context);
    final primaryMaxW = kiamiDashboardPrimaryMaxWidth(context);
    final fixedStorageOnMobile = !isWide;
    final profile = profileAsync.valueOrNull;

    return GlobalFileSearchLauncher(
      files: allFiles,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KiamiPageHeader(
          largeTitle: !isWide,
          title: isWide
              ? KiamiStrings.dashboardTitle
              : profileAsync.when(
                      data: (p) => _headerTitle(p),
                      loading: () => KiamiStrings.dashboardTitle,
                      error: (_, __) => KiamiStrings.dashboardTitle,
                    ),
          actions: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: KiamiStrings.storageSupportTooltip,
              icon: const Icon(Icons.support_agent_outlined),
              onPressed: () => showSupportContactDialog(context),
            ),
            if (!isWide && kiamiDeviceBackupSupported())
              PopupMenuButton<_DeviceBackupAction>(
                tooltip: KiamiStrings.deviceBackupTooltip,
                icon: const Icon(Icons.backup_outlined),
                onSelected: (action) {
                  switch (action) {
                    case _DeviceBackupAction.backup:
                      runDeviceBackupFlow(context, ref);
                    case _DeviceBackupAction.restore:
                      runDeviceRestoreFlow(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _DeviceBackupAction.backup,
                    child: ListTile(
                      leading: Icon(Icons.cloud_upload_outlined),
                      title: Text(KiamiStrings.deviceBackupMenuBackup),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuItem(
                    value: _DeviceBackupAction.restore,
                    child: ListTile(
                      leading: Icon(Icons.restore_outlined),
                      title: Text(KiamiStrings.deviceBackupMenuRestore),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              )
            else
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: refreshKiamiFiles,
              ),
            if (!isWide)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: KiamiStrings.navSettings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(KiamiRoutes.settings),
              ),
          ],
        ),
        if (fixedStorageOnMobile && profile != null)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: primaryMaxW ?? double.infinity,
                ),
                child: _StorageCard(
                  profile: profile,
                ),
              ),
            ),
          )
        else if (fixedStorageOnMobile && profileAsync.isLoading)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _StorageCardSkeleton(),
          ),
        Expanded(
          child: RefreshIndicator(
                onRefresh: refreshKiamiFiles,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: primaryMaxW ?? double.infinity,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                profileAsync.when(
                                  data: (p) => _DashboardTopSection(
                                    profile: p,
                                    queueProcessing: queueState.isProcessing,
                                    fullWidthUpload:
                                        isNativeDesktop && isWide,
                                    fixedStorageCard: fixedStorageOnMobile,
                                    onPickUpload: _pickAndUpload,
                                    onFilesDropped: _handlePickedFiles,
                                    maxPerFileLabel:
                                        formatTransferLimit(p.maxFileSizeBytes),
                                  ),
                                  loading: () => fixedStorageOnMobile
                                      ? const SizedBox.shrink()
                                      : const _StorageCardSkeleton(),
                                  error: (e, _) => KiamiApiUnavailableCard(
                                    error: e,
                                    compact: true,
                                    onRetry: refreshKiamiFiles,
                                  ),
                                ),
                                const UploadQueuePanel(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              filesAsync.when(
                data: (allFiles) {
                  if (allFiles.isEmpty) {
                    final profile =
                        ref.watch(kiamiProfileProvider).valueOrNull;
                    final maxLabel = formatTransferLimit(
                      profile?.maxFileSizeBytes ??
                          KiamiConstants.maxUploadBytes,
                    );
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: _EmptyState(maxPerFileLabel: maxLabel),
                      ),
                    );
                  }

                  final grouped = groupFilesByCategory(allFiles);

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
                          child: FileCategoryGrid(
                            grouped: grouped,
                            onCategoryTap: (category) => context.push(
                              KiamiRoutes.categoryFilesFor(category),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
                          child: Text(
                            KiamiStrings.categorySelectHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: KiamiApiUnavailableCard(
                      error: e,
                      onRetry: refreshKiamiFiles,
                    ),
                  ),
                ),
              ),
              const KiamiScrollBottomSpacer(),
            ],
          ),
        ),
        ),
      ],
      ),
    );
  }
}

class _DashboardTopSection extends StatelessWidget {
  const _DashboardTopSection({
    required this.profile,
    required this.queueProcessing,
    required this.fullWidthUpload,
    required this.fixedStorageCard,
    required this.onPickUpload,
    required this.onFilesDropped,
    required this.maxPerFileLabel,
  });

  final KiamiProfile profile;
  final String maxPerFileLabel;
  final bool queueProcessing;
  final bool fullWidthUpload;
  final bool fixedStorageCard;
  final VoidCallback onPickUpload;
  final Future<void> Function(List<PlatformFile> files) onFilesDropped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (KiamiApiLimits.enforced)
            QuotaBanner(
              quota: profile.quota,
              storageUsedBytes: profile.storageUsedBytes,
              quotaBytes: profile.plan.quotaBytes,
              storageAvailableBytes: profile.storageAvailableBytes,
              onUpgrade: () => context.push(KiamiRoutes.billing),
            ),
          if (!fixedStorageCard) ...[
            _StorageCard(
              profile: profile,
              expanded: fullWidthUpload,
            ),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final cardWidth = fullWidthUpload
                  ? maxW.clamp(480.0, 1200.0)
                  : null;

              return UploadDropTarget(
                enabled: !queueProcessing,
                onFilesDropped: onFilesDropped,
                child: KiamiUploadZone(
                  isLoading: queueProcessing,
                  enabled: !queueProcessing,
                  onTap: onPickUpload,
                  progressCurrent: 0,
                  progressTotal: 0,
                  cardWidth: cardWidth,
                  maxPerFileLabel: maxPerFileLabel,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.profile,
    this.expanded = false,
  });

  final KiamiProfile profile;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final used = profile.storageUsedBytes;
    final unlimited = !KiamiApiLimits.enforced;
    final quotaBytes = profile.plan.quotaBytes;
    final ratio = unlimited
        ? 0.0
        : (quotaBytes > 0 ? (used / quotaBytes).clamp(0.0, 1.0) : 0.0);
    final percent = profile.quota.usagePercent.toStringAsFixed(1);
    final barColor = QuotaUi.barColor(profile.quota.status);
    final planLabel = profile.plan.name;

    final narrow = MediaQuery.sizeOf(context).width < 400;
    return KiamiCard(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 24 : (narrow ? 14 : 16),
        vertical: expanded ? 22 : (narrow ? 16 : 18),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: barColor, size: expanded ? 26 : 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    KiamiStrings.storageUsed,
                    style: (expanded
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KiamiColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    planLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KiamiColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!unlimited)
              ClipRRect(
                borderRadius: BorderRadius.circular(KiamiDecorations.radiusSm),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('${profile.plan.code}-$quotaBytes'),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: ratio),
                  builder: (context, value, _) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return LinearProgressIndicator(
                      value: value > 0 ? value : null,
                      minHeight: expanded ? 12 : 10,
                      backgroundColor: isDark
                          ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
                          : KiamiColors.lightGray,
                      color: barColor,
                    );
                  },
                ),
              ),
            if (!unlimited) const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  unlimited
                      ? '${formatBytes(used)} · ${KiamiStrings.noTransferLimit}'
                      : '${formatBytes(used)} / ${formatBytes(quotaBytes)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!unlimited)
                  Text(
                    '$percent% ${KiamiStrings.storagePercent}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
    );
  }
}

class _StorageCardSkeleton extends StatelessWidget {
  const _StorageCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const KiamiCard(
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.maxPerFileLabel});

  final String maxPerFileLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? KiamiColors.darkSurfaceElevated
                : KiamiColors.softWhite,
            boxShadow: [
              BoxShadow(
                color: KiamiColors.primaryBlue.withValues(alpha: 0.12),
                blurRadius: 32,
              ),
            ],
          ),
          child: const Icon(
            Icons.cloud_outlined,
            size: 56,
            color: KiamiColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          KiamiStrings.dashboardEmpty,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            KiamiStrings.dashboardEmptyHint(maxPerFileLabel),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

enum _DeviceBackupAction { backup, restore }
