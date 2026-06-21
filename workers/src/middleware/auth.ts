import { createMiddleware } from 'hono/factory';
import type { AppVariables, AuthUser, Env } from '../types';
import { verifyFirebaseIdToken } from '../lib/firebase-jwt';
import { getClientIp, getIpHashPepper, hashIp } from '../lib/client-ip';
import { logSecurityEvent } from '../db/security';
import { checkRateLimit } from '../db/rate-limit';
import { RATE_LIMITS } from '../config/rate-limits';

/**
 * Exige Authorization: Bearer <Firebase idToken>.
 * Define c.get('user') com uid e claims.
 */
export const requireAuth = createMiddleware<{
  Bindings: Env;
  Variables: AppVariables;
}>(async (c, next) => {
  const header = c.req.header('Authorization');
  if (!header?.startsWith('Bearer ')) {
    return c.json(
      {
        error: 'unauthorized',
        message: 'Cabecalho Authorization: Bearer <token> em falta.',
      },
      401,
    );
  }

  const token = header.slice('Bearer '.length).trim();
  if (!token) {
    return c.json({ error: 'unauthorized', message: 'Token vazio.' }, 401);
  }

  const projectId = c.env.FIREBASE_PROJECT_ID;
  if (!projectId) {
    return c.json(
      { error: 'server_misconfigured', message: 'FIREBASE_PROJECT_ID em falta.' },
      500,
    );
  }

  try {
    const payload = await verifyFirebaseIdToken(token, projectId);
    const user: AuthUser = {
      uid: payload.sub!,
      email: typeof payload.email === 'string' ? payload.email : undefined,
      emailVerified: payload.email_verified === true,
      name: typeof payload.name === 'string' ? payload.name : undefined,
      picture: typeof payload.picture === 'string' ? payload.picture : undefined,
    };
    c.set('user', user);
    await next();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Token invalido';
    const db = c.env.DB;
    if (db) {
      const ip = getClientIp(c);
      const ipHash = await hashIp(ip, getIpHashPepper(c.env));
      const failBucket = `ip:${ip}:auth_fail`;
      const failRl = await checkRateLimit(
        db,
        failBucket,
        RATE_LIMITS.ipAuthFailPerMinute,
        60,
      );
      c.executionCtx.waitUntil(
        logSecurityEvent(db, {
          eventType: 'auth_failed',
          ipHash,
          path: new URL(c.req.url).pathname,
          metadata: { rateLimited: !failRl.allowed },
        }),
      );
      if (!failRl.allowed) {
        return c.json(
          {
            error: 'rate_limited',
            message: 'Demasiadas tentativas invalidas. Aguarde um minuto.',
            retryAfterSeconds: failRl.retryAfterSeconds,
          },
          429,
        );
      }
    }
    return c.json(
      {
        error: 'invalid_token',
        message: 'Token Firebase invalido ou expirado.',
        detail: c.env.ENVIRONMENT === 'development' ? message : undefined,
      },
      401,
    );
  }
});
