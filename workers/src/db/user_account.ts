import { deleteR2Objects } from '../lib/delete-r2-keys';

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
