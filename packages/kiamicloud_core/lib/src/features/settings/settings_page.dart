import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/kiami_constants.dart';
import '../../constants/kiami_strings.dart';
import '../../api/kiami_api_config.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/admin/providers/admin_ui_eligible_provider.dart';
import '../../features/files/providers/files_providers.dart';
import '../../features/legal/legal_pdf_viewer_page.dart';
import '../../data/admin_access_store.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/kiami_page_header.dart';
import 'providers/api_endpoint_providers.dart';

/// Definições — aparência, privacidade, suporte e conta.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

@Deprecated('Use SettingsPage')
typedef SettingsPlaceholderPage = SettingsPage;

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(adminUiEligibleProvider);
      ref.invalidate(activeApiEndpointProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showAdminSection = ref.watch(adminSettingsSectionProvider);
    final canChangeServer = ref.watch(canSwitchApiEndpointProvider);
    final showBack = kiamiShowsShellBackButton(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KiamiPageHeader(
          title: KiamiStrings.settingsTitle,
          leading: showBack
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go(KiamiRoutes.home),
                )
              : null,
        ),
        Expanded(
          child: ListView(
            padding: kiamiScrollPadding(
              context,
              left: kiamiSettingsListHorizontalPadding,
              top: 8,
              right: kiamiSettingsListHorizontalPadding,
              bottomExtra: 24,
            ),
            children: [
              Text(
                KiamiStrings.settingsPrivacySection,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              KiamiCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsNavTile(
                      icon: Icons.gavel_outlined,
                      title: KiamiStrings.settingsLegal,
                      onTap: () =>
                          _openLegalDocument(KiamiStrings.legalDocumentTitle),
                      dense: true,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (canChangeServer) ...[
                KiamiCard(
                  padding: EdgeInsets.zero,
                  child: _SettingsNavTile(
                    icon: Icons.dns_outlined,
                    title: KiamiStrings.settingsChangeServer,
                    subtitle: KiamiStrings.settingsChangeServerHint,
                    showDivider: false,
                    onTap: () => context.push(KiamiRoutes.serverSettings),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              KiamiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      KiamiStrings.settingsTheme,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      emptySelectionAllowed: false,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(KiamiStrings.settingsThemeSystem),
                          icon: Icon(Icons.brightness_auto, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(KiamiStrings.settingsThemeLight),
                          icon: Icon(Icons.light_mode_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(KiamiStrings.settingsThemeDark),
                          icon: Icon(Icons.dark_mode_outlined, size: 18),
                        ),
                      ],
                      selected: {widget.themeMode},
                      onSelectionChanged: (s) {
                        if (s.isNotEmpty) widget.onThemeModeChanged(s.first);
                      },
                    ),
                  ],
                ),
              ),
              if (KiamiApiConfig.isLocalApiUrl && showAdminSection) ...[
                const SizedBox(height: 16),
                Text(
                  KiamiStrings.localBladeConsoleSection,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                KiamiCard(
                  padding: EdgeInsets.zero,
                  child: _SettingsNavTile(
                    icon: Icons.dashboard_outlined,
                    title: KiamiStrings.localBladeConsole,
                    subtitle: KiamiStrings.localBladeConsoleHint,
                    showDivider: false,
                    externalLink: true,
                    onTap: () => _openBladeConsole(),
                  ),
                ),
              ],
              if (showAdminSection) ...[
                const SizedBox(height: 16),
                Text(
                  KiamiStrings.settingsAdminSection,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                KiamiCard(
                  padding: EdgeInsets.zero,
                  child: _SettingsNavTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: KiamiStrings.settingsAdmin,
                    showDivider: false,
                    onTap: () => context.push(KiamiRoutes.admin),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await AdminAccessStore.clear();
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go(KiamiRoutes.auth);
                },
                icon: const Icon(Icons.logout),
                label: const Text(KiamiStrings.settingsLogout),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KiamiColors.error,
                  side: const BorderSide(color: KiamiColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                KiamiStrings.settingsDangerSection,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              KiamiCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsNavTile(
                      icon: Icons.person_remove_outlined,
                      title: KiamiStrings.settingsDeleteAccount,
                      onTap: _deletingAccount ? () {} : _confirmDeleteAccount,
                      dense: true,
                      titleColor: KiamiColors.error,
                      iconColor: KiamiColors.error,
                    ),
                    _SettingsNavTile(
                      icon: Icons.delete_outline,
                      title: KiamiStrings.trashTitle,
                      onTap: () => context.push(KiamiRoutes.trash),
                      dense: true,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openLegalDocument(String title) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegalPdfViewerPage(
          title: title,
        ),
      ),
    );
  }

  Future<void> _openBladeConsole() async {
    final urls = [
      KiamiConstants.bladeConsoleProxyUrl,
      KiamiConstants.bladeConsoleUrl,
    ];
    for (final url in urls) {
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Abra no browser (mesma Wi‑Fi):\n${KiamiConstants.bladeConsoleProxyUrl}',
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _DeleteAccountConfirmDialog(),
    );
    if (!mounted || confirmed != true) return;

    final api = ref.read(kiamiApiClientProvider);
    final authRepo = ref.read(authRepositoryProvider);

    setState(() => _deletingAccount = true);
    try {
      await api.deleteAccount();
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      await AdminAccessStore.clear();
      await authRepo.signOut();
      if (!mounted) return;
      context.go(KiamiRoutes.auth);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.settingsDeleteSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.settingsDeleteError)),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }
}

class _DeleteAccountConfirmDialog extends StatefulWidget {
  const _DeleteAccountConfirmDialog();

  @override
  State<_DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<_DeleteAccountConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _confirmed =>
      _controller.text.trim() == KiamiStrings.settingsDeleteConfirmHint;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(KiamiStrings.settingsDeleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(KiamiStrings.settingsDeleteAccountBody),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: KiamiStrings.settingsDeleteConfirmHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
          child: const Text(KiamiStrings.settingsDeleteAccount),
        ),
      ],
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.dense = false,
    this.showDivider = true,
    this.titleColor,
    this.iconColor,
    this.externalLink = false,
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool dense;
  final bool showDivider;
  final Color? titleColor;
  final Color? iconColor;
  final bool externalLink;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      color: iconColor ?? KiamiColors.primaryBlue,
      size: 22,
    );

    return Column(
      children: [
        ListTile(
          dense: dense,
          leading: badgeCount != null && badgeCount! > 0
              ? Badge(
                  label: Text('$badgeCount'),
                  child: iconWidget,
                )
              : iconWidget,
          title: Text(
            title,
            style: titleColor != null ? TextStyle(color: titleColor) : null,
          ),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: Icon(
            externalLink ? Icons.open_in_new : Icons.chevron_right,
            size: 20,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
