import { buildR2ObjectKey } from '../lib/r2-keys';
import { sanitizeFileName } from '../lib/sanitize';
import {
  isLocalUnlimitedMode,
  resolveMaxFileBytes,
  resolveQuotaBytes,
} from '../lib/local_unlimited';

const FILE_COLUMNS = `id, firebase_uid, folder_id, name, mime_type, size_bytes,
  r2_object_key, thumb_r2_object_key, status, created_at, updated_at`;

export type FileRow = {
  id: string;
  firebase_uid: string;
  folder_id: string | null;
  name: string;
  mime_type: string | null;
  size_bytes: number;
  r2_object_key: string | null;
  thumb_r2_object_key: string | null;
  status: string;
  created_at: string;
  updated_at: string;
};

export type FileDto = {
  id: string;
  name: string;
  mimeType: string | null;
  sizeBytes: number;
  status: string;
  folderId: string | null;
  createdAt: string;
  updatedAt: string;
  hasThumbnail: boolean;
};

export type StorageContext = {
  storageUsedBytes: number;
  quotaBytes: number;
  maxFileSizeBytes: number;
  planCode: string;
};

function mapFileDto(row: FileRow): FileDto {
  return {
    id: row.id,
    name: row.name,
    mimeType: row.mime_type,
    sizeBytes: row.size_bytes,
    status: row.status,
    folderId: row.folder_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    hasThumbnail: Boolean(row.thumb_r2_object_key),
  };
}

type StorageRow = {
  storage_used_bytes: number;
  plan_quota_bytes: number;
  quota_bytes_override: number | null;
  max_file_size_bytes: number;
  max_file_size_bytes_override: number | null;
  plan_code: string;
};

export async function getStorageContext(
  db: D1Database,
  firebaseUid: string,
  environment?: string,
): Promise<StorageContext | null> {
  const row = await db
    .prepare(
      `SELECT u.storage_used_bytes, p.quota_bytes AS plan_quota_bytes,
              u.quota_bytes_override, p.max_file_size_bytes,
              u.max_file_size_bytes_override, u.plan_code
       FROM users u
       INNER JOIN plans p ON p.code = u.plan_code
       WHERE u.firebase_uid = ?`,
    )
    .bind(firebaseUid)
    .first<StorageRow>();
  if (!row) return null;
  return {
    storageUsedBytes: row.storage_used_bytes,
    quotaBytes: resolveQuotaBytes(
      row.plan_quota_bytes,
      row.quota_bytes_override,
      environment,
    ),
    maxFileSizeBytes: resolveMaxFileBytes(
      row.max_file_size_bytes,
      row.max_file_size_bytes_override,
      environment,
    ),
    planCode: row.plan_code,
  };
}

