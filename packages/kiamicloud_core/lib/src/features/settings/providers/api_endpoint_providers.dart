import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/kiami_api_config.dart';
import '../../../constants/kiami_constants.dart';
import '../../../data/api_endpoint_store.dart';
import '../../files/providers/files_providers.dart';

/// Incrementa quando o URL da API muda (força refresh de providers dependentes).
final apiEndpointRevisionProvider = StateProvider<int>((ref) => 0);

/// Sincroniza [KiamiApiConfig] com as preferências guardadas (SharedPreferences).
Future<void> reloadApiEndpointFromStore() async {
  if (kIsWeb) {
    await ApiEndpointStore.clear();
    KiamiApiConfig.configure(
      KiamiConstants.cloudBetaApiBaseUrl,
      mode: KiamiApiEndpointMode.cloud,
    );
    return;
  }

  final mode = await ApiEndpointStore.getMode();
  final url = await ApiEndpointStore.loadEffectiveUrl(
    cloudDefault: KiamiConstants.cloudBetaApiBaseUrl,
  );
  KiamiApiConfig.configure(url, mode: mode);
}

/// Garante que memória e preferências estão alinhadas antes de chamadas à API.
final activeApiEndpointProvider = FutureProvider<void>((ref) async {
  ref.watch(apiEndpointRevisionProvider);
  await reloadApiEndpointFromStore();
});

final savedApiEndpointModeProvider =
    FutureProvider.autoDispose<KiamiApiEndpointMode>((ref) async {
  ref.watch(apiEndpointRevisionProvider);
  return ApiEndpointStore.getMode();
});

final savedLocalApiHostProvider = FutureProvider.autoDispose<String?>((ref) async {
  ref.watch(apiEndpointRevisionProvider);
  return ApiEndpointStore.getLocalHost();
});

final canSwitchApiEndpointProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  final profile = ref.watch(kiamiProfileProvider).valueOrNull;
  return profile?.canSwitchApiEndpoint ?? false;
});

void applyApiEndpointChange(
  dynamic ref, {
  required KiamiApiEndpointMode mode,
  String? localHost,
  required String cloudDefault,
}) {
  final url = ApiEndpointStore.resolveUrl(
    mode: mode,
    cloudDefault: cloudDefault,
    localHost: localHost,
  );
  KiamiApiConfig.configure(url, mode: mode);
  ref.read(apiEndpointRevisionProvider.notifier).state++;
  refreshKiamiProfile(ref);
  ref.invalidate(kiamiFilesProvider);
  ref.invalidate(savedApiEndpointModeProvider);
  ref.invalidate(savedLocalApiHostProvider);
  ref.invalidate(activeApiEndpointProvider);
}

Future<void> persistAndApplyApiEndpoint(
  dynamic ref, {
  required KiamiApiEndpointMode mode,
  String? localHost,
}) async {
  if (kIsWeb) {
    await ApiEndpointStore.clear();
    applyApiEndpointChange(
      ref,
      mode: KiamiApiEndpointMode.cloud,
      cloudDefault: KiamiConstants.cloudBetaApiBaseUrl,
    );
    return;
  }

  await ApiEndpointStore.save(mode: mode, localHost: localHost);
  applyApiEndpointChange(
    ref,
    mode: mode,
    localHost: localHost,
    cloudDefault: KiamiConstants.cloudBetaApiBaseUrl,
  );
}

String displayHostFromUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || uri.host.isEmpty) return baseUrl;
  if (uri.hasPort && uri.port != 80 && uri.port != 443) {
    return '${uri.host}:${uri.port}';
  }
  return uri.host;
}
