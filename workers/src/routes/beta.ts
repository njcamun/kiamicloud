import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { rateLimitByUser } from '../middleware/rate-limit';
import { insertAccountEvent } from '../db/account_events';

export const betaRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

/** Informacao publica do programa beta. */
betaRoutes.get('/info', (c) =>
  c.json({
    program: 'KiamiCloud Beta',
    version: '0.5.0-beta',
    environment: c.env.ENVIRONMENT ?? 'unknown',
    feedbackEnabled: true,
    knownLimitations: [
      'Pagamentos em modo mock (sem gateway real)',
      'Upload maximo por ficheiro conforme o plano (15 MB a 150 MB)',
      'Sem partilha publica de links',
      'Pastas ainda nao disponiveis na UI',
    ],
  }),
);

betaRoutes.use('/feedback', requireAuth);
betaRoutes.use('/feedback', rateLimitByUser);

/** Enviar feedback de testador (autenticado). */
betaRoutes.post('/feedback', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{
    message?: string;
    appVersion?: string;
    platform?: string;
    apiBaseUrl?: string;
  }>();

  const message = body.message?.trim();
  if (!message || message.length < 5) {
    return c.json(
      {
        error: 'invalid_request',
        message: 'Mensagem em falta (minimo 5 caracteres).',
      },
      400,
    );
  }
  if (message.length > 4000) {
    return c.json(
      { error: 'invalid_request', message: 'Mensagem demasiado longa.' },
      400,
    );
  }

  await c.env.DB.prepare(
    `INSERT INTO beta_feedback (
       firebase_uid, email, message, app_version, platform, api_base_url
     ) VALUES (?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      user.uid,
      user.email ?? null,
      message,
      body.appVersion ?? null,
      body.platform ?? null,
      body.apiBaseUrl ?? null,
    )
    .run();

  await insertAccountEvent(c.env.DB, {
    firebaseUid: user.uid,
    kind: 'support_sent',
    title: 'Mensagem enviada',
    body: message.length > 120 ? `${message.slice(0, 117)}…` : message,
    metadata: { platform: body.platform ?? null },
    markRead: true,
  });

  return c.json({
    ok: true,
    message: 'Obrigado pelo feedback. A equipa KiamiCloud vai analisar.',
  });
});
