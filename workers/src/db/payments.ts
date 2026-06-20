import { getPlanByCode, NO_CHECKOUT_PLAN_CODES } from '../config/plans';
import { insertAccountEvent } from './account_events';
import { activateOrRenewSubscription, getSubscriptionDto } from './subscriptions';
import { getUserProfile } from './users';
import type { UserProfile } from './schema';
import { logSecurityEvent } from './security';

export type CheckoutRow = {
  id: string;
  firebase_uid: string;
  plan_code: string;
  amount_kz: number;
  reference: string;
  status: string;
  provider: string;
  expires_at: string;
  paid_at: string | null;
  proof_r2_key: string | null;
  proof_mime_type: string | null;
  proof_submitted_at: string | null;
  rejection_reason: string | null;
  rejected_at: string | null;
  created_at: string;
};

export type CheckoutDto = {
  id: string;
  planCode: string;
  amountKz: number;
  reference: string;
  status: string;
  provider: string;
  expiresAt: string;
  paidAt: string | null;
  proofSubmittedAt: string | null;
  rejectionReason: string | null;
  rejectedAt: string | null;
  hasProof: boolean;
  createdAt: string;
};

export type SubscriptionDto = {
  id: string;
  planCode: string;
  status: string;
  effectiveStatus: string;
  startedAt: string;
  endsAt: string | null;
  gracePeriodEndsAt: string | null;
  deletionScheduledAt: string | null;
  autoRenew: boolean;
};

function mapCheckout(row: CheckoutRow): CheckoutDto {
  return {
    id: row.id,
    planCode: row.plan_code,
    amountKz: row.amount_kz,
    reference: row.reference,
    status: row.status,
    provider: row.provider,
    expiresAt: row.expires_at,
    paidAt: row.paid_at,
    proofSubmittedAt: row.proof_submitted_at,
    rejectionReason: row.rejection_reason,
    rejectedAt: row.rejected_at,
    hasProof: Boolean(row.proof_r2_key),
    createdAt: row.created_at,
  };
}

const PROOF_MAX_BYTES = 5 * 1024 * 1024;
const PROOF_MIME_EXT: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'application/pdf': 'pdf',
};

export function proofR2Key(firebaseUid: string, checkoutId: string, ext: string): string {
  return `proofs/${firebaseUid}/${checkoutId}.${ext}`;
}

function buildReference(): string {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const suffix = crypto.randomUUID().slice(0, 8).toUpperCase();
  return `KIA-${date}-${suffix}`;
}

export async function switchUserPlan(
  db: D1Database,
  input: { firebaseUid: string; planCode: string },
): Promise<{ profile: UserProfile; planName: string } | { error: string }> {
  const plan = getPlanByCode(input.planCode);
  if (!plan) return { error: 'Plano invalido.' };
  if (!NO_CHECKOUT_PLAN_CODES.has(plan.code)) {
    return { error: 'Este plano requer pagamento. Use o checkout.' };
  }

  const profile = await db
    .prepare(
      `SELECT u.plan_code, u.storage_used_bytes
       FROM users u
       WHERE u.firebase_uid = ?`,
    )
    .bind(input.firebaseUid)
    .first<{
      plan_code: string;
      storage_used_bytes: number;
    }>();

  if (!profile) return { error: 'Utilizador nao encontrado.' };
  if (profile.plan_code === plan.code) {
    return { error: 'Ja esta neste plano.' };
  }

  const currentPlan = getPlanByCode(profile.plan_code);
  if (currentPlan && plan.quotaBytes < currentPlan.quotaBytes) {
    if (profile.storage_used_bytes > plan.quotaBytes) {
      return {
        error:
          'Nao pode mudar para um plano menor enquanto o uso excede a nova quota. Apague ficheiros primeiro.',
      };
    }
  }

  const previousPlanCode = profile.plan_code;

  try {
    await activateOrRenewSubscription(db, {
      firebaseUid: input.firebaseUid,
      planCode: plan.code,
    });
  } catch (err) {
    console.error('[payments] switchUserPlan subscription failed:', err);
    return { error: 'Nao foi possivel activar a subscrição do plano.' };
  }

  try {
    await db
      .prepare(
        `UPDATE users SET plan_code = ?, updated_at = datetime('now') WHERE firebase_uid = ?`,
      )
      .bind(plan.code, input.firebaseUid)
      .run();
  } catch (err) {
    console.error('[payments] switchUserPlan UPDATE users failed:', err);
    try {
      await db
        .prepare(
          `UPDATE users SET plan_code = ?, updated_at = datetime('now') WHERE firebase_uid = ?`,
        )
        .bind(previousPlanCode, input.firebaseUid)
        .run();
    } catch (rollbackErr) {
      console.error('[payments] switchUserPlan rollback failed:', rollbackErr);
    }
    return { error: 'Falha ao alterar plano.' };
  }

  try {
    await logSecurityEvent(db, {
      eventType: 'plan_changed',
      firebaseUid: input.firebaseUid,
      metadata: { planCode: plan.code, source: 'direct_switch' },
    });
  } catch (err) {
    console.warn('[payments] switchUserPlan security log failed:', err);
  }

  const updated = await getUserProfile(db, input.firebaseUid);
  if (!updated) return { error: 'Perfil nao encontrado apos alteracao.' };
  return { profile: updated, planName: plan.name };
}

