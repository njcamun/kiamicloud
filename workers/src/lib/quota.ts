/** Limites de alerta de quota (docs/PLANOS.md, Fase 10). */
export const QUOTA_WARNING_RATIO = 0.8;
export const QUOTA_CRITICAL_RATIO = 0.95;

export type QuotaStatus = 'ok' | 'warning' | 'critical' | 'full';

export type QuotaInfo = {
  status: QuotaStatus;
  usagePercent: number;
  usageRatio: number;
  canUpload: boolean;
  message: string | null;
  warningAtPercent: number;
  criticalAtPercent: number;
};

export function computeQuotaInfo(
  storageUsedBytes: number,
  quotaBytes: number,
): QuotaInfo {
  const usageRatio =
    quotaBytes > 0 ? storageUsedBytes / quotaBytes : 0;
  const usagePercent =
    Math.round(usageRatio * 1000) / 10;

  let status: QuotaStatus = 'ok';
  let message: string | null = null;

  if (usageRatio >= 1 || storageUsedBytes >= quotaBytes) {
    status = 'full';
    message =
      'Quota cheia. Apague ficheiros ou faca upgrade do plano para continuar a enviar.';
  } else if (usageRatio >= QUOTA_CRITICAL_RATIO) {
    status = 'critical';
    message = `Quota quase cheia (${usagePercent}%). Liberte espaco em breve.`;
  } else if (usageRatio >= QUOTA_WARNING_RATIO) {
    status = 'warning';
    message = `A usar ${usagePercent}% do armazenamento (aviso aos 80%).`;
  }

  return {
    status,
    usagePercent,
    usageRatio,
    canUpload: storageUsedBytes < quotaBytes,
    message,
    warningAtPercent: QUOTA_WARNING_RATIO * 100,
    criticalAtPercent: QUOTA_CRITICAL_RATIO * 100,
  };
}
