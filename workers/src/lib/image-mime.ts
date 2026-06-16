const IMAGE_EXTENSIONS = new Set([
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
]);

/** Tipos suportados para geracao de miniatura no cliente. */
export function isThumbnailSource(
  mimeType: string | null | undefined,
  fileName?: string,
): boolean {
  const mime = mimeType?.toLowerCase() ?? '';
  if (mime === 'image/svg+xml') return false;
  if (mime.startsWith('image/')) return true;

  if (!fileName?.includes('.')) return false;
  const ext = fileName.split('.').pop()?.toLowerCase() ?? '';
  return IMAGE_EXTENSIONS.has(ext);
}
