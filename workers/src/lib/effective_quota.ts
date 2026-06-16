const GB = 1024 * 1024 * 1024;
const MB = 1024 * 1024;

/** Padrão KiamiLocal — alinhado ao plano Básico. */
export const LOCAL_DEFAULT_QUOTA_BYTES = 20 * GB;
export const LOCAL_DEFAULT_TRANSFER_BYTES = 15 * MB;

const MIN_QUOTA = 1 * GB;
/** Máximo que o admin pode atribuir (plano Ultra). */
const MAX_QUOTA = 500 * GB;

/** Quota efectiva: override do admin ou quota do plano. */
export function effectiveQuotaBytes(
  planQuotaBytes: number,
  overrideBytes: number | null | undefined,
): number {
  if (overrideBytes != null && overrideBytes > 0) {
    return overrideBytes;
  }
  return planQuotaBytes > 0 ? planQuotaBytes : LOCAL_DEFAULT_QUOTA_BYTES;
}

export function validateQuotaOverrideBytes(bytes: number): string | null {
  if (!Number.isFinite(bytes) || bytes < MIN_QUOTA) {
    return `Armazenamento mínimo: ${MIN_QUOTA / GB} GB.`;
  }
  if (bytes > MAX_QUOTA) {
    return `Armazenamento máximo: ${MAX_QUOTA / GB} GB.`;
  }
  return null;
}
