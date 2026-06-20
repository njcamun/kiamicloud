import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../api/models/kiami_file.dart';
import '../../constants/kiami_strings.dart';
import '../../utils/format_bytes.dart';
import '../../utils/kiami_platform.dart';
import '../files/providers/files_providers.dart';
import 'device_backup_access.dart';
import 'device_backup_service.dart';

Future<void> _dismissRootDialog(
  BuildContext context,
  Future<void>? dialogFuture,
) async {
  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
  if (dialogFuture != null) {
    await dialogFuture;
  }
}

String _formatBackupStamp(String stamp) {
  final normalized = stamp.replaceFirstMapped(
    RegExp(r'T(\d{2})-(\d{2})-(\d{2})$'),
    (m) => 'T${m[1]}:${m[2]}:${m[3]}',
  );
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    final local = parsed.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }
  return stamp.replaceAll('T', ' ').replaceAll('-', ':');
}

/// Lista back-ups na cloud e restaura no dispositivo (Android).
Future<void> runDeviceRestoreFlow(BuildContext context, WidgetRef ref) async {
  if (!kiamiDeviceBackupSupported()) return;
  if (!await ensureDeviceBackupPlanAccess(context, ref)) return;
  if (!context.mounted) return;

  final files = ref.read(kiamiFilesProvider).valueOrNull ?? const <KiamiFile>[];
  final sets = groupKiamiBackupFiles(files);

  if (!context.mounted) return;
  if (sets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(KiamiStrings.deviceRestoreNoBackups)),
    );
    return;
  }

  final selected = await showDialog<DeviceBackupSet>(
    context: context,
    builder: (ctx) => _BackupSetPickerDialog(sets: sets),
  );
  if (selected == null || !context.mounted) return;

  final scope = selected.scope;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.restore_outlined),
      title: const Text(KiamiStrings.deviceRestoreConfirmTitle),
      content: Text(
        KiamiStrings.deviceRestoreConfirmBody(
          stamp: _formatBackupStamp(selected.stamp),
          hasContacts: selected.hasContacts,
          hasApps: selected.hasApps,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(KiamiStrings.deviceRestoreConfirmStart),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;

  final progressNotifier = ValueNotifier<DeviceBackupProgress>(
    const DeviceBackupProgress(
      fraction: 0,
      label: KiamiStrings.deviceRestorePreparing,
    ),
  );

  var progressVisible = false;
  var progressClosed = false;
  if (!context.mounted) {
    progressNotifier.dispose();
    return;
  }

  progressVisible = true;
  final progressDialogFuture = showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => _RestoreProgressDialog(notifier: progressNotifier),
  );
  await SchedulerBinding.instance.endOfFrame;

  final service = DeviceBackupService();
  final api = ref.read(kiamiApiClientProvider);
  File? appsZipFile;

  Future<void> closeProgress() async {
    if (!progressVisible) return;
    progressVisible = false;
    progressClosed = true;
    await _dismissRootDialog(context, progressDialogFuture);
    progressNotifier.dispose();
  }

  try {
    final permitted = await service.ensureRestorePermissions(scope);
    if (!permitted) {
      await closeProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(KiamiStrings.deviceRestorePermissionDenied),
        ),
      );
      return;
    }

    List<int>? contactsBytes;

    if (selected.hasContacts) {
      if (!progressClosed) {
        progressNotifier.value = const DeviceBackupProgress(
          fraction: 0.02,
          label: KiamiStrings.deviceRestoreDownloadingContacts,
        );
      }
      contactsBytes = await api.downloadFileBytes(selected.contactsFile!.id);
    }
    if (selected.hasApps) {
      if (!progressClosed) {
        progressNotifier.value = DeviceBackupProgress(
          fraction: selected.hasContacts ? 0.08 : 0.02,
          label: KiamiStrings.deviceRestoreDownloadingApps,
        );
      }
      final appsBytes = await api.downloadFileBytes(selected.appsFile!.id);
      final tmp = await getTemporaryDirectory();
      appsZipFile = File(
        p.join(tmp.path, 'kiami_restore_apps_${selected.stamp}.zip'),
      );
      await appsZipFile.writeAsBytes(appsBytes, flush: true);
    }

    final result = await service.restore(
      scope: scope,
      contactsBytes: contactsBytes,
      appsZipFile: appsZipFile,
      onProgress: (p) {
        if (progressClosed) return;
        progressNotifier.value = p;
      },
      onBeforeApkInstall: (current, total) async {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(KiamiStrings.deviceRestoreApkContinueTitle),
            content: Text(
              current > 1
                  ? KiamiStrings.deviceRestoreApkContinueBody(current, total)
                  : KiamiStrings.deviceRestoreApkFirstBody(total),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(KiamiStrings.deviceRestoreApkContinue),
              ),
            ],
          ),
        );
      },
    );

    await closeProgress();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: Theme.of(ctx).colorScheme.primary,
          size: 40,
        ),
        title: const Text(KiamiStrings.deviceRestoreSuccessTitle),
        content: Text(
          KiamiStrings.deviceRestoreSuccessBody(
            contacts: result.contactsRestored,
            apks: result.apksQueued,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(KiamiStrings.okButton),
          ),
        ],
      ),
    );
  } catch (e) {
    await closeProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(KiamiStrings.deviceRestoreFailed(e.toString()))),
    );
  } finally {
    final zip = appsZipFile;
    if (zip != null && await zip.exists()) {
      try {
        await zip.delete();
      } catch (_) {
        // Ignora falha ao limpar ficheiro temporário.
      }
    }
  }
}

class _BackupSetPickerDialog extends StatelessWidget {
  const _BackupSetPickerDialog({required this.sets});

  final List<DeviceBackupSet> sets;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(KiamiStrings.deviceRestorePickTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: sets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final set = sets[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text(_formatBackupStamp(set.stamp)),
              subtitle: Text(_setSubtitle(set)),
              onTap: () => Navigator.pop(context, set),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(KiamiStrings.cancelButton),
        ),
      ],
    );
  }

  String _setSubtitle(DeviceBackupSet set) {
    final parts = <String>[];
    if (set.hasContacts) {
      parts.add(
        '${KiamiStrings.deviceBackupScopeContacts} '
        '(${formatBytes(set.contactsFile!.sizeBytes)})',
      );
    }
    if (set.hasApps) {
      parts.add(
        '${KiamiStrings.deviceBackupScopeApps} '
        '(${formatBytes(set.appsFile!.sizeBytes)})',
      );
    }
    return parts.join(' · ');
  }
}

class _RestoreProgressDialog extends StatelessWidget {
  const _RestoreProgressDialog({required this.notifier});

  final ValueNotifier<DeviceBackupProgress> notifier;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text(KiamiStrings.deviceRestoreProgressTitle),
        content: ValueListenableBuilder<DeviceBackupProgress>(
          valueListenable: notifier,
          builder: (context, progress, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  progress.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress.fraction),
                const SizedBox(height: 8),
                Text(
                  '${(progress.fraction * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  KiamiStrings.deviceRestoreWaitHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
