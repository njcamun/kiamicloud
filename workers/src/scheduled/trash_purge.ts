import {
  TRASH_PURGE_MAX_BATCHES,
  TRASH_RETENTION_DAYS,
} from '../config/trash';
import { purgeAllExpiredTrash } from '../db/trash_purge';
import type { Env } from '../types';

export async function runTrashPurge(env: Env): Promise<void> {
  const result = await purgeAllExpiredTrash(
    env.DB,
    env.FILES_BUCKET,
    TRASH_PURGE_MAX_BATCHES,
  );

  console.log(
    JSON.stringify({
      event: 'trash_purge_complete',
      environment: env.ENVIRONMENT ?? 'unknown',
      retentionDays: TRASH_RETENTION_DAYS,
      ...result,
    }),
  );
}
