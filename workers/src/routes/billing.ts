import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { rateLimitByUser } from '../middleware/rate-limit';
import { RATE_LIMITS } from '../config/rate-limits';
import { checkRateLimit } from '../db/rate-limit';
import { logSecurityEvent } from '../db/security';
import {
  confirmCheckoutPayment,
  createCheckout,
  getActiveSubscription,
  getCheckoutById,
  listUserCheckouts,
  submitCheckoutProof,
} from '../db/payments';
import { getClientIp, hashIp } from '../lib/client-ip';
import { computeQuotaInfo } from '../lib/quota';
import {
  applyLocalUnlimitedToProfile,
  isLocalUnlimitedMode,
  unlimitedQuotaInfo,
} from '../lib/local_unlimited';
import { ensureUser } from '../db/users';
import { getPlanByCode } from '../config/plans';
import { PAYMENT_INSTRUCTIONS } from '../config/payment-instructions';

export const billingRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

/** Webhook publico (sem Bearer). */
billingRoutes.post('/webhook', async (c) => {
  const db = c.env.DB;
  const secret = c.env.PAYMENT_WEBHOOK_SECRET;
  if (!secret) {
    return c.json(
      {
        error: 'server_misconfigured',
        message: 'PAYMENT_WEBHOOK_SECRET nao configurado.',
      },
      500,
    );
  }

  const ip = getClientIp(c);
  const ipHash = await hashIp(ip);
  const rl = await checkRateLimit(
    db,
    `ip:${ip}:webhook`,
    RATE_LIMITS.webhookPerMinute,
    60,
  );
  if (!rl.allowed) {
    return c.json(
      {
        error: 'rate_limited',
        message: 'Demasiados pedidos ao webhook.',
        retryAfterSeconds: rl.retryAfterSeconds,
      },
      429,
    );
  }

  const headerSecret = c.req.header('X-Kiami-Webhook-Secret');
  if (headerSecret !== secret) {
    c.executionCtx.waitUntil(
      logSecurityEvent(db, {
        eventType: 'webhook_invalid',
        ipHash,
        path: '/billing/webhook',
      }),
    );
    return c.json({ error: 'forbidden', message: 'Webhook secret invalido.' }, 403);
  }

  const body = await c.req.json<{
    checkoutId?: string;
    reference?: string;
  }>();

  const result = await confirmCheckoutPayment(db, {
    checkoutId: body.checkoutId,
    reference: body.reference,
  });

  if (!result.ok) {
    return c.json({ error: 'payment_failed', message: result.error }, 400);
  }

  return c.json({
    ok: true,
    checkout: result.checkout,
    plan: result.profile.plan,
    message: 'Plano activado com sucesso.',
  });
});

/** Rotas autenticadas (evita mount aninhado que quebra hot-reload). */
billingRoutes.use('/status', requireAuth, rateLimitByUser);
billingRoutes.use('/payment-instructions', requireAuth, rateLimitByUser);
billingRoutes.use('/checkout', requireAuth, rateLimitByUser);
billingRoutes.use('/checkout/*', requireAuth, rateLimitByUser);
billingRoutes.use('/checkouts', requireAuth, rateLimitByUser);

billingRoutes.get('/payment-instructions', (c) => {
  return c.json({ instructions: PAYMENT_INSTRUCTIONS });
});

billingRoutes.get('/status', async (c) => {
  const user = c.get('user');
  const profileRaw = await ensureUser(c.env.DB, user);
  const profile = applyLocalUnlimitedToProfile(profileRaw, c.env.ENVIRONMENT);
  const localUnlimited = isLocalUnlimitedMode(c.env.ENVIRONMENT);
  const subscription = await getActiveSubscription(c.env.DB, user.uid);
  const checkouts = await listUserCheckouts(c.env.DB, user.uid, 10);
  const pending = checkouts.filter(
    (ch) => ch.status === 'pending' || ch.status === 'awaiting_review',
  );
  const recentRejected = checkouts.filter((ch) => ch.status === 'rejected').slice(0, 3);

  return c.json({
    plan: profile.plan,
    storageUsedBytes: profile.storageUsedBytes,
    storageAvailableBytes: profile.storageAvailableBytes,
    quota: localUnlimited
      ? unlimitedQuotaInfo()
      : computeQuotaInfo(
          profile.storageUsedBytes,
          profile.plan.quotaBytes,
        ),
    subscription,
    pendingCheckouts: localUnlimited ? [] : pending,
    recentRejectedCheckouts: localUnlimited ? [] : recentRejected,
    paymentsEnabled:
      !localUnlimited && c.env.PAYMENTS_ENABLED !== 'false',
    provider: 'manual',
    paymentInstructions: PAYMENT_INSTRUCTIONS,
  });
});

