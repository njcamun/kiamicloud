import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { AppVariables, Env } from './types';
import { kiamiCors } from './middleware/cors';
import { securityHeaders } from './middleware/security-headers';
import { rateLimitByIp } from './middleware/rate-limit';
import { healthRoutes } from './routes/health';
import { meRoutes } from './routes/me';
import { plansRoutes } from './routes/plans';
import { filesRoutes } from './routes/files';
import { auditRoutes } from './routes/audit';
import { accountActivityRoutes } from './routes/account_activity';
import { billingRoutes } from './routes/billing';
import { adminRoutes } from './routes/admin';
import { betaRoutes } from './routes/beta';
import { supportRoutes } from './routes/support';
import { bladeConsoleRoutes } from './routes/blade-console';
import { runTrashPurge } from './scheduled/trash_purge';
import { runSubscriptionLifecycleJob } from './scheduled/subscription_lifecycle';

const app = new Hono<{ Bindings: Env; Variables: AppVariables }>();

app.use('*', securityHeaders());
app.use('*', kiamiCors());
app.use('*', rateLimitByIp);

app.route('/health', healthRoutes);
app.route('/me/audit', auditRoutes);
app.route('/me/activity', accountActivityRoutes);
app.route('/me/support', supportRoutes);
app.route('/me', meRoutes);
app.route('/plans', plansRoutes);
app.route('/files', filesRoutes);
app.route('/billing', billingRoutes);
app.route('/admin', adminRoutes);
app.route('/beta', betaRoutes);
app.route('/blade-console', bladeConsoleRoutes);

app.get('/', (c) =>
  c.json({
    name: 'KiamiCloud API',
    slogan: 'Minha Cloud. Meu mundo. Sem limites.',
    endpoints: {
      health: 'GET /health',
      healthPing: 'GET /health/ping',
      plans: 'GET /plans',
      me: 'GET|DELETE /me (Bearer) — perfil; DELETE com { confirm: "APAGAR" }',
      files:
        'GET|POST|PATCH|DELETE /files/* (Bearer) — upload, download, renomear, apagar',
      audit: 'GET /me/audit (Bearer) — historico de accoes',
      activity:
        'GET /me/activity (Bearer) — suporte, billing e notificacoes',
      billing:
        'GET|POST /billing/* (Bearer) — planos, checkout; POST /billing/webhook (secret)',
      admin: 'GET|PATCH /admin/* (Bearer + ADMIN_UIDS) — painel administrativo',
      bladeConsole:
        'GET /blade-console/* (development) — consola LAN; POST /blade-console/login',
      beta: 'GET /beta/info | POST /beta/feedback (Bearer)',
    },
  }),
);

app.notFound((c) =>
  c.json({ error: 'not_found', path: new URL(c.req.url).pathname }, 404),
);

app.onError((err, c) => {
  if (err instanceof HTTPException) {
    return err.getResponse();
  }
  console.error('[kiamicloud-api]', err);
  return c.json(
    {
      error: 'internal_error',
      message: 'Erro interno do servidor.',
    },
    500,
  );
});

export default {
  fetch: app.fetch,
  scheduled(
    _event: ScheduledEvent,
    env: Env,
    ctx: ExecutionContext,
  ): void {
    ctx.waitUntil(
      Promise.all([
        runTrashPurge(env).catch((err) => {
          console.error('[trash-purge] scheduled failed', err);
        }),
        runSubscriptionLifecycleJob(env).catch((err) => {
          console.error('[subscription-lifecycle] scheduled failed', err);
        }),
      ]),
    );
  },
};
