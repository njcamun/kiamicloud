import {
  SHARE_DEFAULT_EXPIRY_DAYS,
  SHARE_MAX_EXPIRY_DAYS,
} from '../config/shares';

export type FileShareRow = {
  id: string;
  token: string;
  firebase_uid: string;
  file_id: string;
  expires_at: string;
  revoked_at: string | null;
  access_count: number;
  created_at: string;
};

export type FileShareDto = {
  id: string;
  token: string;
  fileId: string;
  fileName: string;
  expiresAt: string;
  revokedAt: string | null;
  accessCount: number;
  createdAt: string;
  active: boolean;
};

function generateToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(24));
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function clampExpiryDays(days?: number): number {
  if (typeof days !== 'number' || !Number.isFinite(days)) {
    return SHARE_DEFAULT_EXPIRY_DAYS;
  }
  return Math.min(
    SHARE_MAX_EXPIRY_DAYS,
    Math.max(1, Math.floor(days)),
  );
}

export async function createFileShare(
  db: D1Database,
  input: {
    firebaseUid: string;
    fileId: string;
    expiresInDays?: number;
  },
): Promise<FileShareDto | null> {
  const file = await db
    .prepare(
      `SELECT id, name, status FROM files
       WHERE id = ? AND firebase_uid = ? AND deleted_at IS NULL`,
    )
    .bind(input.fileId, input.firebaseUid)
    .first<{ id: string; name: string; status: string }>();

  if (!file || file.status !== 'active') return null;

  const days = clampExpiryDays(input.expiresInDays);
  const id = crypto.randomUUID();
  const token = generateToken();

  await db
    .prepare(
      `INSERT INTO file_shares (
         id, token, firebase_uid, file_id, expires_at
       ) VALUES (?, ?, ?, ?, datetime('now', '+' || ? || ' days'))`,
    )
    .bind(id, token, input.firebaseUid, input.fileId, days)
    .run();

  const row = await db
    .prepare(
      `SELECT id, token, firebase_uid, file_id, expires_at, revoked_at,
              access_count, created_at
       FROM file_shares WHERE id = ?`,
    )
    .bind(id)
    .first<FileShareRow>();

  if (!row) return null;

  return mapShareDto(row, file.name);
}

function isShareActive(row: FileShareRow): boolean {
  if (row.revoked_at) return false;
  return row.expires_at > new Date().toISOString().slice(0, 19).replace('T', ' ');
}

function mapShareDto(row: FileShareRow, fileName: string): FileShareDto {
  return {
    id: row.id,
    token: row.token,
    fileId: row.file_id,
    fileName,
    expiresAt: row.expires_at,
    revokedAt: row.revoked_at,
    accessCount: row.access_count,
    createdAt: row.created_at,
    active: isShareActive(row),
  };
}

export async function listFileSharesForUser(
  db: D1Database,
  firebaseUid: string,
): Promise<FileShareDto[]> {
  const { results } = await db
    .prepare(
      `SELECT s.id, s.token, s.firebase_uid, s.file_id, s.expires_at, s.revoked_at,
              s.access_count, s.created_at, f.name AS file_name
       FROM file_shares s
       INNER JOIN files f ON f.id = s.file_id
       WHERE s.firebase_uid = ?
       ORDER BY s.created_at DESC
       LIMIT 100`,
    )
    .bind(firebaseUid)
    .all<FileShareRow & { file_name: string }>();

  return (results ?? []).map((row) =>
    mapShareDto(row, row.file_name),
  );
}

export async function revokeFileShare(
  db: D1Database,
  shareId: string,
  firebaseUid: string,
): Promise<boolean> {
  const result = await db
    .prepare(
      `UPDATE file_shares SET revoked_at = datetime('now')
       WHERE id = ? AND firebase_uid = ? AND revoked_at IS NULL`,
    )
    .bind(shareId, firebaseUid)
    .run();
  return (result.meta.changes ?? 0) > 0;
}

export type PublicShareFile = {
  shareId: string;
  fileId: string;
  name: string;
  mimeType: string | null;
  sizeBytes: number;
  r2ObjectKey: string;
  ownerUid: string;
};

export async function getPublicShareFile(
  db: D1Database,
  token: string,
): Promise<PublicShareFile | null> {
  const row = await db
    .prepare(
      `SELECT s.id AS share_id,
              f.id AS file_id, f.name, f.mime_type, f.size_bytes, f.r2_object_key,
              f.firebase_uid
       FROM file_shares s
       INNER JOIN files f ON f.id = s.file_id
       WHERE s.token = ?
         AND s.revoked_at IS NULL
         AND s.expires_at > datetime('now')
         AND f.status = 'active'
         AND f.deleted_at IS NULL
         AND f.r2_object_key IS NOT NULL`,
    )
    .bind(token)
    .first<{
      share_id: string;
      file_id: string;
      name: string;
      mime_type: string | null;
      size_bytes: number;
      r2_object_key: string;
      firebase_uid: string;
    }>();

  if (!row) return null;

  return {
    shareId: row.share_id,
    fileId: row.file_id,
    name: row.name,
    mimeType: row.mime_type,
    sizeBytes: row.size_bytes,
    r2ObjectKey: row.r2_object_key,
    ownerUid: row.firebase_uid,
  };
}

export async function recordShareAccess(
  db: D1Database,
  shareId: string,
): Promise<void> {
  await db
    .prepare(
      `UPDATE file_shares SET access_count = access_count + 1 WHERE id = ?`,
    )
    .bind(shareId)
    .run();
}
