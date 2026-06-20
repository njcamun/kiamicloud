import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/kiami_routes.dart';

import '../../constants/kiami_constants.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/file_category.dart';
import '../../widgets/file_category_grid.dart';
import '../files/presentation/file_list_actions.dart';
import '../../utils/format_bytes.dart';
import '../../theme/kiami_spacing.dart';
import '../../widgets/global_file_search.dart';
import '../../widgets/upload_drop_target.dart';
import '../../widgets/upload_queue_panel.dart';
import '../upload/upload_files_handler.dart';
import '../upload/upload_queue.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/kiami_empty_state.dart';
import '../../widgets/kiami_loading_skeleton.dart';
import '../../widgets/kiami_page_header.dart';
import '../../widgets/kiami_storage_card.dart';
import '../../widgets/kiami_upload_zone.dart';
import '../../widgets/quota_banner.dart';
import '../../widgets/subscription_banner.dart';
import '../../widgets/quota_limit_dialog.dart';
import '../activity/account_notifications_popup.dart';
import '../../utils/kiami_support_contact.dart';
import '../../utils/kiami_layout.dart';
import '../../utils/kiami_platform.dart';
import '../../utils/kiami_web_file_picker.dart';
import '../../utils/kiami_api_limits.dart';
import '../activity/providers/profile_quota_sync_provider.dart';
import '../backup/device_backup_flow.dart';
import '../backup/device_backup_restore_flow.dart';
import '../files/providers/files_providers.dart';
import '../connectivity/connectivity_provider.dart';
import '../../widgets/kiami_unavailable.dart';
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
      final List<PlatformFile> files;
      if (kIsWeb) {
        final picked = await pickFilesWithWebInput(allowMultiple: true);
        if (picked == null || picked.isEmpty) return;
        files = picked;
      } else {
        final picked = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          withData: false,
          withReadStream: true,
        );
        if (picked == null || picked.files.isEmpty) return;
        files = picked.files;
      }
      await _handlePickedFiles(files);
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
    final filesAsync = ref.watch(kiamiFilesViewProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final profileConnectionError = profileAsync.hasError &&
        kiamiApiErrorIsConnection(profileAsync.error!);
    final showNoConnectOnUpload = !isOnline || profileConnectionError;
    final queueState = ref.watch(uploadQueueProvider);
    UploadQueueItem? uploadingItem;
    for (final item in queueState.items) {
      if (item.status == UploadQueueItemStatus.uploading) {
        uploadingItem = item;
        break;
      }
    }
    final uploadProgress = uploadingItem?.progress ?? 0.0;
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
            const AccountNotificationsIconButton(),
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
                child: KiamiStorageCard(
                  profile: profile,
                  onHelpTap: () => showKiamiStorageHelp(context),
                ),
              ),
            ),
          )
        else if (fixedStorageOnMobile && profileAsync.isLoading)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: const KiamiStorageCardSkeleton(),
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
                                _DashboardTopSection(
                                  profile: profile,
                                  profileLoading: profileAsync.isLoading,
                                  profileError: profileAsync.hasError,
                                  showNoConnectOnUpload: showNoConnectOnUpload,
                                  queueProcessing: queueState.isProcessing,
                                  uploadProgress: uploadProgress,
                                  fullWidthUpload:
                                      isNativeDesktop && isWide,
                                  fixedStorageCard: fixedStorageOnMobile,
                                  onPickUpload: profileAsync.isLoading
                                      ? () => showKiamiMessage(
                                            KiamiStrings.uploadProfileLoading,
                                          )
                                      : profileAsync.hasError
                                          ? () => showKiamiMessage(
                                                KiamiStrings.apiUnavailableTitle,
                                              )
                                          : _pickAndUpload,
                                  onFilesDropped: profileAsync.isLoading ||
                                          profileAsync.hasError
                                      ? (_) async {}
                                      : _handlePickedFiles,
                                  maxPerFileLabel: formatTransferLimit(
                                    profile?.maxFileSizeBytes ??
                                        KiamiConstants.maxUploadBytes,
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
                        child: KiamiEmptyState(
                          icon: Icons.cloud_outlined,
                          title: KiamiStrings.dashboardEmpty,
                          subtitle: KiamiStrings.dashboardEmptyHint(maxLabel),
                        ),
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
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, KiamiSpacing.lg, hPad, 0),
                    child: KiamiFileGridSkeleton(
                      crossAxisCount: isWide ? 4 : 2,
                    ),
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
    required this.profileLoading,
    required this.profileError,
    required this.showNoConnectOnUpload,
    required this.queueProcessing,
    required this.uploadProgress,
    required this.fullWidthUpload,
    required this.fixedStorageCard,
    required this.onPickUpload,
    required this.onFilesDropped,
    required this.maxPerFileLabel,
  });

  final KiamiProfile? profile;
  final bool profileLoading;
  final bool profileError;
  final bool showNoConnectOnUpload;
  final String maxPerFileLabel;
  final bool queueProcessing;
  final double uploadProgress;
  final bool fullWidthUpload;
  final bool fixedStorageCard;
  final VoidCallback onPickUpload;
  final Future<void> Function(List<PlatformFile> files) onFilesDropped;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final uploadEnabled =
        !queueProcessing && !profileLoading && !profileError && p != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profileLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (p != null && KiamiApiLimits.enforced) ...[
            if (p.access != null)
              SubscriptionBanner(
                access: p.access!,
                onRenew: () => showPlanChangeSupportDialog(context),
              ),
            QuotaBanner(
              quota: p.quota,
              storageUsedBytes: p.storageUsedBytes,
              quotaBytes: p.plan.quotaBytes,
              storageAvailableBytes: p.storageAvailableBytes,
              onUpgrade: () => showPlanChangeSupportDialog(context),
            ),
          ],
          if (p != null && !fixedStorageCard) ...[
            KiamiStorageCard(
              profile: p,
              expanded: fullWidthUpload,
              onHelpTap: () => showKiamiStorageHelp(context),
            ),
            const SizedBox(height: 16),
          ] else if (profileLoading && !fixedStorageCard)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: KiamiStorageCardSkeleton(),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final cardWidth = fullWidthUpload
                  ? maxW.clamp(480.0, 1200.0)
                  : null;

              if (showNoConnectOnUpload) {
                return KiamiUploadIllustrationCard(
                  cardWidth: cardWidth,
                  child: const KiamiNoConnectIllustration(fit: BoxFit.cover),
                );
              }

              return UploadDropTarget(
                enabled: uploadEnabled,
                onFilesDropped: onFilesDropped,
                child: KiamiUploadZone(
                  isLoading: queueProcessing,
                  enabled: uploadEnabled,
                  onTap: onPickUpload,
                  uploadProgress: uploadProgress,
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

enum _DeviceBackupAction { backup, restore }
