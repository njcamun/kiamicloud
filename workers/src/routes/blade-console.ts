import { Hono } from 'hono';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import type { Env } from '../types';
import { BLADE_CONSOLE_HTML } from '../blade-console/html';
import {
  bladeConsoleCredentials,
  isBladeConsoleEnabled,
  requireBladeConsoleSession,
} from '../middleware/blade-console-auth';
import {
  BLADE_CONSOLE_COOKIE,
  SESSION_MAX_AGE_SEC,
  createBladeConsoleSession,
  verifyBladeConsoleSession,
} from '../lib/blade-console-session';
import {
  getPlatformStats,
  listActivityFeedAdmin,
  listFilesGroupedByUserAdmin,
  listRecentlyActiveUsersAdmin,
  listSecurityEventsAdmin,
} from '../db/admin';
import { getClientIp, hashIp } from '../lib/client-ip';
import { checkRateLimit } from '../db/rate-limit';
import { logSecurityEvent } from '../db/security';

/** Consola web local — apenas ambiente development (ZimaBlade). */
export const bladeConsoleRoutes = new Hono<{ Bindings: Env }>();

function serveConsoleHtml(c: { html: (s: string) => Response; header: (n: string, v: string) => void }) {
  c.header('Cache-Control', 'no-store');
  return c.html(BLADE_CONSOLE_HTML);
}

bladeConsoleRoutes.get('/', (c) => {
  if (!isBladeConsoleEnabled(c.env)) {
    return c.text('Not found', 404);
  }
  return serveConsoleHtml(c);
});

bladeConsoleRoutes.post('/login', async (c) => {
  if (!isBladeConsoleEnabled(c.env)) {
    return c.text('Not found', 404);
  }

  const creds = bladeConsoleCredentials(c.env)!;
  const ip = getClientIp(c);
  const ipHash = await hashIp(ip);
  const bucket = `ip:${ip}:blade_console_login`;
  const rl = await checkRateLimit(c.env.DB, bucket, 10, 60);
  if (!rl.allowed) {
    return c.json(
      {
        error: 'rate_limited',
        message: 'Demasiadas tentativas. Aguarde um minuto.',
      },
      429,
    );
  }

  let body: { username?: string; password?: string };
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'invalid_request', message: 'JSON invalido.' }, 400);
  }

  const username = body.username?.trim() ?? '';
  const password = body.password ?? '';
  if (username !== creds.user || password !== creds.password) {
    c.executionCtx.waitUntil(
      logSecurityEvent(c.env.DB, {
        eventType: 'auth_failed',
        ipHash,
        path: '/blade-console/login',
        metadata: { reason: 'blade_console_login' },
      }),
    );
    return c.json(
      { error: 'unauthorized', message: 'Utilizador ou password incorrectos.' },
      401,
    );
  }

  const token = await createBladeConsoleSession(creds.user, creds.password);
  setCookie(c, BLADE_CONSOLE_COOKIE, token, {
    path: '/',
    httpOnly: true,
    sameSite: 'Lax',
    maxAge: SESSION_MAX_AGE_SEC,
  });

  return c.json({ ok: true, user: creds.user, message: 'Sessao iniciada.' });
});

bladeConsoleRoutes.post('/logout', (c) => {
  deleteCookie(c, BLADE_CONSOLE_COOKIE, { path: '/' });
  return c.json({ ok: true });
});

bladeConsoleRoutes.get('/session', async (c) => {
  if (!isBladeConsoleEnabled(c.env)) {
    return c.text('Not found', 404);
  }

  const creds = bladeConsoleCredentials(c.env)!;
  const token = getCookie(c, BLADE_CONSOLE_COOKIE);
  const ok =
    !!token &&
    (await verifyBladeConsoleSession(token, creds.user, creds.password));
  if (!ok) {
    return c.json({ ok: false }, 401);
  }
  return c.json({ ok: true, user: creds.user });
});

const api = new Hono<{ Bindings: Env }>();
api.use('/*', requireBladeConsoleSession);

api.get('/stats', async (c) => {
  const stats = await getPlatformStats(c.env.DB, c.env.ENVIRONMENT);
  return c.json({ stats });
});

api.get('/activity/feed', async (c) => {
  const limit = Number(c.req.query('limit') ?? 60) || 60;
  const feed = await listActivityFeedAdmin(c.env.DB, limit);
  return c.json({ feed });
});

api.get('/activity/active-users', async (c) => {
  const minutes = Number(c.req.query('minutes') ?? 30) || 30;
  const users = await listRecentlyActiveUsersAdmin(c.env.DB, minutes);
  return c.json({ users, windowMinutes: minutes });
});

api.get('/security-events', async (c) => {
  const limit = Number(c.req.query('limit') ?? 30) || 30;
  const events = await listSecurityEventsAdmin(c.env.DB, limit);
  return c.json({ events });
});

api.get('/files-by-user', async (c) => {
  const limitPerUser = Number(c.req.query('limitPerUser') ?? 100) || 100;
  const users = await listFilesGroupedByUserAdmin(c.env.DB, limitPerUser);
  return c.json({ users });
});

bladeConsoleRoutes.route('/api', api);

bladeConsoleRoutes.get('/*', (c) => {
  if (!isBladeConsoleEnabled(c.env)) {
    return c.text('Not found', 404);
  }
  return serveConsoleHtml(c);
});
