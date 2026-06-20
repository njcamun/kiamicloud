import { Hono } from 'hono';

import type { AppVariables, Env } from '../types';

import { requireAuth } from '../middleware/auth';

import { rateLimitByUser } from '../middleware/rate-limit';

import { deleteUserAccount } from '../db/user_account';

import { ensureUser, getUserProfileWithOverrides } from '../db/users';

import { computeQuotaInfo } from '../lib/quota';

import { buildMeProfileResponse } from '../lib/profile_response';

import { isLocalTransferUnlimited, isLocalUnlimitedMode, unlimitedQuotaInfo, LOCAL_UNLIMITED_QUOTA_BYTES } from '../lib/local_unlimited';

import { getSubscriptionDto, resolveSubscriptionAccessForUser } from '../db/subscriptions';



export const meRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();



meRoutes.use('/*', requireAuth);

meRoutes.use('/*', rateLimitByUser);



meRoutes.get('/', async (c) => {

  const auth = c.get('user');

  const db = c.env.DB;



  if (!db) {

    return c.json(

      { error: 'server_misconfigured', message: 'Base D1 nao configurada.' },

      500,

    );

  }



  await ensureUser(db, auth);

  const row = await getUserProfileWithOverrides(db, auth.uid);

  if (!row) {

    return c.json(

      { error: 'not_found', message: 'Perfil nao encontrado.' },

      404,

    );

  }



  const body = buildMeProfileResponse(row, {

    quotaBytesOverride: row.quotaBytesOverride,

    maxFileSizeBytesOverride: row.maxFileSizeBytesOverride,

  });

  const localUnlimited = isLocalUnlimitedMode(c.env.ENVIRONMENT);
  const quotaBytesOut = localUnlimited
    ? LOCAL_UNLIMITED_QUOTA_BYTES
    : body.plan.quotaBytes;
  const storageAvailableOut = localUnlimited
    ? Math.max(0, LOCAL_UNLIMITED_QUOTA_BYTES - body.storageUsedBytes)
    : body.storageAvailableBytes;
  const quota = localUnlimited
    ? unlimitedQuotaInfo()
    : computeQuotaInfo(body.storageUsedBytes, quotaBytesOut);

  // Servidor local: 0 = sem limite de transferência por ficheiro.
  const transferUnlimited = isLocalTransferUnlimited(c.env.ENVIRONMENT);
  const maxFileSizeBytes = transferUnlimited ? 0 : body.plan.maxFileSizeBytes;
  const planOut = transferUnlimited
    ? { ...body.plan, maxFileSizeBytes: 0, quotaBytes: quotaBytesOut }
    : { ...body.plan, quotaBytes: quotaBytesOut };

  const subscription = localUnlimited
    ? null
    : await getSubscriptionDto(db, auth.uid);
  const access = localUnlimited
    ? {
        canUpload: true,
        canDownload: true,
        status: 'active',
        effectiveStatus: 'active',
        blockReason: null,
        storageOverQuota: false,
      }
    : await resolveSubscriptionAccessForUser(db, {
        firebaseUid: auth.uid,
        planCode: planOut.code,
        storageUsedBytes: body.storageUsedBytes,
        quotaBytes: quotaBytesOut,
        environment: c.env.ENVIRONMENT,
      });

  return c.json(
    {
      uid: body.uid,
      email: body.email,
      emailVerified: auth.emailVerified ?? false,
      displayName: body.displayName,
      photoUrl: body.photoUrl,
      plan: planOut,
      quotaBytes: quotaBytesOut,
      storageUsedBytes: body.storageUsedBytes,
      storageAvailableBytes: storageAvailableOut,
      maxFileSizeBytes,
      quotaBytesOverride: body.quotaBytesOverride,
      maxFileSizeBytesOverride: body.maxFileSizeBytesOverride,
      quota,
      subscription,
      access,
      canSwitchApiEndpoint: body.canSwitchApiEndpoint,
      createdAt: body.createdAt,
      updatedAt: body.updatedAt,
    },
    200,
    { 'Cache-Control': 'no-store' },
  );
});



/** Elimina conta e todos os dados na cloud (D1 + R2). */

meRoutes.delete('/', async (c) => {

  const user = c.get('user');

  const body = (await c.req

    .json<{ confirm?: string }>()

    .catch(() => ({ confirm: undefined }))) as { confirm?: string };

  const confirm = typeof body.confirm === 'string' ? body.confirm.trim() : '';



  if (confirm !== 'APAGAR') {

    return c.json(

      {

        error: 'invalid_request',

        message: 'Confirme com { "confirm": "APAGAR" }.',

      },

      400,

    );

  }



  await deleteUserAccount(c.env.DB, c.env.FILES_BUCKET, user.uid);



  return c.json({

    ok: true,

    message: 'Conta e dados removidos do KiamiCloud.',

  });

});


