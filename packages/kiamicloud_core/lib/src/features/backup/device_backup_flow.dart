import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../../utils/kiami_platform.dart';
import '../files/providers/files_providers.dart';
import 'device_backup_service.dart';

/// Fecha o diálogo no root navigator sem rebentar `!_debugLocked`.
Future<void> _popRootDialog(BuildContext context) async {
  if (!context.mounted) return;
  await SchedulerBinding.instance.endOfFrame;
  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

/// Inicia o fluxo de back-up (Android apenas).
Future<void> runDeviceBackupFlow(BuildContext context, WidgetRef ref) async {
  if (!kiamiDeviceBackupSupported()) return;

  final waitOk = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.backup_outlined),
      title: const Text(KiamiStrings.deviceBackupConfirmTitle),
      content: const Text(KiamiStrings.deviceBackupConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(KiamiStrings.deviceBackupConfirmStart),
        ),
      ],
    ),
  );
  if (waitOk != true || !context.mounted) return;

  final scope = await showDialog<DeviceBackupScope>(
    context: context,
    builder: (ctx) => const _BackupScopeDialog(),
  );
  if (scope == null || !context.mounted) return;

  final progressNotifier = ValueNotifier<DeviceBackupProgress>(
    const DeviceBackupProgress(
      fraction: 0,
      label: KiamiStrings.deviceBackupPreparing,
    ),
  );

  var progressVisible = false;
  if (!context.mounted) {
    progressNotifier.dispose();
    return;
  }

  progressVisible = true;
  // Não await — o diálogo fica aberto durante o back-up.
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => _BackupProgressDialog(notifier: progressNotifier),
  );
  await SchedulerBinding.instance.endOfFrame;

  final service = DeviceBackupService();
  final api = ref.read(kiamiApiClientProvider);

  Future<void> closeProgress() async {
    if (!progressVisible) return;
    progressVisible = false;
    await _popRootDialog(context);
    progressNotifier.dispose();
  }

  try {
    final permitted = await service.ensurePermissions(scope);
    if (!permitted) {
      await closeProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.deviceBackupPermissionDenied)),
      );
      return;
    }

    await service.run(
      scope: scope,
      onProgress: (p) {
        if (!progressVisible) return;
        progressNotifier.value = p;
      },
      upload: (name, bytes) async {
        await api.uploadFile(name: name, bytes: bytes);
      },
    );

    await closeProgress();
    if (!context.mounted) return;

    ref.invalidate(kiamiFilesProvider);
    ref.invalidate(kiamiProfileProvider);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: Theme.of(ctx).colorScheme.primary,
          size: 40,
        ),
        title: const Text(KiamiStrings.deviceBackupSuccessTitle),
        content: const Text(KiamiStrings.deviceBackupSuccessBody),
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
      SnackBar(content: Text(KiamiStrings.deviceBackupFailed(e.toString()))),
    );
  }
}

class _BackupScopeDialog extends StatefulWidget {
  const _BackupScopeDialog();

  @override
  State<_BackupScopeDialog> createState() => _BackupScopeDialogState();
}

class _BackupScopeDialogState extends State<_BackupScopeDialog> {
  DeviceBackupScope _scope = DeviceBackupScope.both;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(KiamiStrings.deviceBackupScopeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScopeOption(
            label: KiamiStrings.deviceBackupScopeContacts,
            selected: _scope == DeviceBackupScope.contacts,
            onTap: () => setState(() => _scope = DeviceBackupScope.contacts),
          ),
          _ScopeOption(
            label: KiamiStrings.deviceBackupScopeApps,
            selected: _scope == DeviceBackupScope.apps,
            onTap: () => setState(() => _scope = DeviceBackupScope.apps),
          ),
          _ScopeOption(
            label: KiamiStrings.deviceBackupScopeBoth,
            selected: _scope == DeviceBackupScope.both,
            onTap: () => setState(() => _scope = DeviceBackupScope.both),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _scope),
          child: const Text(KiamiStrings.deviceBackupScopeConfirm),
        ),
      ],
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _BackupProgressDialog extends StatelessWidget {
  const _BackupProgressDialog({required this.notifier});

  final ValueNotifier<DeviceBackupProgress> notifier;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text(KiamiStrings.deviceBackupProgressTitle),
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
                  KiamiStrings.deviceBackupWaitHint,
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
