import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { rateLimitByUser } from '../middleware/rate-limit';
import {
  countUnreadAccountEvents,
  listAccountEventsForUser,
  markAccountEventRead,
  markAllAccountEventsRead,
} from '../db/account_events';

export const accountActivityRoutes = new Hono<{
  Bindings: Env;
  Variables: AppVariables;
}>();

accountActivityRoutes.use('/*', requireAuth);
accountActivityRoutes.use('/*', rateLimitByUser);

/** Historico de suporte, billing e notificacoes do utilizador. */
accountActivityRoutes.get('/', async (c) => {
  const user = c.get('user');
  const limit = Math.min(100, Math.max(1, Number(c.req.query('limit') ?? 40) || 40));
  const [events, unreadCount] = await Promise.all([
    listAccountEventsForUser(c.env.DB, user.uid, limit),
    countUnreadAccountEvents(c.env.DB, user.uid),
  ]);
  return c.json({ events, unreadCount });
});

/** Marca uma notificacao como lida. */
accountActivityRoutes.post('/:id/read', async (c) => {
  const user = c.get('user');
  const eventId = Number(c.req.param('id'));
  if (!Number.isFinite(eventId)) {
    return c.json({ error: 'invalid_request', message: 'ID invalido.' }, 400);
  }
  const ok = await markAccountEventRead(c.env.DB, user.uid, eventId);
  if (!ok) {
    return c.json({ error: 'not_found', message: 'Evento nao encontrado.' }, 404);
  }
  const unreadCount = await countUnreadAccountEvents(c.env.DB, user.uid);
  return c.json({ ok: true, unreadCount });
});

/** Marca todas as notificacoes como lidas. */
accountActivityRoutes.post('/read-all', async (c) => {
  const user = c.get('user');
  const marked = await markAllAccountEventsRead(c.env.DB, user.uid);
  return c.json({ ok: true, marked, unreadCount: 0 });
});