export async function createCheckout(
  db: D1Database,
  input: {
    firebaseUid: string;
    planCode: string;
    ttlHours?: number;
  },
): Promise<
  | { checkout: CheckoutDto; planName: string }
  | { immediate: true; profile: UserProfile; planName: string }
  | { error: string }
> {
  const plan = getPlanByCode(input.planCode);
  if (!plan) return { error: 'Plano invalido.' };
  if (NO_CHECKOUT_PLAN_CODES.has(plan.code)) {
    const switched = await switchUserPlan(db, input);
    if ('error' in switched) return { error: switched.error };
    return {
      immediate: true,
      profile: switched.profile,
      planName: switched.planName,
    };
  }

  const profile = await db
    .prepare(
      `SELECT u.plan_code, u.storage_used_bytes, p.quota_bytes
       FROM users u
       INNER JOIN plans p ON p.code = u.plan_code
       WHERE u.firebase_uid = ?`,
    )
    .bind(input.firebaseUid)
    .first<{
      plan_code: string;
      storage_used_bytes: number;
      quota_bytes: number;
    }>();

  if (!profile) return { error: 'Utilizador nao encontrado.' };
  if (profile.plan_code === plan.code) {
    return { error: 'Ja esta neste plano.' };
  }

  const openCheckout = await db
    .prepare(
      `SELECT id FROM payment_checkouts
       WHERE firebase_uid = ?
         AND status IN ('pending', 'awaiting_review')
       LIMIT 1`,
    )
    .bind(input.firebaseUid)
    .first<{ id: string }>();

  if (openCheckout) {
    return {
      error:
        'Ja tem um pedido de upgrade em curso. Envie o comprovativo ou aguarde a revisao.',
    };
  }

  const currentPlan = getPlanByCode(profile.plan_code);
  if (currentPlan && plan.quotaBytes < currentPlan.quotaBytes) {
    if (profile.storage_used_bytes > plan.quotaBytes) {
      return {
        error:
          'Nao pode mudar para um plano menor enquanto o uso excede a nova quota. Apague ficheiros primeiro.',
      };
    }
  }

  const id = crypto.randomUUID();
  const reference = buildReference();
  const ttlHours = input.ttlHours ?? 24;
  const expiresAt = new Date(Date.now() + ttlHours * 3600 * 1000).toISOString();

  await db
    .prepare(
      `INSERT INTO payment_checkouts (
         id, firebase_uid, plan_code, amount_kz, reference, status, provider, expires_at
       ) VALUES (?, ?, ?, ?, ?, 'pending', 'manual', ?)`,
    )
    .bind(id, input.firebaseUid, plan.code, plan.priceKzMonth, reference, expiresAt)
    .run();

  await logSecurityEvent(db, {
    eventType: 'checkout_created',
    firebaseUid: input.firebaseUid,
    metadata: { planCode: plan.code, reference, amountKz: plan.priceKzMonth },
  });

  const row = await db
    .prepare(`SELECT * FROM payment_checkouts WHERE id = ?`)
    .bind(id)
    .first<CheckoutRow>();

  if (!row) return { error: 'Falha ao criar checkout.' };

  await insertAccountEvent(db, {
    firebaseUid: input.firebaseUid,
    kind: 'billing_checkout_created',
    title: 'Pedido de upgrade',
    body: `Referencia ${reference} criada para o plano ${plan.name}. Efectue o pagamento e envie o comprovativo.`,
    metadata: {
      checkoutId: id,
      planCode: plan.code,
      planName: plan.name,
      reference,
      amountKz: plan.priceKzMonth,
    },
    markRead: true,
  });

  return { checkout: mapCheckout(row), planName: plan.name };
}

