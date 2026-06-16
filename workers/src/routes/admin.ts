import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { requireAdmin } from '../middleware/admin';
import { requireCloudSupportChat } from '../middleware/cloud-support';
import { rateLimitByUser } from '../middleware/rate-limit';
import { listAccountEventsAdmin } from '../db/account_events';
import { getCloudflareUsageEstimate } from '../db/cloudflare_usage';
import {
  confirmCheckoutPayment,
  getCheckoutProofObject,
  listUserCheckouts,
  rejectCheckoutPayment,
} from '../db/payments';
import {
  listSupportMessagesForAdmin,
  markSupportReadByAdmin,
  sendSupportMessageAsAdmin,
} from '../db/support_chat';
import {
  getPlatformStats,
  getUserAdminDetail,
  listBetaFeedbackAdmin,
  listCheckoutsAdmin,
  listSecurityEventsAdmin,
  listUserFeedbackAdmin,
  listUsersAdmin,
  listActivityFeedAdmin,
  listRecentlyActiveUsersAdmin,
  logAdminAction,
  markFeedbackReviewedAdmin,
  updateUserByAdmin,
} from '../db/admin';

export const adminRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

adminRoutes.use('/*', requireAuth);
adminRoutes.use('/*', requireAdmin);
adminRoutes.use('/*', rateLimitByUser);

/** Confirma sessao admin (200) ou 403. */
adminRoutes.get('/me', (c) => {
  const user = c.get('user');
  return c.json({
    uid: user.uid,
    email: user.email,
    isAdmin: true,
  });
});

/** Metricas da plataforma (+ uso Cloudflare quando disponível). */
adminRoutes.get('/stats', async (c) => {
  const stats = await getPlatformStats(c.env.DB, c.env.ENVIRONMENT);
  let cloudflareUsage: Awaited<ReturnType<typeof getCloudflareUsageEstimate>> | null =
    null;
  try {
    cloudflareUsage = await getCloudflareUsageEstimate(c.env.DB);
  } catch (err) {
    console.error('[admin] cloudflare-usage', err);
  }
  return c.json({ stats, cloudflareUsage });
});

/** Métricas Cloudflare (Workers, D1, R2) + estimativa de custo. */
adminRoutes.get('/cloudflare-usage', async (c) => {
  const usage = await getCloudflareUsageEstimate(c.env.DB);
  return c.json({ usage });
});

/** Lista utilizadores (paginada + pesquisa). */
adminRoutes.get('/users', async (c) => {
  const limit = Number(c.req.query('limit') ?? 25) || 25;
  const offset = Number(c.req.query('offset') ?? 0) || 0;
  const search = c.req.query('q') ?? undefined;

  const result = await listUsersAdmin(c.env.DB, {
    search,
    limit,
    offset,
    environment: c.env.ENVIRONMENT,
  });
  return c.json({
    users: result.users,
    total: result.total,
    limit,
    offset,
  });
});

/** Feed unificado suporte + billing (historico plataforma). */
adminRoutes.get('/activity', async (c) => {
  const limit = Number(c.req.query('limit') ?? 40) || 40;
  const events = await listAccountEventsAdmin(c.env.DB, { limit });
  return c.json({ events });
});

/** Historico suporte + billing de um utilizador. */
adminRoutes.get('/users/:uid/activity', async (c) => {
  const limit = Number(c.req.query('limit') ?? 40) || 40;
  const events = await listAccountEventsAdmin(c.env.DB, {
    firebaseUid: c.req.param('uid'),
    limit,
  });
  return c.json({ events });
});

/** Historico de checkouts de um utilizador. */
adminRoutes.get('/users/:uid/checkouts', async (c) => {
  const limit = Number(c.req.query('limit') ?? 30) || 30;
  const checkouts = await listUserCheckouts(c.env.DB, c.req.param('uid'), limit);
  return c.json({ checkouts });
});

/** Feedback / suporte de um utilizador. */
adminRoutes.get('/users/:uid/feedback', async (c) => {
  const limit = Number(c.req.query('limit') ?? 50) || 50;
  const feedback = await listUserFeedbackAdmin(
    c.env.DB,
    c.req.param('uid'),
    limit,
  );
  return c.json({ feedback });
});

