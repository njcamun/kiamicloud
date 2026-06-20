import type { Context } from 'hono';
import type { AppVariables, Env } from '../types';
import { getStorageContext } from '../db/files';
import { resolveSubscriptionAccessForUser } from '../db/subscriptions';
import { subscriptionBlockMessage } from '../lib/subscription-access';

type AccessAction = 'upload' | 'download';

export async function enforceSubscriptionAccess(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  action: AccessAction,
): Promise<Response | null> {
  const user = c.get('user');
  const storage = await getStorageContext(
    c.env.DB,
    user.uid,
    c.env.ENVIRONMENT,
  );
  if (!storage) {
    return c.json({ error: 'not_found', message: 'Utilizador nao encontrado.' }, 404);
  }

  const access = await resolveSubscriptionAccessForUser(c.env.DB, {
    firebaseUid: user.uid,
    planCode: storage.planCode,
    storageUsedBytes: storage.storageUsedBytes,
    quotaBytes: storage.quotaBytes,
    environment: c.env.ENVIRONMENT,
  });

  const allowed =
    action === 'upload' ? access.canUpload : access.canDownload;

  if (allowed) return null;

  return c.json(
    {
      error: access.blockReason ?? 'subscription_blocked',
      message: subscriptionBlockMessage(access.blockReason),
      access,
    },
    403,
  );
}
