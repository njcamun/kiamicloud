import { Hono } from 'hono';
import type { Env } from '../types';
import { API_PHASE, API_VERSION } from '../config/version';

export const healthRoutes = new Hono<{ Bindings: Env }>();

/** Ping instantaneo (sem D1) — use para testar se o servidor responde. */
healthRoutes.get('/ping', (c) =>
  c.json({
    status: 'ok',
    ping: true,
    version: API_VERSION,
    environment: c.env.ENVIRONMENT ?? 'unknown',
    timestamp: new Date().toISOString(),
  }),
);

async function checkDatabase(
  db: D1Database,
  timeoutMs = 2000,
): Promise<'ok' | 'error' | 'timeout'> {
  try {
    await Promise.race([
      db.prepare('SELECT 1 AS ok').first(),
      new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('d1_timeout')), timeoutMs),
      ),
    ]);
    return 'ok';
  } catch (e) {
    return e instanceof Error && e.message === 'd1_timeout' ? 'timeout' : 'error';
  }
}

healthRoutes.get('/', async (c) => {
  let database: 'ok' | 'error' | 'timeout' | 'not_configured' =
    'not_configured';
  let storage: 'ok' | 'not_configured' = 'not_configured';
  let r2Presign = false;

  if (c.env.DB) {
    database = await checkDatabase(c.env.DB);
  }

  if (c.env.FILES_BUCKET) {
    storage = 'ok';
  }

  r2Presign = !!(
    c.env.R2_ACCOUNT_ID &&
    c.env.R2_ACCESS_KEY_ID &&
    c.env.R2_SECRET_ACCESS_KEY
  );

  const degraded = database === 'error' || database === 'timeout';
  const env = c.env.ENVIRONMENT ?? 'unknown';
  const isRestrictedHealth = env === 'beta' || env === 'production';

  if (isRestrictedHealth) {
    return c.json({
      status: degraded ? 'degraded' : 'ok',
      service: 'kiamicloud-api',
      version: API_VERSION,
      environment: env,
      database: database === 'ok' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
    });
  }

  return c.json({
    status: degraded ? 'degraded' : 'ok',
    service: 'kiamicloud-api',
    version: API_VERSION,
    phase: API_PHASE,
    environment: c.env.ENVIRONMENT ?? 'unknown',
    firebaseProjectId: c.env.FIREBASE_PROJECT_ID,
    database,
    storage,
    r2PresignConfigured: r2Presign,
    features: [
      'auth',
      'files',
      'quotas',
      'billing-mock',
      'admin',
      'audit',
    ],
    timestamp: new Date().toISOString(),
  });
});
