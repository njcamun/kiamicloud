import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { rateLimitByUser } from '../middleware/rate-limit';
import { listFileActions } from '../db/security';

export const auditRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

auditRoutes.use('/*', requireAuth);
auditRoutes.use('/*', rateLimitByUser);

/** Historico de accoes do utilizador (upload, download, rename, delete). */
auditRoutes.get('/', async (c) => {
  const user = c.get('user');
  const limit = Math.min(
    100,
    Math.max(1, Number(c.req.query('limit') ?? 50) || 50),
  );
  const actions = await listFileActions(c.env.DB, user.uid, limit);
  return c.json({ actions });
});
