import '../assets/kiami_assets.dart';
import '../utils/kiami_local_api_url.dart';

/// Constantes globais do MVP.
abstract final class KiamiConstants {
  static const String appName = 'KiamiCloud';

  static const String slogan = 'Minha Cloud. Meu mundo. Sem limites.';
  /// Fallback global (plano Plus+ usa 150 MB via API).
  static const int maxUploadBytes = 157286400; // 150 MB
  static const String maxUploadLabel = '150 MB';

  /// Breakpoints responsivos (mobile first)
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 1024;

  /// Plano Básico por defeito
  static const int basicoPlanQuotaGb = 20;
  static const int basicoPlanMaxFileMb = 15;

  /// API beta na Cloudflare (apos wrangler deploy --env beta).
  static const String cloudBetaApiBaseUrl =
      'https://kiamicloud-api-beta.kiamicloud.workers.dev';

  /// IP estático do ZimaBlade (reserva DHCP no router).
  static const String bladeStaticHost = '192.168.100.170';
  static const int bladeApiPort = 8787;
  static const int bladeConsoleProxyPort = 8790;

  /// API no ZimaBlade (Docker + wrangler dev).
  static const String bladeApiBaseUrl =
      'http://$bladeStaticHost:$bladeApiPort';

  /// URL LAN por defeito (CasaOS / ZimaBlade).
  /// Override: `--dart-define=KIAMI_LOCAL_API_HOST=192.168.100.170:8787`
  /// Ou URL completa: `--dart-define=KIAMI_LOCAL_API_URL=http://192.168.100.170:8787`
  static String get lanApiBaseUrl {
    return normalizeLocalApiBaseUrl(
      defaultUrl: bladeApiBaseUrl,
      fromUrlDefine: const String.fromEnvironment('KIAMI_LOCAL_API_URL'),
      fromHostDefine: const String.fromEnvironment('KIAMI_LOCAL_API_HOST'),
    );
  }

  @Deprecated('Use lanApiBaseUrl')
  static String get localApiBaseUrl => lanApiBaseUrl;

  /// Consola Blade — proxy nginx (:8790) ou API directa se proxy indisponível.
  static String get bladeConsoleUrl {
    const proxyHost = String.fromEnvironment('KIAMI_BLADE_CONSOLE_HOST');
    if (proxyHost.trim().isNotEmpty) {
      final host = proxyHost.trim().replaceFirst(RegExp(r'^https?://'), '');
      return 'http://$host/blade-console/';
    }
    return '$lanApiBaseUrl/blade-console/';
  }

  /// Atalho CasaOS (nginx :8790).
  static String get bladeConsoleProxyUrl {
    final uri = Uri.parse(lanApiBaseUrl);
    final host = uri.host.isNotEmpty ? uri.host : bladeStaticHost;
    return 'http://$host:$bladeConsoleProxyPort/blade-console/';
  }

  /// URLs legais — actualizar quando as páginas estiverem no site.
  static const String termsUrl = 'https://kiamicloud.com/termos';
  static const String privacyUrl = 'https://kiamicloud.com/privacidade';
  static const String supportEmail = 'KiamiCloud@gmail.com';
  static const String legalContactEmail = supportEmail;

  /// Documentação legal completa (sincronizada de branding/assets/).
  static const String legalDocumentAsset = KiamiAssets.legalDocumentBundlePath;

  /// WhatsApp de suporte — apenas dígitos (código país + número).
  /// Configurar depois em código ou via `--dart-define=KIAMI_SUPPORT_WHATSAPP=2449XXXXXXXX`.
  static const String supportWhatsAppNumber = String.fromEnvironment(
    'KIAMI_SUPPORT_WHATSAPP',
    defaultValue: '244958839693',
  );

  static String get supportWhatsAppDigits =>
      supportWhatsAppNumber.replaceAll(RegExp(r'\D'), '');
}
