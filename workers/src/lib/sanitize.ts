/** Nome de ficheiro seguro para chave R2 (sem path traversal). */
export function sanitizeFileName(name: string): string {
  const base = name.replace(/\\/g, '/').split('/').pop()?.trim() ?? '';
  const cleaned = base
    .replace(/[^\w.\- ()áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]/gi, '_')
    .slice(0, 200);
  return cleaned.length > 0 ? cleaned : 'ficheiro';
}
