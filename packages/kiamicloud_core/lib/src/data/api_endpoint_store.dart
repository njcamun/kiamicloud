import 'package:shared_preferences/shared_preferences.dart';

import '../constants/kiami_constants.dart';
import '../utils/kiami_local_api_url.dart';

enum KiamiApiEndpointMode { cloud, local }

/// Preferência de servidor persistida (app cloud — utilizadores autorizados).
abstract final class ApiEndpointStore {
  static const _modeKey = 'api_endpoint_mode_v1';
  static const _hostKey = 'api_endpoint_host_v1';

  static Future<KiamiApiEndpointMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_modeKey);
    return raw == 'local' ? KiamiApiEndpointMode.local : KiamiApiEndpointMode.cloud;
  }

  static Future<String?> getLocalHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hostKey);
  }

  static Future<void> save({
    required KiamiApiEndpointMode mode,
    String? localHost,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _modeKey,
      mode == KiamiApiEndpointMode.local ? 'local' : 'cloud',
    );
    if (mode == KiamiApiEndpointMode.local &&
        localHost != null &&
        localHost.trim().isNotEmpty) {
      await prefs.setString(_hostKey, localHost.trim());
    } else {
      await prefs.remove(_hostKey);
    }
  }

  static Future<void> clear() => save(mode: KiamiApiEndpointMode.cloud);

  static String resolveUrl({
    required KiamiApiEndpointMode mode,
    required String cloudDefault,
    String? localHost,
  }) {
    if (mode == KiamiApiEndpointMode.cloud) {
      return cloudDefault.replaceAll(RegExp(r'/+$'), '');
    }
    final host = (localHost ?? '').trim();
    if (host.isEmpty) {
      return KiamiConstants.bladeApiBaseUrl;
    }
    return buildLocalApiUrlFromHost(
      host,
      defaultPort: KiamiConstants.bladeApiPort,
    );
  }

  static Future<String> loadEffectiveUrl({required String cloudDefault}) async {
    final mode = await getMode();
    final host = await getLocalHost();
    return resolveUrl(
      mode: mode,
      cloudDefault: cloudDefault,
      localHost: host,
    );
  }
}
