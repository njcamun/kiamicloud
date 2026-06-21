/// Ambiente de execucao da app (Fase 14 — beta).
enum KiamiAppEnvironment {
  development,
  beta,
  production,
}

abstract final class KiamiEnvironment {
  static const String appVersion = '0.6.0';

  static KiamiAppEnvironment _current = KiamiAppEnvironment.development;

  static KiamiAppEnvironment get current => _current;

  static bool get isBeta => _current == KiamiAppEnvironment.beta;

  static bool get isProduction => _current == KiamiAppEnvironment.production;

  static bool get isDevelopment => _current == KiamiAppEnvironment.development;

  static String get label => switch (_current) {
        KiamiAppEnvironment.development => 'Desenvolvimento',
        KiamiAppEnvironment.beta => 'Beta',
        KiamiAppEnvironment.production => 'Producao',
      };

  static void configure({KiamiAppEnvironment? environment}) {
    if (environment != null) {
      _current = environment;
      return;
    }
    const raw = String.fromEnvironment('KIAMI_ENV', defaultValue: 'development');
    _current = switch (raw.toLowerCase()) {
      'beta' => KiamiAppEnvironment.beta,
      'production' || 'prod' => KiamiAppEnvironment.production,
      _ => KiamiAppEnvironment.development,
    };
  }

  /// URL beta por defeito quando KIAMI_ENV=beta sem URL explicita.
  static String get defaultBetaApiUrl =>
      const String.fromEnvironment(
        'KIAMI_BETA_API_URL',
        defaultValue: 'https://kiamicloud-api-beta.kiamicloud.workers.dev',
      );
}