export async function getCheckoutById(
  db: D1Database,
  checkoutId: string,
  firebaseUid?: string,
): Promise<CheckoutDto | null> {
  const row = firebaseUid
    ? await db
        .prepare(
          `SELECT * FROM payment_checkouts WHERE id = ? AND firebase_uid = ?`,
        )
        .bind(checkoutId, firebaseUid)
        .first<CheckoutRow>()
    : await db
        .prepare(`SELECT * FROM payment_checkouts WHERE id = ?`)
        .bind(checkoutId)
        .first<CheckoutRow>();
  return row ? mapCheckout(row) : null;
}

export async function listUserCheckouts(
  db: D1Database,
  firebaseUid: string,
  limit = 20,
): Promise<CheckoutDto[]> {
  const { results } = await db
    .prepare(
      `SELECT * FROM payment_checkouts
       WHERE firebase_uid = ?
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .bind(firebaseUid, limit)
    .all<CheckoutRow>();
  return (results ?? []).map(mapCheckout);
}

export async function getActiveSubscription(
  db: D1Database,
  firebaseUid: string,
): Promise<SubscriptionDto | null> {
  return getSubscriptionDto(db, firebaseUid);
}

/**
 * Confirma pagamento (webhook mock ou gateway futuro).
 * Actualiza plano do utilizador e regista subscricao.
 */
export async function confirmCheckoutPayment(
  db: D1Database,
  input: {
    checkoutId?: string;
    reference?: string;
    /** Dev/simulacao: permite confirmar sem comprovativo. */
    allowPendingWithoutProof?: boolean;
  },
): Promise<
  | { ok: true; checkout: CheckoutDto; profile: UserProfile }
  | { ok: false; error: string }
> {
  const row = input.checkoutId
    ? await db
        .prepare(`SELECT * FROM payment_checkouts WHERE id = ?`)
        .bind(input.checkoutId)
        .first<CheckoutRow>()
    : input.reference
      ? await db
          .prepare(`SELECT * FROM payment_checkouts WHERE reference = ?`)
          .bind(input.reference)
          .first<CheckoutRow>()
      : null;

  if (!row) return { ok: false, error: 'Checkout nao encontrado.' };
  if (row.status === 'paid') {
    return { ok: false, error: 'Checkout ja foi pago.' };
  }
  if (row.status === 'rejected') {
    return { ok: false, error: 'Checkout foi rejeitado.' };
  }
  if (row.status !== 'pending' && row.status !== 'awaiting_review') {
    return { ok: false, error: `Checkout em estado invalido: ${row.status}.` };
  }
  if (row.status === 'pending') {
    if (row.proof_r2_key) {
      return {
        ok: false,
        error: 'Checkout aguarda revisao. Confirme apos analise do comprovativo.',
      };
    }
    if (!input.allowPendingWithoutProof) {
      return {
        ok: false,
        error: 'Aguarda comprovativo de pagamento antes da confirmacao.',
      };
    }
  }

  if (new Date(row.expires_at).getTime() < Date.now()) {
    await db
      .prepare(
        `UPDATE payment_checkouts SET status = 'expired', updated_at = datetime('now') WHERE id = ?`,
      )
      .bind(row.id)
      .run();
    return { ok: false, error: 'Checkout expirado.' };
  }

  const plan = getPlanByCode(row.plan_code);
  if (!plan) return { ok: false, error: 'Plano do checkout invalido.' };

  try {
    await activateOrRenewSubscription(db, {
      firebaseUid: row.firebase_uid,
      planCode: row.plan_code,
    });
  } catch (err) {
    console.error('[payments] confirmCheckout subscription failed:', err);
    return { ok: false, error: 'Nao foi possivel activar a subscrição do plano.' };
  }

  await db.batch([
    db
      .prepare(
        `UPDATE payment_checkouts SET
           status = 'paid',
           paid_at = datetime('now'),
           updated_at = datetime('now')
         WHERE id = ?`,
      )
      .bind(row.id),
    db
      .prepare(
        `UPDATE users SET plan_code = ?, updated_at = datetime('now') WHERE firebase_uid = ?`,
      )
      .bind(row.plan_code, row.firebase_uid),
  ]);

  try {
    await logSecurityEvent(db, {
      eventType: 'checkout_paid',
      firebaseUid: row.firebase_uid,
      metadata: { planCode: row.plan_code, reference: row.reference },
    });

    await logSecurityEvent(db, {
      eventType: 'plan_changed',
      firebaseUid: row.firebase_uid,
      metadata: { planCode: row.plan_code, source: 'payment' },
    });
  } catch (err) {
    console.warn('[payments] confirmCheckout security log failed:', err);
  }

  const profileRow = await db
    .prepare(
      `SELECT
         u.firebase_uid, u.email, u.display_name, u.photo_url,
         u.plan_code, u.storage_used_bytes, u.created_at, u.updated_at,
         p.name AS plan_name, p.quota_bytes AS plan_quota_bytes,
         p.price_kz_month AS plan_price_kz_month,
         p.max_file_size_bytes AS plan_max_file_size_bytes
       FROM users u
       INNER JOIN plans p ON p.code = u.plan_code
       WHERE u.firebase_uid = ?`,
    )
    .bind(row.firebase_uid)
    .first<{
      firebase_uid: string;
      email: string | null;
      display_name: string | null;
      photo_url: string | null;
      plan_code: string;
      storage_used_bytes: number;
      created_at: string;
      updated_at: string;
      plan_name: string;
      plan_quota_bytes: number;
      plan_price_kz_month: number;
      plan_max_file_size_bytes: number;
    }>();

  if (!profileRow) return { ok: false, error: 'Perfil nao encontrado apos pagamento.' };

  const used = profileRow.storage_used_bytes;
  const quota = profileRow.plan_quota_bytes;
  const profile: UserProfile = {
    uid: profileRow.firebase_uid,
    email: profileRow.email,
    displayName: profileRow.display_name,
    photoUrl: profileRow.photo_url,
    plan: {
      code: profileRow.plan_code,
      name: profileRow.plan_name,
      quotaBytes: quota,
      priceKzMonth: profileRow.plan_price_kz_month,
      maxFileSizeBytes: profileRow.plan_max_file_size_bytes,
    },
    storageUsedBytes: used,
    storageAvailableBytes: Math.max(0, quota - used),
    canSwitchApiEndpoint: false,
    createdAt: profileRow.created_at,
    updatedAt: profileRow.updated_at,
  };

  const checkout = await getCheckoutById(db, row.id);
  if (!checkout) return { ok: false, error: 'Checkout nao encontrado.' };

  await insertAccountEvent(db, {
    firebaseUid: row.firebase_uid,
    kind: 'billing_paid',
    title: 'Plano activado',
    body: `O seu plano foi actualizado para ${profileRow.plan_name}.`,
    metadata: {
      checkoutId: row.id,
      planCode: row.plan_code,
      planName: profileRow.plan_name,
      reference: row.reference,
    },
  });

  return { ok: true, checkout, profile };
}

export async function submitCheckoutProof(
  db: D1Database,
  bucket: R2Bucket,
  input: {
    checkoutId: string;
    firebaseUid: string;
    mimeType: string;
    body: ArrayBuffer;
  },
): Promise<{ ok: true; checkout: CheckoutDto } | { ok: false; error: string }> {
  const row = await db
    .prepare(
      `SELECT * FROM payment_checkouts WHERE id = ? AND firebase_uid = ?`,
    )
    .bind(input.checkoutId, input.firebaseUid)
    .first<CheckoutRow>();

  if (!row) return { ok: false, error: 'Checkout nao encontrado.' };
  if (row.status !== 'pending') {
    return { ok: false, error: 'Este pedido ja nao aceita comprovativo.' };
  }
  if (new Date(row.expires_at).getTime() < Date.now()) {
    await db
      .prepare(
        `UPDATE payment_checkouts SET status = 'expired', updated_at = datetime('now') WHERE id = ?`,
      )
      .bind(row.id)
      .run();
    return { ok: false, error: 'Checkout expirado.' };
  }

  const mime = input.mimeType.trim().toLowerCase();
  const ext = PROOF_MIME_EXT[mime];
  if (!ext) {
    return {
      ok: false,
      error: 'Formato invalido. Use JPEG, PNG ou PDF.',
    };
  }
  if (input.body.byteLength <= 0) {
    return { ok: false, error: 'Comprovativo vazio.' };
  }
  if (input.body.byteLength > PROOF_MAX_BYTES) {
    return { ok: false, error: 'Comprovativo demasiado grande (max. 5 MB).' };
  }

  const key = proofR2Key(input.firebaseUid, row.id, ext);
  await bucket.put(key, input.body, {
    httpMetadata: { contentType: mime },
  });

  await db
    .prepare(
      `UPDATE payment_checkouts SET
         status = 'awaiting_review',
         proof_r2_key = ?,
         proof_mime_type = ?,
         proof_submitted_at = datetime('now'),
         updated_at = datetime('now')
       WHERE id = ?`,
    )
    .bind(key, mime, row.id)
    .run();

  await logSecurityEvent(db, {
    eventType: 'checkout_proof_submitted',
    firebaseUid: input.firebaseUid,
    metadata: { checkoutId: row.id, reference: row.reference },
  });

  const checkout = await getCheckoutById(db, row.id, input.firebaseUid);
  if (!checkout) return { ok: false, error: 'Checkout nao encontrado.' };

  const plan = getPlanByCode(row.plan_code);
  await insertAccountEvent(db, {
    firebaseUid: input.firebaseUid,
    kind: 'billing_proof_submitted',
    title: 'Comprovativo enviado',
    body: `Recebemos o seu comprovativo (${row.reference}). Revisao em ate 6 horas.`,
    metadata: {
      checkoutId: row.id,
      planCode: row.plan_code,
      planName: plan?.name ?? row.plan_code,
      reference: row.reference,
    },
    markRead: true,
  });

  return { ok: true, checkout };
}

export async function rejectCheckoutPayment(
  db: D1Database,
  input: {
    checkoutId: string;
    reason: string;
  },
): Promise<{ ok: true; checkout: CheckoutDto } | { ok: false; error: string }> {
  const reason = input.reason.trim();
  if (reason.length < 5) {
    return { ok: false, error: 'Motivo da rejeicao demasiado curto.' };
  }

  const row = await db
    .prepare(`SELECT * FROM payment_checkouts WHERE id = ?`)
    .bind(input.checkoutId)
    .first<CheckoutRow>();

  if (!row) return { ok: false, error: 'Checkout nao encontrado.' };
  if (row.status !== 'awaiting_review') {
    return { ok: false, error: 'So pedidos em revisao podem ser rejeitados.' };
  }

  await db
    .prepare(
      `UPDATE payment_checkouts SET
         status = 'rejected',
         rejection_reason = ?,
         rejected_at = datetime('now'),
         updated_at = datetime('now')
       WHERE id = ?`,
    )
    .bind(reason, row.id)
    .run();

  await logSecurityEvent(db, {
    eventType: 'checkout_rejected',
    firebaseUid: row.firebase_uid,
    metadata: { checkoutId: row.id, reference: row.reference, reason },
  });

  const checkout = await getCheckoutById(db, row.id);
  if (!checkout) return { ok: false, error: 'Checkout nao encontrado.' };

  const plan = getPlanByCode(row.plan_code);
  await insertAccountEvent(db, {
    firebaseUid: row.firebase_uid,
    kind: 'billing_rejected',
    title: 'Pagamento rejeitado',
    body: reason,
    metadata: {
      checkoutId: row.id,
      planCode: row.plan_code,
      planName: plan?.name ?? row.plan_code,
      reference: row.reference,
      rejectionReason: reason,
    },
  });

  return { ok: true, checkout };
}

export async function getCheckoutProofObject(
  db: D1Database,
  bucket: R2Bucket,
  checkoutId: string,
): Promise<
  | { ok: true; object: R2ObjectBody; mimeType: string }
  | { ok: false; error: string }
> {
  const row = await db
    .prepare(`SELECT proof_r2_key, proof_mime_type FROM payment_checkouts WHERE id = ?`)
    .bind(checkoutId)
    .first<{ proof_r2_key: string | null; proof_mime_type: string | null }>();

  if (!row?.proof_r2_key) {
    return { ok: false, error: 'Comprovativo nao encontrado.' };
  }

  const object = await bucket.get(row.proof_r2_key);
  if (!object) return { ok: false, error: 'Comprovativo nao encontrado no armazenamento.' };

  return {
    ok: true,
    object,
    mimeType: row.proof_mime_type ?? 'application/octet-stream',
  };
}
