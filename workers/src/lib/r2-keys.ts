import { sanitizeFileName } from './sanitize';

/**
 * Estrutura obrigatoria: users/{firebase_uid}/{file_id}/{filename}
 * @see docs/ARQUITETURA.md
 */
export function buildR2ObjectKey(
  firebaseUid: string,
  fileId: string,
  fileName: string,
): string {
  const safeName = sanitizeFileName(fileName);
  return `users/${firebaseUid}/${fileId}/${safeName}`;
}

/** Miniatura JPEG fixa por ficheiro (nao inclui o nome original). */
export function buildThumbR2ObjectKey(
  firebaseUid: string,
  fileId: string,
): string {
  return `users/${firebaseUid}/${fileId}/_thumb.jpg`;
}
