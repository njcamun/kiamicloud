import { createMiddleware } from 'hono/factory';
import type { AppVariables, Env } from '../types';
import { isAdminUid } from '../config/admin';
import { logSecurityEvent } from '../db/security';

/**
 * Exige utilizador autenticado listado em ADMIN_UIDS.
 * Deve correr depois de requireAuth.
 */
export const requireAdmin = createMiddleware<{
  Bindings: Env;
  Variables: AppVariables;
}>(async (c, next) => {
  const user = c.get('user');
  if (!isAdminUid(user.uid, c.env.ADMIN_UIDS)) {
    c.executionCtx.waitUntil(
      logSecurityEvent(c.env.DB, {
        eventType: 'auth_failed',
        firebaseUid: user.uid,
        path: new URL(c.req.url).pathname,
        metadata: { reason: 'admin_forbidden' },
      }),
    );
    return c.json(
      {
        error: 'forbidden',
        message: 'Acesso reservado a administradores.',
      },
      403,
    );
  }
  await next();
});
