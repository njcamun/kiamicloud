import { createMiddleware } from 'hono/factory';
import type { AppVariables, Env } from '../types';
import { RATE_LIMITS } from '../config/rate-limits';
import { checkRateLimit } from '../db/rate-limit';
import { logSecurityEvent } from '../db/security';
import { getClientIp, getIpHashPepper, hashIp } from '../lib/client-ip';

/** Rate limit global por IP (antes de auth). */
export const rateLimitByIp = createMiddleware<{ Bindings: Env }>(
  async (c, next) => {
    const db = c.env.DB;
    if (!db) {
      await next();
      return;
    }

    const ip = getClientIp(c);
    const path = new URL(c.req.url).pathname;
    const bucketKey = `ip:${ip}:global`;
    const result = await checkRateLimit(
      db,
      bucketKey,
      RATE_LIMITS.ipGlobalPerMinute,
      60,
    );

    if (!result.allowed) {
      const ipHash = await hashIp(ip, getIpHashPepper(c.env));
      c.executionCtx.waitUntil(
        logSecurityEvent(db, {
          eventType: 'rate_limited',
          ipHash,
          path,
          metadata: { bucket: 'ip_global' },
        }),
      );
      return c.json(
        {
          error: 'rate_limited',
          message: 'Demasiados pedidos. Tente novamente em breve.',
          retryAfterSeconds: result.retryAfterSeconds ?? 60,
        },
        429,
        { 'Retry-After': String(result.retryAfterSeconds ?? 60) },
      );
    }

    c.header('X-RateLimit-Remaining', String(result.remaining));
    await next();
  },
);

/** Rate limit por utilizador autenticado. */
export const rateLimitByUser = createMiddleware<{
  Bindings: Env;
  Variables: AppVariables;
}>(async (c, next) => {
  const db = c.env.DB;
  const user = c.get('user');
  if (!db || !user) {
    await next();
    return;
  }

  const path = new URL(c.req.url).pathname;
  const isUploadInit =
    c.req.method === 'POST' && path.endsWith('/upload/init');

  const bucketKey = isUploadInit
    ? `uid:${user.uid}:upload_init`
    : `uid:${user.uid}:api`;
  const limit = isUploadInit
    ? RATE_LIMITS.userUploadInitPerHour
    : RATE_LIMITS.userApiPerMinute;
  const windowSeconds = isUploadInit ? 3600 : 60;

  const result = await checkRateLimit(db, bucketKey, limit, windowSeconds);
  if (!result.allowed) {
    c.executionCtx.waitUntil(
      logSecurityEvent(db, {
        eventType: 'rate_limited',
        firebaseUid: user.uid,
        path,
        metadata: { bucket: bucketKey },
      }),
    );
    return c.json(
      {
        error: 'rate_limited',
        message: 'Demasiados pedidos. Tente novamente em breve.',
        retryAfterSeconds: result.retryAfterSeconds ?? windowSeconds,
      },
      429,
      { 'Retry-After': String(result.retryAfterSeconds ?? windowSeconds) },
    );
  }

  await next();
});
