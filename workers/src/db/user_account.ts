import { deleteR2Objects } from '../lib/delete-r2-keys';
import { ensureUser } from './users';
import { listFileActions } from './security';

export type UserExportPayload = {
  exportedAt: string;
  version: string;
  user: Record<string, unknown>;
  files: Record<string, unknown>[];
  fileActions: Record<string, unknown>[];
  betaFeedback: Record<string, unknown>[];
};

export async function buildUserExport(
  db: D1Database,
  firebaseUid: string,
): Promise<UserExportPayload> {
  const profileRow = await db
    .prepare(
      `SELECT email FROM users WHERE firebase_uid = ?`,
    )
    .bind(firebaseUid)
    .first<{ email: string | null }>();

  const profile = await ensureUser(db, {
    uid: firebaseUid,
    email: profileRow?.email ?? undefined,
  });

  const { results: files } = await db
    .prepare(
      `SELECT id, name, mime_type, size_bytes, status, folder_id,
              r2_object_key, thumb_r2_object_key, created_at, updated_at, deleted_at
       FROM files
       WHERE firebase_uid = ?
       ORDER BY created_at DESC
       LIMIT 2000`,
    )
    .bind(firebaseUid)
    .all<Record<string, unknown>>();

  const actions = await listFileActions(db, firebaseUid, 500);

  let betaFeedback: Record<string, unknown>[] = [];
  try {
    const feedback = await db
      .prepare(
        `SELECT id, message, app_version, platform, created_at
         FROM beta_feedback
         WHERE firebase_uid = ?
         ORDER BY created_at DESC
         LIMIT 200`,
      )
      .bind(firebaseUid)
      .all<Record<string, unknown>>();
    betaFeedback = feedback.results ?? [];
  } catch {
    betaFeedback = [];
  }

  return {
    exportedAt: new Date().toISOString(),
    version: '1',
    user: {
      uid: profile.uid,
      email: profile.email,
      displayName: profile.displayName,
      plan: profile.plan,
      storageUsedBytes: profile.storageUsedBytes,
      storageAvailableBytes: profile.storageAvailableBytes,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    },
    files: (files ?? []).map((row) => ({
      id: row.id,
      name: row.name,
      mimeType: row.mime_type,
      sizeBytes: row.size_bytes,
      status: row.status,
      folderId: row.folder_id,
      hasR2Object: Boolean(row.r2_object_key),
      hasThumbnail: Boolean(row.thumb_r2_object_key),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      deletedAt: row.deleted_at,
    })),
    fileActions: actions.map((a) => ({
      id: a.id,
      action: a.action,
      fileId: a.fileId,
      metadata: a.metadata,
      createdAt: a.createdAt,
    })),
    betaFeedback,
  };
}

async function deleteAllUserR2Objects(
  bucket: R2Bucket,
  firebaseUid: string,
): Promise<void> {
  const prefix = `users/${firebaseUid}/`;
  let cursor: string | undefined;

  do {
    const listed = await bucket.list({ prefix, cursor, limit: 1000 });
    const keys = listed.objects.map((o) => o.key);
    await deleteR2Objects(bucket, keys);
    cursor = listed.truncated ? listed.cursor : undefined;
  } while (cursor);
}

export async function deleteUserAccount(
  db: D1Database,
  bucket: R2Bucket,
  firebaseUid: string,
): Promise<void> {
  const { results: fileRows } = await db
    .prepare(
      `SELECT r2_object_key, thumb_r2_object_key
       FROM files
       WHERE firebase_uid = ?`,
    )
    .bind(firebaseUid)
    .all<{ r2_object_key: string | null; thumb_r2_object_key: string | null }>();

  const keys: string[] = [];
  for (const row of fileRows ?? []) {
    if (row.r2_object_key) keys.push(row.r2_object_key);
    if (row.thumb_r2_object_key) keys.push(row.thumb_r2_object_key);
  }
  await deleteR2Objects(bucket, keys);
  await deleteAllUserR2Objects(bucket, firebaseUid);

  await db
    .prepare(`DELETE FROM users WHERE firebase_uid = ?`)
    .bind(firebaseUid)
    .run();
}
