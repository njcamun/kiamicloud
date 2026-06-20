import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/kiami_api_config.dart';
import '../../../api/models/kiami_admin.dart';
import '../../../api/models/kiami_plan.dart';
import '../../../constants/kiami_strings.dart';
import '../../../utils/format_bytes.dart';
import '../../files/providers/files_providers.dart';

const _mb = 1024 * 1024;
const _gb = 1024 * 1024 * 1024;
const _transferPresetsMb = [15, 75, 150, 300];
const _transferMaxMb = 300;

/// Formulário de edição de plano, armazenamento e transferência (ecrã de detalhe).
class AdminUserEditForm extends ConsumerStatefulWidget {
  const AdminUserEditForm({
    super.key,
    required this.user,
    required this.plans,
    required this.onSaved,
  });

  final KiamiAdminUser user;
  final List<KiamiPlan> plans;
  final ValueChanged<KiamiAdminUser> onSaved;

  @override
  ConsumerState<AdminUserEditForm> createState() => _AdminUserEditFormState();
}

class _AdminUserEditFormState extends ConsumerState<AdminUserEditForm> {
  late String _selectedPlan;
  late bool _customStorage;
  late int _storageBytes;
  late bool _customTransfer;
  late int _transferBytes;
  late bool _canSwitchApiEndpoint;
  bool _saving = false;

  KiamiPlan? get _plan =>
      widget.plans.where((p) => p.code == _selectedPlan).firstOrNull;

