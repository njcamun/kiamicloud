import type { QuotaInfo } from './quota';
import { effectiveMaxFileSizeBytes } from './effective_max_file';
import { effectiveQuotaBytes } from './effective_quota';

/** 1 TiB — quota efectiva no servidor local (CasaOS / Blade). */
export const LOCAL_UNLIMITED_QUOTA_BYTES = 1024 * 1024 * 1024 * 1024;

/**
 * Servidor local (Blade, ENVIRONMENT=development): sem limites de armazenamento
 * nem de transferência por ficheiro. Cloudflare aplica quotas do plano.
 */
export function isLocalUnlimitedMode(environment?: string): boolean {
  return environment === 'development';
}

export function isLocalTransferUnlimited(environment?: string): boolean {
  return isLocalUnlimitedMode(environment);
}

export function cloudLimitsEnforced(environment?: string): boolean {
  return !isLocalUnlimitedMode(environment);
}

/** Chat de suporte — apenas na API Cloudflare (não no Blade/local). */
export function isCloudSupportChatEnabled(environment?: string): boolean {
  return cloudLimitsEnforced(environment);
}

export function resolveQuotaBytes(
  planQuotaBytes: number,
  overrideBytes: number | null | undefined,
  environment?: string,
): number {
  if (isLocalUnlimitedMode(environment)) return LOCAL_UNLIMITED_QUOTA_BYTES;
  return effectiveQuotaBytes(planQuotaBytes, overrideBytes);
}

export function resolveMaxFileBytes(
  planMaxFileSizeBytes: number,
  overrideBytes: number | null | undefined,
  environment?: string,
): number {
  if (isLocalTransferUnlimited(environment)) return 0;
  return effectiveMaxFileSizeBytes(planMaxFileSizeBytes, overrideBytes);
}

export function unlimitedQuotaInfo(): QuotaInfo {
  return {
    status: 'ok',
    usagePercent: 0,
    usageRatio: 0,
    canUpload: true,
    message: null,
    warningAtPercent: 80,
    criticalAtPercent: 95,
  };
}

export function applyLocalUnlimitedToProfile<T>(profile: T, environment?: string): T {
  if (!isLocalUnlimitedMode(environment)) return profile;
  return profile;
}
