/** Limite efectivo por ficheiro: override do utilizador ou padrão do plano. */
export function effectiveMaxFileSizeBytes(
  planMaxFileSizeBytes: number,
  overrideBytes: number | null | undefined,
): number {
  if (overrideBytes != null && overrideBytes > 0) {
    return overrideBytes;
  }
  return planMaxFileSizeBytes > 0 ? planMaxFileSizeBytes : 15 * 1024 * 1024;
}

const MB = 1024 * 1024;
const MIN_OVERRIDE = 1 * MB;
/** Máximo que o admin pode atribuir por ficheiro (KiamiCloud). */
const MAX_OVERRIDE = 300 * MB;

export function validateTransferOverrideBytes(bytes: number): string | null {
  if (!Number.isFinite(bytes) || bytes < MIN_OVERRIDE) {
    return `Transferência mínima: ${MIN_OVERRIDE / MB} MB.`;
  }
  if (bytes > MAX_OVERRIDE) {
    return `Transferência máxima: ${MAX_OVERRIDE / MB} MB.`;
  }
  return null;
}