  @override
  void initState() {
    super.initState();
    _syncFromUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant AdminUserEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid ||
        oldWidget.user.updatedAt != widget.user.updatedAt) {
      _syncFromUser(widget.user);
    }
  }

  void _syncFromUser(KiamiAdminUser user) {
    _selectedPlan = user.planCode;
    _storageBytes = user.quotaBytes;
    _customStorage = user.hasQuotaOverride;
    _customTransfer = user.hasTransferOverride;
    _transferBytes = user.hasTransferOverride
        ? user.transferOverrideBytes!
        : user.maxFileSizeBytes;
    _canSwitchApiEndpoint = user.canSwitchApiEndpoint;
  }

  int get _planTransferBytes =>
      _plan?.maxFileSizeBytes ?? widget.user.planMaxFileSizeBytes;

  int get _planQuotaBytes => _plan?.quotaBytes ?? widget.user.planQuotaBytes;

  bool get _limitsEnforced => KiamiApiConfig.isCloudEndpoint;

  int get _expectedStorageBytes => _limitsEnforced
      ? (_customStorage
          ? _storageBytes
          : (_plan?.quotaBytes ?? widget.user.planQuotaBytes))
      : widget.user.quotaBytes;

  int get _expectedTransferBytes => _limitsEnforced
      ? (_customTransfer ? _transferBytes : _planTransferBytes)
      : 0;

  bool get _switchChanged =>
      _canSwitchApiEndpoint != widget.user.canSwitchApiEndpoint;

  bool? get _switchParam => _switchChanged ? _canSwitchApiEndpoint : null;

  bool get _hasChanges {
    final planChanged = _selectedPlan != widget.user.planCode;
    if (!_limitsEnforced) {
      return planChanged || _switchChanged;
    }
    final storageChanged = _customStorage != widget.user.hasQuotaOverride ||
        (_customStorage &&
            _storageBytes !=
                (widget.user.quotaOverrideBytes ?? widget.user.quotaBytes));
    final transferChanged = _customTransfer != widget.user.hasTransferOverride ||
        (_customTransfer &&
            _transferBytes !=
                (widget.user.transferOverrideBytes ??
                    widget.user.maxFileSizeBytes));
    return planChanged || storageChanged || transferChanged || _switchChanged;
  }

  Future<void> _save() async {
    if (!_hasChanges || _saving) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(kiamiApiClientProvider);
      final expectedStorage = _expectedStorageBytes;
      final expectedTransfer = _expectedTransferBytes;

      // planCode só quando mudou — evita "Nada para actualizar" após sucesso parcial.
      final updated = await api.updateAdminUser(
        uid: widget.user.uid,
        planCode: _selectedPlan != widget.user.planCode ? _selectedPlan : null,
        quotaBytesOverride:
            _limitsEnforced && _customStorage ? _storageBytes : null,
        clearQuotaOverride: _limitsEnforced &&
            !_customStorage &&
            widget.user.hasQuotaOverride,
        maxFileSizeBytesOverride:
            _limitsEnforced && _customTransfer ? _transferBytes : null,
        clearTransferOverride: _limitsEnforced &&
            !_customTransfer &&
            widget.user.hasTransferOverride,
        canSwitchApiEndpoint: _switchParam,
      );

      if (!mounted) return;
      final storageOk =
          !_limitsEnforced || updated.quotaBytes == expectedStorage;
      final transferOk = !_limitsEnforced ||
          updated.maxFileSizeBytes == expectedTransfer;
      setState(() => _syncFromUser(updated));
      widget.onSaved(updated);
      final msg = storageOk && transferOk
          ? KiamiStrings.adminUserUpdated
          : KiamiStrings.adminUserUpdatedMismatch(
              formatBytes(updated.quotaBytes),
              formatBytes(expectedStorage),
              formatBytes(updated.maxFileSizeBytes),
              formatBytes(expectedTransfer),
            );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = widget.user.storageUsedBytes;
    final capacity = _limitsEnforced
        ? (_customStorage ? _storageBytes : _planQuotaBytes)
        : null;
    final usageRatio = capacity != null && capacity > 0
        ? (used / capacity).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedPlan,
          decoration: const InputDecoration(
            labelText: KiamiStrings.adminPlanLabel,
          ),
          items: widget.plans
              .map(
                (p) => DropdownMenuItem(value: p.code, child: Text(p.name)),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _selectedPlan = v;
              if (!_customStorage) _storageBytes = _planQuotaBytes;
              if (!_customTransfer) _transferBytes = _planTransferBytes;
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          KiamiStrings.adminStorageSection,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          label: KiamiStrings.adminStorageInUse,
          value: _limitsEnforced
              ? '${formatBytes(used)} / ${formatBytes(capacity!)}'
              : '${formatBytes(used)} · ${KiamiStrings.noTransferLimit}',
        ),
        if (_limitsEnforced) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usageRatio,
              minHeight: 8,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '${widget.user.filesCount} ${KiamiStrings.adminUserFiles.toLowerCase()}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (!_limitsEnforced)
          Text(
            KiamiStrings.adminLocalUnlimitedHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(KiamiStrings.adminStorageCustom),
            subtitle: Text(
              _customStorage
                  ? formatBytes(_storageBytes)
                  : '${KiamiStrings.adminStoragePlanDefault}: ${formatBytes(_planQuotaBytes)}',
            ),
            value: _customStorage,
            onChanged: (v) {
              setState(() {
                _customStorage = v;
                if (v) {
                  _storageBytes = widget.user.hasQuotaOverride
                      ? widget.user.quotaOverrideBytes!
                      : widget.user.quotaBytes;
                }
              });
            },
          ),
          if (_customStorage) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                const maxGb = 500;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [20, 40, 80, 150, 320, 500].map((gb) {
                        final bytes = gb * _gb;
                        return FilterChip(
                          label: Text('$gb GB'),
                          selected: _storageBytes == bytes,
                          onSelected: (_) =>
                              setState(() => _storageBytes = bytes),
                        );
                      }).toList(),
                    ),
                    Slider(
                      value: (_storageBytes / _gb)
                          .clamp(5, maxGb.toDouble())
                          .toDouble(),
                      min: 5,
                      max: maxGb.toDouble(),
                      divisions: maxGb - 5,
                      label: formatBytes(_storageBytes),
                      onChanged: (v) =>
                          setState(() => _storageBytes = v.round() * _gb),
                    ),
                    Center(
                      child: Text(
                        formatBytes(_storageBytes),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: KiamiStrings.adminStorageCapacity,
              value: formatBytes(_planQuotaBytes),
            ),
            const SizedBox(height: 4),
            Text(
              KiamiStrings.adminStorageReadOnlyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        if (_limitsEnforced) ...[
          const SizedBox(height: 20),
          Text(
            KiamiStrings.adminTransferSection,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(KiamiStrings.adminTransferCustom),
            subtitle: Text(
              _customTransfer
                  ? formatBytes(_transferBytes)
                  : '${KiamiStrings.adminTransferPlanDefault}: ${formatBytes(_planTransferBytes)}',
            ),
            value: _customTransfer,
            onChanged: (v) {
              setState(() {
                _customTransfer = v;
                if (v) {
                  _transferBytes = widget.user.hasTransferOverride
                      ? widget.user.transferOverrideBytes!
                      : widget.user.maxFileSizeBytes;
                }
              });
            },
          ),
          if (_customTransfer) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _transferPresetsMb.map((mb) {
                final bytes = mb * _mb;
                return FilterChip(
                  label: Text('$mb MB'),
                  selected: _transferBytes == bytes,
                  onSelected: (_) => setState(() => _transferBytes = bytes),
                );
              }).toList(),
            ),
            Slider(
              value: (_transferBytes / _mb)
                  .clamp(5, _transferMaxMb.toDouble())
                  .toDouble(),
              min: 5,
              max: _transferMaxMb.toDouble(),
              divisions: 59,
              label: formatBytes(_transferBytes),
              onChanged: (v) => setState(() => _transferBytes = v.round() * _mb),
            ),
            Center(
              child: Text(
                formatBytes(_transferBytes),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        Text(
          KiamiStrings.settingsServerTitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(KiamiStrings.adminCanSwitchServer),
          subtitle: const Text(KiamiStrings.adminCanSwitchServerHint),
          value: _canSwitchApiEndpoint,
          onChanged: (v) => setState(() => _canSwitchApiEndpoint = v),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: !_hasChanges || _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(KiamiStrings.adminSave),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