export async function createPendingFile(
  db: D1Database,
  input: {
    id: string;
    firebaseUid: string;
    name: string;
    sizeBytes: number;
    mimeType?: string;
    folderId?: string;
  },
): Promise<{ r2ObjectKey: string; file: FileDto }> {
  const safeName = sanitizeFileName(input.name);
  const r2ObjectKey = buildR2ObjectKey(input.firebaseUid, input.id, safeName);

  await db
    .prepare(
      `INSERT INTO files (
         id, firebase_uid, folder_id, name, mime_type, size_bytes, r2_object_key, status
       ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
    )
    .bind(
      input.id,
      input.firebaseUid,
      input.folderId ?? null,
      safeName,
      input.mimeType ?? null,
      input.sizeBytes,
      r2ObjectKey,
    )
    .run();

  const row = await getFileById(db, input.id, input.firebaseUid);
  if (!row) throw new Error('Falha ao criar metadado do ficheiro.');
  return { r2ObjectKey, file: mapFileDto(row) };
}

export async function getFileById(
  db: D1Database,
  fileId: string,
  firebaseUid: string,
): Promise<FileRow | null> {
  return db
    .prepare(
      `SELECT ${FILE_COLUMNS}
       FROM files
       WHERE id = ? AND firebase_uid = ? AND deleted_at IS NULL`,
    )
    .bind(fileId, firebaseUid)
    .first<FileRow>();
}

export async function listActiveFiles(
  db: D1Database,
  firebaseUid: string,
  limit = 100,
): Promise<FileDto[]> {
  const { results } = await db
    .prepare(
      `SELECT ${FILE_COLUMNS}
       FROM files
       WHERE firebase_uid = ? AND status = 'active' AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .bind(firebaseUid, limit)
    .all<FileRow>();

  return (results ?? []).map(mapFileDto);
}

export async function activateFile(
  db: D1Database,
  input: {
    fileId: string;
    firebaseUid: string;
    actualSizeBytes: number;
  },
): Promise<FileDto | null> {
  const existing = await getFileById(db, input.fileId, input.firebaseUid);
  if (!existing || existing.status !== 'pending') return null;

  await db.batch([
    db
      .prepare(
        `UPDATE files SET
           status = 'active',
           size_bytes = ?,
           updated_at = datetime('now')
         WHERE id = ? AND firebase_uid = ?`,
      )
      .bind(input.actualSizeBytes, input.fileId, input.firebaseUid),
    db
      .prepare(
        `UPDATE users SET
           storage_used_bytes = storage_used_bytes + ?,
           updated_at = datetime('now')
         WHERE firebase_uid = ?`,
      )
      .bind(input.actualSizeBytes, input.firebaseUid),
    db
      .prepare(
        `INSERT INTO file_actions (firebase_uid, file_id, action, metadata_json)
         VALUES (?, ?, 'upload', ?)`,
      )
      .bind(
        input.firebaseUid,
        input.fileId,
        JSON.stringify({ sizeBytes: input.actualSizeBytes }),
      ),
  ]);

  const row = await getFileById(db, input.fileId, input.firebaseUid);
  return row ? mapFileDto(row) : null;
}

export async function setFileThumbnailKey(
  db: D1Database,
  fileId: string,
  firebaseUid: string,
  thumbR2ObjectKey: string,
): Promise<FileDto | null> {
  const existing = await getFileById(db, fileId, firebaseUid);
  if (!existing || existing.status !== 'active') return null;

  await db
    .prepare(
      `UPDATE files SET
         thumb_r2_object_key = ?,
         updated_at = datetime('now')
       WHERE id = ? AND firebase_uid = ?`,
    )
    .bind(thumbR2ObjectKey, fileId, firebaseUid)
    .run();

  const row = await getFileById(db, fileId, firebaseUid);
  return row ? mapFileDto(row) : null;
}

export async function logDownload(
  db: D1Database,
  firebaseUid: string,
  fileId: string,
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO file_actions (firebase_uid, file_id, action)
       VALUES (?, ?, 'download')`,
    )
    .bind(firebaseUid, fileId)
    .run();
}

export async function renameFile(
  db: D1Database,
  input: {
    fileId: string;
    firebaseUid: string;
    newName: string;
  },
): Promise<FileDto | null> {
  const safeName = sanitizeFileName(input.newName);
  if (!safeName) return null;

  const existing = await getFileById(db, input.fileId, input.firebaseUid);
  if (!existing || existing.status !== 'active') return null;

  const duplicate = await db
    .prepare(
      `SELECT id FROM files
       WHERE firebase_uid = ? AND name = ? AND status = 'active'
         AND deleted_at IS NULL AND id != ?`,
    )
    .bind(input.firebaseUid, safeName, input.fileId)
    .first<{ id: string }>();

  if (duplicate) {
    throw new Error('DUPLICATE_NAME');
  }

  await db.batch([
    db
      .prepare(
        `UPDATE files SET name = ?, updated_at = datetime('now')
         WHERE id = ? AND firebase_uid = ?`,
      )
      .bind(safeName, input.fileId, input.firebaseUid),
    db
      .prepare(
        `INSERT INTO file_actions (firebase_uid, file_id, action, metadata_json)
         VALUES (?, ?, 'rename', ?)`,
      )
      .bind(
        input.firebaseUid,
        input.fileId,
        JSON.stringify({ newName: safeName }),
      ),
  ]);

  const row = await getFileById(db, input.fileId, input.firebaseUid);
  return row ? mapFileDto(row) : null;
}

export async function softDeleteFile(
  db: D1Database,
  fileId: string,
  firebaseUid: string,
): Promise<FileRow | null> {
  const existing = await getFileById(db, fileId, firebaseUid);
  if (!existing || existing.status !== 'active') return null;

  await db.batch([
    db
      .prepare(
        `UPDATE files SET
           status = 'deleted',
           deleted_at = datetime('now'),
           updated_at = datetime('now')
         WHERE id = ? AND firebase_uid = ?`,
      )
      .bind(fileId, firebaseUid),
    db
      .prepare(
        `UPDATE users SET
           storage_used_bytes = MAX(0, storage_used_bytes - ?),
           updated_at = datetime('now')
         WHERE firebase_uid = ?`,
      )
      .bind(existing.size_bytes, firebaseUid),
    db
      .prepare(
        `INSERT INTO file_actions (firebase_uid, file_id, action)
         VALUES (?, ?, 'delete')`,
      )
      .bind(firebaseUid, fileId),
  ]);

  return existing;
}

export async function getFileRowAny(
  db: D1Database,
  fileId: string,
  firebaseUid: string,
): Promise<FileRow | null> {
  return db
    .prepare(
      `SELECT ${FILE_COLUMNS}
       FROM files
       WHERE id = ? AND firebase_uid = ?`,
    )
    .bind(fileId, firebaseUid)
    .first<FileRow>();
}

export async function listTrashFiles(
  db: D1Database,
  firebaseUid: string,
  limit = 100,
): Promise<(FileDto & { deletedAt: string })[]> {
  const { results } = await db
    .prepare(
      `SELECT ${FILE_COLUMNS}, deleted_at
       FROM files
       WHERE firebase_uid = ? AND status = 'deleted' AND deleted_at IS NOT NULL
       ORDER BY deleted_at DESC
       LIMIT ?`,
    )
    .bind(firebaseUid, limit)
    .all<FileRow & { deleted_at: string }>();

  return (results ?? []).map((row) => ({
    ...mapFileDto(row),
    deletedAt: row.deleted_at,
  }));
}

export async function restoreFile(
  db: D1Database,
  fileId: string,
  firebaseUid: string,
  environment?: string,
): Promise<FileDto | null> {
  const row = await getFileRowAny(db, fileId, firebaseUid);
  if (!row || row.status !== 'deleted') return null;

  const ctx = await getStorageContext(db, firebaseUid, environment);
  if (!ctx) return null;
  if (
    !isLocalUnlimitedMode(environment) &&
    ctx.storageUsedBytes + row.size_bytes > ctx.quotaBytes
  ) {
    throw new Error('QUOTA_EXCEEDED');
  }

  await db.batch([
    db
      .prepare(
        `UPDATE files SET
           status = 'active',
           deleted_at = NULL,
           updated_at = datetime('now')
         WHERE id = ? AND firebase_uid = ?`,
      )
      .bind(fileId, firebaseUid),
    db
      .prepare(
        `UPDATE users SET
           storage_used_bytes = storage_used_bytes + ?,
           updated_at = datetime('now')
         WHERE firebase_uid = ?`,
      )
      .bind(row.size_bytes, firebaseUid),
    db
      .prepare(
        `INSERT INTO file_actions (firebase_uid, file_id, action)
         VALUES (?, ?, 'restore')`,
      )
      .bind(firebaseUid, fileId),
  ]);

  const updated = await getFileById(db, fileId, firebaseUid);
  return updated ? mapFileDto(updated) : null;
}

export async function permanentDeleteFile(
  db: D1Database,
  fileId: string,
  firebaseUid: string,
): Promise<FileRow | null> {
  const row = await getFileRowAny(db, fileId, firebaseUid);
  if (!row || row.status !== 'deleted') return null;

  await db
    .prepare(
      `DELETE FROM files WHERE id = ? AND firebase_uid = ? AND status = 'deleted'`,
    )
    .bind(fileId, firebaseUid)
    .run();

  await db
    .prepare(
      `INSERT INTO file_actions (firebase_uid, file_id, action)
       VALUES (?, ?, 'permanent_delete')`,
    )
    .bind(firebaseUid, fileId)
    .run();

  return row;
}
