import '../api/kiami_api_config.dart';
import '../constants/kiami_constants.dart';

/// Quota legada da API local «ilimitada» (1 TiB).
const int kLegacyUnlimitedQuotaBytes = 1024 * 1024 * 1024 * 1024;

int get kBasicoQuotaBytes =>
    KiamiConstants.basicoPlanQuotaGb * 1024 * 1024 * 1024;

int get kBasicoMaxFileBytes =>
    KiamiConstants.basicoPlanMaxFileMb * 1024 * 1024;

int get kLocalAdminMaxQuotaBytes => 500 * 1024 * 1024 * 1024;

bool isLegacyUnlimitedQuota(int bytes) =>
    bytes >= kLegacyUnlimitedQuotaBytes ~/ 2;

/// Normaliza quota para UI e cache (valores legados «ilimitados» → plano básico).
int normalizeQuotaBytes(int bytes) {
  if (isLegacyUnlimitedQuota(bytes)) return kBasicoQuotaBytes;
  if (bytes <= 0) return kBasicoQuotaBytes;
  return bytes;
}

/// Quota efectiva — cloud: valor da API; Blade: sem limite (mantém valor da API).
int parseEffectiveQuotaBytes(int bytes) {
  if (!KiamiApiConfig.isCloudEndpoint) {
    return bytes > 0 ? bytes : kLegacyUnlimitedQuotaBytes;
  }
  return bytes > 0 ? bytes : kBasicoQuotaBytes;
}

/// 0 = sem limite por ficheiro (servidor local).
const int kUnlimitedTransferBytes = 0;

int normalizeMaxFileBytes(int bytes) {
  if (bytes <= 0) return kUnlimitedTransferBytes;
  if (isLegacyUnlimitedQuota(bytes)) return kBasicoMaxFileBytes;
  return bytes;
}

/// Transferência — cloud: valor da API; Blade: sempre ilimitado.
int parseEffectiveMaxFileBytes(int bytes) {
  if (!KiamiApiConfig.isCloudEndpoint) {
    return kUnlimitedTransferBytes;
  }
  return bytes > 0 ? bytes : kBasicoMaxFileBytes;
}

int normalizedStorageAvailable(int used, int quota) =>
    (quota - used).clamp(0, quota);