billingRoutes.post('/checkout', async (c) => {
  const user = c.get('user');
  if (isLocalUnlimitedMode(c.env.ENVIRONMENT)) {
    return c.json(
      {
        error: 'payments_disabled',
        message: 'Servidor local: planos e pagamentos nao aplicam.',
      },
      503,
    );
  }
  if (c.env.PAYMENTS_ENABLED === 'false') {
    return c.json(
      {
        error: 'payments_disabled',
        message: 'Pagamentos temporariamente desactivados.',
      },
      503,
    );
  }

  const body = await c.req.json<{ planCode?: string }>();
  const planCode = body.planCode?.trim();
  if (!planCode) {
    return c.json(
      { error: 'invalid_request', message: 'planCode em falta.' },
      400,
    );
  }

  const result = await createCheckout(c.env.DB, {
    firebaseUid: user.uid,
    planCode,
  });

  if ('error' in result) {
    return c.json({ error: 'checkout_failed', message: result.error }, 400);
  }

  if ('immediate' in result && result.immediate) {
    return c.json({
      immediate: true,
      plan: result.profile.plan,
      planName: result.planName,
      message: 'Plano alterado com sucesso.',
    });
  }

  const { checkout, planName } = result;
  return c.json({
    checkout,
    planName,
    paymentInstructions: PAYMENT_INSTRUCTIONS,
    message:
      'Faca a transferencia e envie o comprovativo. Revisao em ate 6 horas.',
  });
});

billingRoutes.get('/checkout/:id', async (c) => {
  const user = c.get('user');
  const checkout = await getCheckoutById(
    c.env.DB,
    c.req.param('id'),
    user.uid,
  );
  if (!checkout) {
    return c.json({ error: 'not_found', message: 'Checkout nao encontrado.' }, 404);
  }
  const plan = getPlanByCode(checkout.planCode);
  return c.json({
    checkout,
    planName: plan?.name ?? checkout.planCode,
    paymentInstructions: PAYMENT_INSTRUCTIONS,
  });
});

billingRoutes.put('/checkout/:id/proof', async (c) => {
  const user = c.get('user');
  const checkoutId = c.req.param('id');
  const mimeType = c.req.header('Content-Type')?.split(';')[0]?.trim() ?? '';
  const body = await c.req.arrayBuffer();

  const result = await submitCheckoutProof(c.env.DB, c.env.FILES_BUCKET, {
    checkoutId,
    firebaseUid: user.uid,
    mimeType,
    body,
  });

  if (!result.ok) {
    return c.json({ error: 'proof_failed', message: result.error }, 400);
  }

  return c.json({
    checkout: result.checkout,
    message: `Comprovativo recebido. Upgrade em ate ${PAYMENT_INSTRUCTIONS.reviewSlaHours} horas.`,
  });
});

billingRoutes.post('/checkout/:id/simulate-pay', async (c) => {
  if (c.env.ENVIRONMENT === 'production') {
    return c.json(
      { error: 'forbidden', message: 'Simulacao apenas em desenvolvimento.' },
      403,
    );
  }

  const user = c.get('user');
  const checkout = await getCheckoutById(
    c.env.DB,
    c.req.param('id'),
    user.uid,
  );
  if (!checkout) {
    return c.json({ error: 'not_found', message: 'Checkout nao encontrado.' }, 404);
  }

  const result = await confirmCheckoutPayment(c.env.DB, {
    checkoutId: checkout.id,
    allowPendingWithoutProof: true,
  });

  if (!result.ok) {
    return c.json({ error: 'payment_failed', message: result.error }, 400);
  }

  return c.json({
    ok: true,
    checkout: result.checkout,
    plan: result.profile.plan,
    message: 'Plano activado (simulacao dev).',
  });
});

billingRoutes.get('/checkouts', async (c) => {
  const user = c.get('user');
  const checkouts = await listUserCheckouts(c.env.DB, user.uid);
  return c.json({ checkouts });
});
