import {
  TRASH_PURGE_BATCH_SIZE,
  TRASH_RETENTION_DAYS,
} from '../config/trash';
import { deleteR2Objects } from '../lib/delete-r2-keys';
import type { FileRow } from './files';
import { permanentDeleteFile } from './files';

export type TrashPurgeResult = {
  scanned: number;
  purged: number;
  r2Deleted: number;
  errors: number;
};

export async function listExpiredTrashFiles(
  db: D1Database,
  limit: number,
): Promise<FileRow[]> {
  const { results } = await db
    .prepare(
      `SELECT id, firebase_uid, folder_id, name, mime_type, size_bytes,
              r2_object_key, thumb_r2_object_key, status, created_at, updated_at
       FROM files
       WHERE status = 'deleted'
         AND deleted_at IS NOT NULL
         AND deleted_at < datetime('now', ?)
       ORDER BY deleted_at ASC
       LIMIT ?`,
    )
    .bind(`-${TRASH_RETENTION_DAYS} days`, limit)
    .all<FileRow>();

  return results ?? [];
}

export async function purgeExpiredTrashBatch(
  db: D1Database,
  bucket: R2Bucket,
  rows: FileRow[],
): Promise<TrashPurgeResult> {
  const result: TrashPurgeResult = {
    scanned: rows.length,
    purged: 0,
    r2Deleted: 0,
    errors: 0,
  };

  for (const row of rows) {
    try {
      const deleted = await permanentDeleteFile(db, row.id, row.firebase_uid);
      if (!deleted) {
        result.errors += 1;
        continue;
      }

      result.purged += 1;

      const keys = [deleted.r2_object_key, deleted.thumb_r2_object_key];
      await deleteR2Objects(bucket, keys);
      if (deleted.r2_object_key) result.r2Deleted += 1;
      if (deleted.thumb_r2_object_key) result.r2Deleted += 1;
    } catch (err) {
      result.errors += 1;
      console.error('[trash-purge] file', row.id, err);
    }
  }

  return result;
}

export async function purgeAllExpiredTrash(
  db: D1Database,
  bucket: R2Bucket,
  maxBatches: number,
): Promise<TrashPurgeResult> {
  const total: TrashPurgeResult = {
    scanned: 0,
    purged: 0,
    r2Deleted: 0,
    errors: 0,
  };

  for (let batch = 0; batch < maxBatches; batch += 1) {
    const rows = await listExpiredTrashFiles(db, TRASH_PURGE_BATCH_SIZE);
    if (rows.length === 0) break;

    const partial = await purgeExpiredTrashBatch(db, bucket, rows);
    total.scanned += partial.scanned;
    total.purged += partial.purged;
    total.r2Deleted += partial.r2Deleted;
    total.errors += partial.errors;

    if (rows.length < TRASH_PURGE_BATCH_SIZE) break;
  }

  return total;
}
