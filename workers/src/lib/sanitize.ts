/** Nome de ficheiro seguro para chave R2 (sem path traversal). */
export function sanitizeFileName(name: string): string {
  const base = name.replace(/\\/g, '/').split('/').pop()?.trim() ?? '';
  const cleaned = base
    .replace(/[^\w.\- ()áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]/gi, '_')
    .slice(0, 200);
  return cleaned.length > 0 ? cleaned : 'ficheiro';
}

/**
 * Content-Disposition seguro (RFC 6266 / 5987).
 * Evita quebra de cabecalho com aspas, CR/LF ou caracteres especiais.
 */
export function contentDispositionInline(filename: string): string {
  const raw = filename.replace(/[\r\n]/g, ' ').slice(0, 200);
  const asciiFallback = raw
    .replace(/[^\x20-\x7E]/g, '_')
    .replace(/["\\]/g, '_')
    .trim() || 'ficheiro';
  const escaped = asciiFallback.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  const utf8Encoded = encodeURIComponent(raw);
  return `inline; filename="${escaped}"; filename*=UTF-8''${utf8Encoded}`;
}