/** Chat de suporte com um utilizador (apenas Cloudflare). */
adminRoutes.get('/users/:uid/support/messages', requireCloudSupportChat, async (c) => {
  const uid = c.req.param('uid');
  const result = await listSupportMessagesForAdmin(c.env.DB, uid);
  return c.json(result);
});

adminRoutes.post('/users/:uid/support/messages', requireCloudSupportChat, async (c) => {
  const admin = c.get('user');
  const uid = c.req.param('uid');
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
  const saved = await sendSupportMessageAsAdmin(c.env.DB, {
    firebaseUid: uid,
    adminUid: admin.uid,
    message,
  });
  return c.json({ message: saved });
});

adminRoutes.post('/users/:uid/support/read', requireCloudSupportChat, async (c) => {
  await markSupportReadByAdmin(c.env.DB, c.req.param('uid'));
  return c.json({ ok: true });
});

/** Detalhe de um utilizador. */
adminRoutes.get('/users/:uid', async (c) => {
  const user = await getUserAdminDetail(
    c.env.DB,
    c.req.param('uid'),
    c.env.ENVIRONMENT,
  );
  if (!user) {
    return c.json({ error: 'not_found', message: 'Utilizador nao encontrado.' }, 404);
  }
  return c.json({ user });
});

/**
 * Actualizar plano, transferência e/ou permissão para alternar servidor.
 * Body: { planCode?, quotaBytesOverride?, clearQuotaOverride?, maxFileSizeBytesOverride?, clearTransferOverride?, canSwitchApiEndpoint? }
 */
adminRoutes.patch('/users/:uid', async (c) => {
  const admin = c.get('user');
  const body = await c.req.json<{
    planCode?: string;
    quotaBytesOverride?: number | null;
    clearQuotaOverride?: boolean;
    maxFileSizeBytesOverride?: number | null;
    clearTransferOverride?: boolean;
    canSwitchApiEndpoint?: boolean;
  }>();

  const hasPlan = body.planCode !== undefined && body.planCode.trim() !== '';
  const hasQuota = body.quotaBytesOverride !== undefined;
  const clearQuota = body.clearQuotaOverride === true;
  const hasOverride = body.maxFileSizeBytesOverride !== undefined;
  const clearOverride = body.clearTransferOverride === true;
  const hasSwitch = body.canSwitchApiEndpoint !== undefined;

  if (!hasPlan && !hasQuota && !clearQuota && !hasOverride && !clearOverride && !hasSwitch) {
    return c.json(
      {
        error: 'invalid_request',
        message:
          'Envie planCode, quotaBytesOverride, clearQuotaOverride, maxFileSizeBytesOverride, clearTransferOverride ou canSwitchApiEndpoint.',
      },
      400,
    );
  }

  const result = await updateUserByAdmin(c.env.DB, {
    targetUid: c.req.param('uid'),
    adminUid: admin.uid,
    environment: c.env.ENVIRONMENT,
    planCode: hasPlan ? body.planCode!.trim() : undefined,
    quotaBytesOverride: hasQuota ? body.quotaBytesOverride : undefined,
    clearQuotaOverride: clearQuota,
    maxFileSizeBytesOverride: hasOverride
      ? body.maxFileSizeBytesOverride
      : undefined,
    clearTransferOverride: clearOverride,
    canSwitchApiEndpoint: hasSwitch ? body.canSwitchApiEndpoint === true : undefined,
  });

  if ('error' in result) {
    console.warn(
      '[admin] PATCH /users/%s failed: %s',
      c.req.param('uid'),
      result.error,
    );
    return c.json({ error: 'update_failed', message: result.error }, 400);
  }

  return c.json({ user: result.user, message: 'Utilizador actualizado.' });
});

/** Feed de actividade (upload, download, etc.) — consola Blade. */
adminRoutes.get('/activity/feed', async (c) => {
  const limit = Number(c.req.query('limit') ?? 50) || 50;
  const feed = await listActivityFeedAdmin(c.env.DB, limit);
  return c.json({ feed });
});

/** Utilizadores activos recentemente na API local. */
adminRoutes.get('/activity/active-users', async (c) => {
  const minutes = Number(c.req.query('minutes') ?? 30) || 30;
  const users = await listRecentlyActiveUsersAdmin(c.env.DB, minutes);
  return c.json({ users, windowMinutes: minutes });
});

