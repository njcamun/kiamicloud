import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/kiami_api_client.dart';
import '../../api/kiami_api_config.dart';
import '../../constants/kiami_constants.dart';
import '../../constants/kiami_strings.dart';
import '../../data/api_endpoint_store.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/kiami_layout.dart';
import '../../utils/kiami_local_api_url.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/kiami_page_header.dart';
import '../files/providers/files_providers.dart';
import 'providers/api_endpoint_providers.dart';

/// Escolha de servidor Cloudflare vs CasaOS (utilizadores autorizados).
class ApiEndpointSettingsPage extends ConsumerStatefulWidget {
  const ApiEndpointSettingsPage({super.key});

  @override
  ConsumerState<ApiEndpointSettingsPage> createState() =>
      _ApiEndpointSettingsPageState();
}

class _ApiEndpointSettingsPageState
    extends ConsumerState<ApiEndpointSettingsPage> {
  final _hostController = TextEditingController();
  KiamiApiEndpointMode _mode = KiamiApiEndpointMode.cloud;
  bool _loading = true;
  bool _testing = false;
  bool _saving = false;
  bool _testPassed = false;
  String? _lastTestedUrl;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final mode = await ApiEndpointStore.getMode();
    final host = await ApiEndpointStore.getLocalHost();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _hostController.text = host ?? KiamiConstants.bladeStaticHost;
      _loading = false;
      _testPassed = false;
      _lastTestedUrl = null;
    });
  }

  String get _cloudUrl => KiamiConstants.cloudBetaApiBaseUrl;

  String _resolveDraftUrl() {
    return ApiEndpointStore.resolveUrl(
      mode: _mode,
      cloudDefault: _cloudUrl,
      localHost: _hostController.text,
    );
  }

  void _onModeChanged(KiamiApiEndpointMode mode) {
    setState(() {
      _mode = mode;
      if (mode == KiamiApiEndpointMode.cloud) {
        // URL cloud é fixo e fiável — não exige teste manual.
        _testPassed = true;
        _lastTestedUrl = _cloudUrl;
      } else {
        _testPassed = false;
        _lastTestedUrl = null;
      }
    });
  }

  void _onHostChanged(String _) {
    setState(() {
      _testPassed = false;
      _lastTestedUrl = null;
    });
  }

  Future<void> _testConnection() async {
    final url = _resolveDraftUrl();
    setState(() => _testing = true);
    try {
      await KiamiApiClient.pingHealthAt(url);
      if (!mounted) return;
      setState(() {
        _testPassed = true;
        _lastTestedUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.settingsServerTestOk)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testPassed = false;
        _lastTestedUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = _resolveDraftUrl();
    final cloudBuiltIn =
        _mode == KiamiApiEndpointMode.cloud && url == _cloudUrl;
    if (!cloudBuiltIn && (!_testPassed || _lastTestedUrl != url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.settingsServerTestRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final host = _mode == KiamiApiEndpointMode.local
          ? displayHostFromUrl(
              buildLocalApiUrlFromHost(
                _hostController.text,
                defaultPort: KiamiConstants.bladeApiPort,
              ),
            )
          : null;
      await persistAndApplyApiEndpoint(
        ref,
        mode: _mode,
        localHost: host,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.settingsServerSaved)),
      );
      context.pop();
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
    final canSwitch = ref.watch(canSwitchApiEndpointProvider);
    if (!canSwitch) {
      final showBack = kiamiShowsShellBackButton(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KiamiPageHeader(
            title: KiamiStrings.settingsServerTitle,
            leading: showBack
                ? IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go(KiamiRoutes.settings),
                  )
                : null,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  KiamiStrings.adminCanSwitchServerHint,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final showBack = kiamiShowsShellBackButton(context);
    final currentUrl = KiamiApiConfig.baseUrl;
    final canSave = _testPassed && _lastTestedUrl == _resolveDraftUrl();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KiamiPageHeader(
          title: KiamiStrings.settingsServerTitle,
          leading: showBack
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go(KiamiRoutes.settings),
                )
              : null,
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: kiamiScrollPadding(
                    context,
                    left: kiamiSettingsListHorizontalPadding,
                    top: 8,
                    right: kiamiSettingsListHorizontalPadding,
                    bottomExtra: 24,
                  ),
                  children: [
                    KiamiCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            KiamiStrings.settingsServerCurrent,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentUrl,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            KiamiApiConfig.usesCloudApi
                                ? KiamiStrings.settingsServerModeCloud
                                : KiamiStrings.settingsServerModeLocal,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: KiamiColors.primaryBlue,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      KiamiStrings.settingsServerModeLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<KiamiApiEndpointMode>(
                      emptySelectionAllowed: false,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: KiamiApiEndpointMode.cloud,
                          label: Text(KiamiStrings.settingsServerModeCloud),
                          icon: Icon(Icons.cloud_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: KiamiApiEndpointMode.local,
                          label: Text(KiamiStrings.settingsServerModeLocal),
                          icon: Icon(Icons.dns_outlined, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) {
                        if (s.isNotEmpty) _onModeChanged(s.first);
                      },
                    ),
                    if (_mode == KiamiApiEndpointMode.local) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: KiamiStrings.settingsServerIpLabel,
                          hintText: KiamiStrings.settingsServerIpHint,
                          prefixIcon: Icon(Icons.lan_outlined),
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        onChanged: _onHostChanged,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        KiamiStrings.settingsServerLocalPortHint(
                          KiamiConstants.bladeApiPort,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: _testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_rounded),
                      label: Text(KiamiStrings.settingsServerTest),
                    ),
                    if (_testPassed) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              KiamiStrings.settingsServerTestOk,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: (!_saving && canSave) ? _save : null,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(KiamiStrings.settingsServerSave),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
