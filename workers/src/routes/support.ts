import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { requireCloudSupportChat } from '../middleware/cloud-support';
import { rateLimitByUser } from '../middleware/rate-limit';
import { ensureUser } from '../db/users';
import {
  listSupportMessagesForUser,
  markSupportReadByUser,
  sendSupportMessageAsUser,
} from '../db/support_chat';

export const supportRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

supportRoutes.use('/*', requireAuth);
supportRoutes.use('/*', requireCloudSupportChat);
supportRoutes.use('/*', rateLimitByUser);

supportRoutes.get('/messages', async (c) => {
  const user = c.get('user');
  const db = c.env.DB;
  if (!db) {
    return c.json(
      { error: 'server_misconfigured', message: 'Base D1 nao configurada.' },
      500,
    );
  }
  await ensureUser(db, user);
  const result = await listSupportMessagesForUser(db, user.uid);
  return c.json(result);
});

supportRoutes.post('/messages', async (c) => {
  const user = c.get('user');
  const db = c.env.DB;
  if (!db) {
    return c.json(
      { error: 'server_misconfigured', message: 'Base D1 nao configurada.' },
      500,
    );
  }
  const body = await c.req.json<{ message?: string }>();
  const message = body.message?.trim();
  if (!message || message.length < 2) {
    return c.json(
      { error: 'invalid_request', message: 'Mensagem em falta (minimo 2 caracteres).' },
      400,
    );
  }
  if (message.length > 4000) {
    return c.json(
      { error: 'invalid_request', message: 'Mensagem demasiado longa.' },
      400,
    );
  }
  await ensureUser(db, user);
  const saved = await sendSupportMessageAsUser(db, {
    firebaseUid: user.uid,
    senderUid: user.uid,
    message,
  });
  return c.json({ message: saved });
});

supportRoutes.post('/read', async (c) => {
  const user = c.get('user');
  const db = c.env.DB;
  if (!db) {
    return c.json(
      { error: 'server_misconfigured', message: 'Base D1 nao configurada.' },
      500,
    );
  }
  await ensureUser(db, user);
  await markSupportReadByUser(db, user.uid);
  return c.json({ ok: true });
});
