import { NO_CHECKOUT_PLAN_CODES } from '../config/plans';
import {
  DELETION_NOTICE_DAYS,
  DELETION_REMINDER_DAYS,
  GRACE_PERIOD_DAYS,
  RENEWAL_REMINDER_DAYS,
  SUBSCRIPTION_PERIOD_DAYS,
  type SubscriptionStatus,
} from '../config/subscriptions';
import {
  computeEffectiveStatus,
  resolveAccess,
  type SubscriptionAccessDto,
} from '../lib/subscription-access';
import { insertAccountEvent, type AccountEventKind } from './account_events';
import { deleteUserAccount } from './user_account';
import { logSecurityEvent, type SecurityEventType } from './security';

export type SubscriptionRow = {
  id: string;
  firebase_uid: string;
  plan_code: string;
  status: string;
  started_at: string;
  ends_at: string | null;
  grace_period_ends_at: string | null;
  auto_renew: number;
  last_notified_at: string | null;
  deletion_scheduled_at: string | null;
  created_at: string;
  updated_at: string;
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

function mapSubscription(row: SubscriptionRow): SubscriptionDto {
  const effective = computeEffectiveStatus(row, row.plan_code);
  return {
    id: row.id,
    planCode: row.plan_code,
    status: row.status,
    effectiveStatus: effective,
    startedAt: row.started_at,
    endsAt: row.ends_at,
    gracePeriodEndsAt: row.grace_period_ends_at,
    deletionScheduledAt: row.deletion_scheduled_at,
    autoRenew: row.auto_renew === 1,
  };
}

function addDaysISO(base: Date, days: number): string {
  const d = new Date(base);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString();
}

export async function getLatestSubscriptionRow(
  db: D1Database,
  firebaseUid: string,
): Promise<SubscriptionRow | null> {
  return db
    .prepare(
      `SELECT *
       FROM subscriptions
       WHERE firebase_uid = ?
         AND status NOT IN ('cancelled', 'deleted')
       ORDER BY updated_at DESC
       LIMIT 1`,
    )
    .bind(firebaseUid)
    .first<SubscriptionRow>();
}

export async function getSubscriptionDto(
  db: D1Database,
  firebaseUid: string,
): Promise<SubscriptionDto | null> {
  const row = await getLatestSubscriptionRow(db, firebaseUid);
  return row ? mapSubscription(row) : null;
}

export async function ensureFreeSubscription(
  db: D1Database,
  firebaseUid: string,
): Promise<void> {
  const existing = await getLatestSubscriptionRow(db, firebaseUid);
  if (existing) return;

  await db
    .prepare(
      `INSERT INTO subscriptions (
         id, firebase_uid, plan_code, status, started_at, ends_at, auto_renew
       ) VALUES (?, ?, 'basico', 'active', datetime('now'), NULL, 0)`,
    )
    .bind(crypto.randomUUID(), firebaseUid)
    .run();
}

export async function resolveSubscriptionAccessForUser(
  db: D1Database,
  input: {
    firebaseUid: string;
    planCode: string;
    storageUsedBytes: number;
    quotaBytes: number;
    environment?: string;
  },
): Promise<SubscriptionAccessDto> {
  const row = await getLatestSubscriptionRow(db, input.firebaseUid);
  return resolveAccess({
    planCode: input.planCode,
    storageUsedBytes: input.storageUsedBytes,
    quotaBytes: input.quotaBytes,
    subscription: row,
    environment: input.environment,
  });
}

/** Activa ou renova subscrição após pagamento confirmado. */
export async function activateOrRenewSubscription(
  db: D1Database,
  input: { firebaseUid: string; planCode: string },
): Promise<void> {
  const now = new Date();
  const existing = await getLatestSubscriptionRow(db, input.firebaseUid);

  let endsAt: string;
  if (NO_CHECKOUT_PLAN_CODES.has(input.planCode)) {
    endsAt = '';
  } else if (existing?.ends_at) {
    const base = new Date(existing.ends_at);
    const startFrom = base.getTime() > now.getTime() ? base : now;
    endsAt = addDaysISO(startFrom, SUBSCRIPTION_PERIOD_DAYS);
  } else {
    endsAt = addDaysISO(now, SUBSCRIPTION_PERIOD_DAYS);
  }

  const subId = crypto.randomUUID();
  const batch: D1PreparedStatement[] = [
    db
      .prepare(
        `UPDATE subscriptions SET status = 'cancelled', updated_at = datetime('now')
         WHERE firebase_uid = ? AND status NOT IN ('cancelled', 'deleted')`,
      )
      .bind(input.firebaseUid),
  ];

  if (NO_CHECKOUT_PLAN_CODES.has(input.planCode)) {
    batch.push(
      db
        .prepare(
          `INSERT INTO subscriptions (
             id, firebase_uid, plan_code, status, started_at, ends_at,
             grace_period_ends_at, deletion_scheduled_at, auto_renew
           ) VALUES (?, ?, ?, 'active', datetime('now'), NULL, NULL, NULL, 0)`,
        )
        .bind(subId, input.firebaseUid, input.planCode),
    );
  } else {
    batch.push(
      db
        .prepare(
          `INSERT INTO subscriptions (
             id, firebase_uid, plan_code, status, started_at, ends_at,
             grace_period_ends_at, deletion_scheduled_at, auto_renew
           ) VALUES (?, ?, ?, 'active', datetime('now'), ?, NULL, NULL, 0)`,
        )
        .bind(subId, input.firebaseUid, input.planCode, endsAt),
    );
  }

  await db.batch(batch);

  try {
    await insertAccountEvent(db, {
      firebaseUid: input.firebaseUid,
      kind: 'subscription_renewed',
      title: 'Subscrição activa',
      body: 'O teu plano foi activado ou renovado com sucesso.',
      metadata: { planCode: input.planCode, endsAt: endsAt || null },
    });
  } catch (err) {
    console.warn('[subscriptions] account event failed:', err);
  }

  try {
    await logSecurityEvent(db, {
      eventType: 'subscription_renewed',
      firebaseUid: input.firebaseUid,
      metadata: { planCode: input.planCode, endsAt: endsAt || null },
    });
  } catch (err) {
    console.warn('[subscriptions] security event failed:', err);
  }
}

function securityEventForSubscriptionStatus(
  status: SubscriptionStatus,
): SecurityEventType | null {
  switch (status) {
    case 'grace_period':
      return 'subscription_grace_period';
    case 'restricted':
      return 'subscription_restricted';
    case 'suspended':
      return 'subscription_suspended';
    case 'pending_deletion':
      return 'subscription_pending_deletion';
    default:
      return null;
  }
}

async function notifyIfDue(
  db: D1Database,
  input: {
    firebaseUid: string;
    subscriptionId: string;
    kind: AccountEventKind;
    title: string;
    body: string;
    metadata: Record<string, unknown>;
    lastNotifiedAt: string | null;
    marker: string;
  },
): Promise<boolean> {
  if (input.lastNotifiedAt === input.marker) return false;
  await insertAccountEvent(db, {
    firebaseUid: input.firebaseUid,
    kind: input.kind,
    title: input.title,
    body: input.body,
    metadata: input.metadata,
  });
  await db
    .prepare(
      `UPDATE subscriptions SET last_notified_at = ?, updated_at = datetime('now') WHERE id = ?`,
    )
    .bind(input.marker, input.subscriptionId)
    .run();
  return true;
}

function daysUntil(iso: string, nowMs: number): number {
  const t = new Date(iso).getTime();
  if (!Number.isFinite(t)) return 9999;
  return Math.ceil((t - nowMs) / 86_400_000);
}

/** Cron diário: transições de estado + lembretes. */
export async function runSubscriptionLifecycle(
  db: D1Database,
  filesBucket: R2Bucket,
): Promise<{
  transitioned: number;
  reminders: number;
  deleted: number;
}> {
  const now = new Date();
  const nowMs = now.getTime();
  let transitioned = 0;
  let reminders = 0;
  let deleted = 0;

  const { results } = await db
    .prepare(
      `SELECT s.*, u.email
       FROM subscriptions s
       INNER JOIN users u ON u.firebase_uid = s.firebase_uid
       WHERE s.status NOT IN ('cancelled', 'deleted')
         AND s.ends_at IS NOT NULL`,
    )
    .all<SubscriptionRow & { email: string | null }>();

  for (const row of results ?? []) {
    const effective = computeEffectiveStatus(row, row.plan_code, nowMs);

    if (effective !== row.status && effective !== 'active') {
      const updates: string[] = [`status = ?`, `updated_at = datetime('now')`];
      const binds: (string | null)[] = [effective];

      if (effective === 'grace_period' && !row.grace_period_ends_at && row.ends_at) {
        updates.push(`grace_period_ends_at = ?`);
        binds.push(addDaysISO(new Date(row.ends_at), GRACE_PERIOD_DAYS));
      }
      if (effective === 'pending_deletion' && !row.deletion_scheduled_at) {
        updates.push(`deletion_scheduled_at = ?`);
        binds.push(addDaysISO(now, DELETION_NOTICE_DAYS));
      }

      binds.push(row.id);
      await db
        .prepare(`UPDATE subscriptions SET ${updates.join(', ')} WHERE id = ?`)
        .bind(...binds)
        .run();

      const kind: AccountEventKind =
        effective === 'grace_period'
          ? 'subscription_grace'
          : effective === 'restricted'
            ? 'subscription_restricted'
            : effective === 'suspended'
              ? 'subscription_suspended'
              : 'subscription_pending_deletion';

      const title =
        effective === 'grace_period'
          ? 'Subscrição a expirar'
          : effective === 'restricted'
            ? 'Uploads bloqueados'
            : effective === 'suspended'
              ? 'Conta suspensa'
              : 'Eliminação agendada';

      await insertAccountEvent(db, {
        firebaseUid: row.firebase_uid,
        kind,
        title,
        body: `O estado da subscrição mudou para ${effective}. Renove em Planos para recuperar o acesso completo.`,
        metadata: { status: effective, subscriptionId: row.id },
      });

      const securityEvent = securityEventForSubscriptionStatus(effective);
      if (securityEvent) {
        await logSecurityEvent(db, {
          eventType: securityEvent,
          firebaseUid: row.firebase_uid,
          metadata: { subscriptionId: row.id },
        });
      }

      transitioned += 1;
    }

    if (row.ends_at && effective === 'active') {
      const daysLeft = daysUntil(row.ends_at, nowMs);
      for (const d of RENEWAL_REMINDER_DAYS) {
        if (daysLeft !== d) continue;
        const marker = `renewal_${d}_${row.ends_at.slice(0, 10)}`;
        const sent = await notifyIfDue(db, {
          firebaseUid: row.firebase_uid,
          subscriptionId: row.id,
          kind: 'subscription_expiring',
          title:
            d === 0
              ? 'Subscrição expira hoje'
              : `Subscrição expira em ${d} dia(s)`,
          body: 'Renove o plano para manter o armazenamento e os uploads activos.',
          metadata: { daysLeft: d, endsAt: row.ends_at },
          lastNotifiedAt: row.last_notified_at,
          marker,
        });
        if (sent) reminders += 1;
      }
    }

    if (row.deletion_scheduled_at && effective === 'pending_deletion') {
      const daysLeft = daysUntil(row.deletion_scheduled_at, nowMs);
      for (const d of DELETION_REMINDER_DAYS) {
        if (daysLeft !== d) continue;
        const marker = `deletion_${d}_${row.deletion_scheduled_at.slice(0, 10)}`;
        const sent = await notifyIfDue(db, {
          firebaseUid: row.firebase_uid,
          subscriptionId: row.id,
          kind: 'subscription_pending_deletion',
          title: `Eliminação em ${d} dia(s)`,
          body: 'Os teus dados serão removidos se não renovares a subscrição.',
          metadata: { daysLeft: d, deletionScheduledAt: row.deletion_scheduled_at },
          lastNotifiedAt: row.last_notified_at,
          marker,
        });
        if (sent) reminders += 1;
      }

      if (daysLeft <= 0) {
        await deleteUserAccount(db, filesBucket, row.firebase_uid);
        await db
          .prepare(
            `UPDATE subscriptions SET status = 'deleted', updated_at = datetime('now') WHERE id = ?`,
          )
          .bind(row.id)
          .run();
        await insertAccountEvent(db, {
          firebaseUid: row.firebase_uid,
          kind: 'subscription_deleted',
          title: 'Conta eliminada',
          body: 'Os dados foram removidos por falta de renovação da subscrição.',
          metadata: { subscriptionId: row.id },
        });
        deleted += 1;
      }
    }
  }

  return { transitioned, reminders, deleted };
}

export type AdminSubscriptionDto = SubscriptionDto & {
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
  storageUsedBytes: number;
};

export async function listSubscriptionsAdmin(
  db: D1Database,
  input: {
    status?: string;
    limit?: number;
    offset?: number;
  },
): Promise<{ items: AdminSubscriptionDto[]; total: number }> {
  const limit = Math.min(Math.max(input.limit ?? 25, 1), 100);
  const offset = Math.max(input.offset ?? 0, 0);

  let where = `WHERE s.status NOT IN ('cancelled')`;
  const binds: (string | number)[] = [];
  if (input.status?.trim()) {
    where += ` AND s.status = ?`;
    binds.push(input.status.trim());
  }

  const countRow = await db
    .prepare(
      `SELECT COUNT(*) AS c FROM subscriptions s ${where}`,
    )
    .bind(...binds)
    .first<{ c: number }>();

  const { results } = await db
    .prepare(
      `SELECT s.*, u.email, u.display_name, u.storage_used_bytes
       FROM subscriptions s
       INNER JOIN users u ON u.firebase_uid = s.firebase_uid
       ${where}
       ORDER BY s.updated_at DESC
       LIMIT ? OFFSET ?`,
    )
    .bind(...binds, limit, offset)
    .all<SubscriptionRow & {
      email: string | null;
      display_name: string | null;
      storage_used_bytes: number;
    }>();

  const items = (results ?? []).map((row) => ({
    ...mapSubscription(row),
    firebaseUid: row.firebase_uid,
    email: row.email,
    displayName: row.display_name,
    storageUsedBytes: row.storage_used_bytes,
  }));

  return { items, total: countRow?.c ?? 0 };
}

export async function getSubscriptionAdminForUser(
  db: D1Database,
  firebaseUid: string,
): Promise<AdminSubscriptionDto | null> {
  const row = await getLatestSubscriptionRow(db, firebaseUid);
  if (!row) return null;

  const user = await db
    .prepare(
      `SELECT email, display_name, storage_used_bytes
       FROM users WHERE firebase_uid = ?`,
    )
    .bind(firebaseUid)
    .first<{
      email: string | null;
      display_name: string | null;
      storage_used_bytes: number;
    }>();

  return {
    ...mapSubscription(row),
    firebaseUid,
    email: user?.email ?? null,
    displayName: user?.display_name ?? null,
    storageUsedBytes: user?.storage_used_bytes ?? 0,
  };
}

export async function reactivateSubscriptionAdmin(
  db: D1Database,
  input: {
    firebaseUid: string;
    endsAtDays?: number;
    adminUid: string;
  },
): Promise<{ ok: true } | { ok: false; error: string }> {
  const row = await getLatestSubscriptionRow(db, input.firebaseUid);
  if (!row) return { ok: false, error: 'Subscrição não encontrada.' };

  const endsAt = addDaysISO(new Date(), input.endsAtDays ?? SUBSCRIPTION_PERIOD_DAYS);
  await db
    .prepare(
      `UPDATE subscriptions SET
         status = 'active',
         ends_at = ?,
         grace_period_ends_at = NULL,
         deletion_scheduled_at = NULL,
         updated_at = datetime('now')
       WHERE id = ?`,
    )
    .bind(endsAt, row.id)
    .run();

  await insertAccountEvent(db, {
    firebaseUid: input.firebaseUid,
    kind: 'subscription_reactivated',
    title: 'Conta reactivada',
    body: 'Um administrador reactivou a tua subscrição.',
    metadata: { endsAt, adminUid: input.adminUid },
  });

  return { ok: true };
}

export async function adjustSubscriptionEndsAtAdmin(
  db: D1Database,
  input: {
    firebaseUid: string;
    endsAt: string;
    adminUid: string;
  },
): Promise<{ ok: true } | { ok: false; error: string }> {
  const row = await getLatestSubscriptionRow(db, input.firebaseUid);
  if (!row) return { ok: false, error: 'Subscrição não encontrada.' };

  await db
    .prepare(
      `UPDATE subscriptions SET
         ends_at = ?,
         status = 'active',
         grace_period_ends_at = NULL,
         deletion_scheduled_at = NULL,
         updated_at = datetime('now')
       WHERE id = ?`,
    )
    .bind(input.endsAt, row.id)
    .run();

  await logSecurityEvent(db, {
    eventType: 'subscription_admin_adjust',
    firebaseUid: input.firebaseUid,
    metadata: { endsAt: input.endsAt, adminUid: input.adminUid },
  });

  return { ok: true };
}
