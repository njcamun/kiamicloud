import '../config/kiami_environment.dart';
import '../data/api_endpoint_store.dart';

/// URL base da API Workers (sem barra final).
abstract final class KiamiApiConfig {
  static String? _override;
  static KiamiApiEndpointMode _endpointMode = KiamiApiEndpointMode.cloud;

  static void configure(
    String baseUrl, {
    KiamiApiEndpointMode? mode,
  }) {
    final trimmed = baseUrl.trim();
    _override = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    if (mode != null) {
      _endpointMode = mode;
    }
  }

  static void setEndpointMode(KiamiApiEndpointMode mode) {
    _endpointMode = mode;
  }

  static KiamiApiEndpointMode get endpointMode => _endpointMode;

  static String get baseUrl {
    if (_override != null && _override!.isNotEmpty) return _override!;
    const fromEnv = String.fromEnvironment('KIAMI_API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/')
          ? fromEnv.substring(0, fromEnv.length - 1)
          : fromEnv;
    }
    return platformDefault();
  }

  static String platformDefault() {
    if (KiamiEnvironment.isProduction) {
      return const String.fromEnvironment(
        'KIAMI_PROD_API_URL',
        defaultValue: 'https://kiamicloud-api.kiamicloud.workers.dev',
      );
    }
    return KiamiEnvironment.defaultBetaApiUrl;
  }

  /// Heurística pelo URL (diagnóstico); preferir [isCloudEndpoint] / [endpointMode].
  static bool get isLocalApiUrl {
    final url = baseUrl.toLowerCase();
    return url.contains('127.0.0.1') ||
        url.contains('localhost') ||
        url.contains('192.168.') ||
        url.contains('10.0.2.2');
  }

  /// Servidor Cloudflare seleccionado nas preferências.
  static bool get isCloudEndpoint => _endpointMode == KiamiApiEndpointMode.cloud;

  static bool get isLocalEndpoint => _endpointMode == KiamiApiEndpointMode.local;

  /// Destino efectivo dos pedidos HTTP (URL actual).
  static bool get usesCloudApi => !isLocalApiUrl;
}