/** Eventos de seguranca recentes. */
adminRoutes.get('/security-events', async (c) => {
  const limit = Number(c.req.query('limit') ?? 40) || 40;
  const events = await listSecurityEventsAdmin(c.env.DB, limit);
  return c.json({ events });
});

/** Checkouts de pagamento (opcional ?status=pending). */
adminRoutes.get('/checkouts', async (c) => {
  const limit = Number(c.req.query('limit') ?? 50) || 50;
  const status = c.req.query('status') ?? undefined;
  const checkouts = await listCheckoutsAdmin(c.env.DB, { limit, status });
  return c.json({ checkouts });
});

/** Confirma pagamento pendente (accao manual do admin). */
adminRoutes.post('/checkouts/:id/confirm', async (c) => {
  const admin = c.get('user');
  const checkoutId = c.req.param('id');
  const result = await confirmCheckoutPayment(c.env.DB, { checkoutId });
  if (!result.ok) {
    return c.json({ error: 'confirm_failed', message: result.error }, 400);
  }
  await logAdminAction(c.env.DB, {
    adminUid: admin.uid,
    targetUid: result.profile.uid,
    action: 'checkout_confirm',
    metadata: {
      checkoutId,
      planCode: result.checkout.planCode,
      reference: result.checkout.reference,
    },
  });
  return c.json({
    checkout: {
      ...result.checkout,
      firebaseUid: result.profile.uid,
    },
    message: 'Pagamento confirmado e plano actualizado.',
  });
});

/** Rejeita comprovativo (feedback ao utilizador). */
adminRoutes.post('/checkouts/:id/reject', async (c) => {
  const admin = c.get('user');
  const checkoutId = c.req.param('id');
  const body = await c.req.json<{ reason?: string }>();
  const reason = body.reason?.trim() ?? '';
  if (reason.length < 5) {
    return c.json(
      {
        error: 'invalid_request',
        message: 'Indique o motivo da rejeicao (min. 5 caracteres).',
      },
      400,
    );
  }

  const result = await rejectCheckoutPayment(c.env.DB, { checkoutId, reason });
  if (!result.ok) {
    return c.json({ error: 'reject_failed', message: result.error }, 400);
  }

  const checkoutRow = await c.env.DB.prepare(
    `SELECT firebase_uid FROM payment_checkouts WHERE id = ?`,
  )
    .bind(checkoutId)
    .first<{ firebase_uid: string }>();

  if (checkoutRow) {
    await logAdminAction(c.env.DB, {
      adminUid: admin.uid,
      targetUid: checkoutRow.firebase_uid,
      action: 'checkout_reject',
      metadata: { checkoutId, reason },
    });
  }

  return c.json({
    checkout: {
      ...result.checkout,
      firebaseUid: checkoutRow?.firebase_uid ?? '',
    },
    message: 'Pagamento rejeitado. O utilizador vera o feedback.',
  });
});

/** Descarrega comprovativo de pagamento. */
adminRoutes.get('/checkouts/:id/proof', async (c) => {
  const checkoutId = c.req.param('id');
  const result = await getCheckoutProofObject(
    c.env.DB,
    c.env.FILES_BUCKET,
    checkoutId,
  );
  if (!result.ok) {
    return c.json({ error: 'not_found', message: result.error }, 404);
  }

  const headers = new Headers();
  headers.set('Content-Type', result.mimeType);
  headers.set('Cache-Control', 'private, max-age=3600');
  return new Response(result.object.body, { headers });
});

/** Feedback recente (todos os utilizadores). */
adminRoutes.get('/feedback', async (c) => {
  const limit = Number(c.req.query('limit') ?? 30) || 30;
  const feedback = await listBetaFeedbackAdmin(c.env.DB, limit);
  return c.json({ feedback });
});

/** Marca feedback como tratado (remove notificação do utilizador). */
adminRoutes.post('/feedback/:id/review', async (c) => {
  const admin = c.get('user');
  const feedbackId = Number(c.req.param('id'));
  if (!Number.isFinite(feedbackId)) {
    return c.json({ error: 'invalid_request', message: 'ID invalido.' }, 400);
  }
  const result = await markFeedbackReviewedAdmin(c.env.DB, {
    feedbackId,
    adminUid: admin.uid,
  });
  if ('error' in result) {
    return c.json({ error: 'review_failed', message: result.error }, 400);
  }
  return c.json({
    feedback: result.feedback,
    message: 'Feedback marcado como tratado.',
  });
});
