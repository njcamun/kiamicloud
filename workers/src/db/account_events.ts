export type AccountEventKind =
  | 'billing_checkout_created'
  | 'billing_proof_submitted'
  | 'billing_paid'
  | 'billing_rejected'
  | 'support_sent'
  | 'support_reviewed'
  | 'quota_updated';

const NOTIFICATION_KINDS: AccountEventKind[] = [
  'billing_paid',
  'billing_rejected',
  'support_reviewed',
  'quota_updated',
];

export type AccountEventDto = {
  id: number;
  kind: AccountEventKind;
  title: string;
  body: string;
  metadata: Record<string, unknown> | null;
  readAt: string | null;
  createdAt: string;
  isNotification: boolean;
  isUnread: boolean;
};

export type AdminAccountEventDto = AccountEventDto & {
  firebaseUid: string;
  userEmail: string | null;
  userDisplayName: string | null;
};

type EventRow = {
  id: number;
  firebase_uid: string;
  kind: string;
  title: string;
  body: string;
  metadata_json: string | null;
  read_at: string | null;
  created_at: string;
  user_email?: string | null;
  user_display_name?: string | null;
};

function mapEvent(row: EventRow): AccountEventDto {
  const kind = row.kind as AccountEventKind;
  const isNotification = NOTIFICATION_KINDS.includes(kind);
  return {
    id: row.id,
    kind,
    title: row.title,
    body: row.body,
    metadata: row.metadata_json
      ? (JSON.parse(row.metadata_json) as Record<string, unknown>)
      : null,
    readAt: row.read_at,
    createdAt: row.created_at,
    isNotification,
    isUnread: isNotification && row.read_at == null,
  };
}

function mapAdminEvent(row: EventRow): AdminAccountEventDto {
  return {
    ...mapEvent(row),
    firebaseUid: row.firebase_uid,
    userEmail: row.user_email ?? null,
    userDisplayName: row.user_display_name ?? null,
  };
}

export async function insertAccountEvent(
  db: D1Database,
  input: {
    firebaseUid: string;
    kind: AccountEventKind;
    title: string;
    body: string;
    metadata?: Record<string, unknown>;
    markRead?: boolean;
  },
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO user_account_events (
         firebase_uid, kind, title, body, metadata_json, read_at
       ) VALUES (?, ?, ?, ?, ?, ?)`,
    )
    .bind(
      input.firebaseUid,
      input.kind,
      input.title,
      input.body,
      input.metadata ? JSON.stringify(input.metadata) : null,
      input.markRead ? new Date().toISOString() : null,
    )
    .run();
}

export async function listAccountEventsForUser(
  db: D1Database,
  firebaseUid: string,
  limit = 40,
): Promise<AccountEventDto[]> {
  const capped = Math.min(100, Math.max(1, limit));
  const { results } = await db
    .prepare(
      `SELECT id, firebase_uid, kind, title, body, metadata_json, read_at, created_at
       FROM user_account_events
       WHERE firebase_uid = ?
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .bind(firebaseUid, capped)
    .all<EventRow>();

  return (results ?? []).map(mapEvent);
}

const UNREAD_NOTIFICATION_KINDS_SQL = `'billing_paid', 'billing_rejected', 'support_reviewed', 'quota_updated'`;

export async function countUnreadAccountEvents(
  db: D1Database,
  firebaseUid: string,
): Promise<number> {
  const row = await db
    .prepare(
      `SELECT COUNT(*) AS cnt FROM user_account_events
       WHERE firebase_uid = ?
         AND read_at IS NULL
         AND kind IN (${UNREAD_NOTIFICATION_KINDS_SQL})`,
    )
    .bind(firebaseUid)
    .first<{ cnt: number }>();
  return row?.cnt ?? 0;
}

export async function markAccountEventRead(
  db: D1Database,
  firebaseUid: string,
  eventId: number,
): Promise<boolean> {
  const result = await db
    .prepare(
      `UPDATE user_account_events SET read_at = datetime('now')
       WHERE id = ? AND firebase_uid = ? AND read_at IS NULL`,
    )
    .bind(eventId, firebaseUid)
    .run();
  return (result.meta.changes ?? 0) > 0;
}

export async function markAllAccountEventsRead(
  db: D1Database,
  firebaseUid: string,
): Promise<number> {
  const result = await db
    .prepare(
      `UPDATE user_account_events SET read_at = datetime('now')
       WHERE firebase_uid = ? AND read_at IS NULL
         AND kind IN (${UNREAD_NOTIFICATION_KINDS_SQL})`,
    )
    .bind(firebaseUid)
    .run();
  return result.meta.changes ?? 0;
}

export async function listAccountEventsAdmin(
  db: D1Database,
  input: { firebaseUid?: string; limit?: number } = {},
): Promise<AdminAccountEventDto[]> {
  const capped = Math.min(100, Math.max(1, input.limit ?? 40));
  const uid = input.firebaseUid?.trim();

  const sql = uid
    ? `SELECT e.id, e.firebase_uid, e.kind, e.title, e.body, e.metadata_json,
              e.read_at, e.created_at, u.email AS user_email, u.display_name AS user_display_name
       FROM user_account_events e
       LEFT JOIN users u ON u.firebase_uid = e.firebase_uid
       WHERE e.firebase_uid = ?
       ORDER BY e.created_at DESC
       LIMIT ?`
    : `SELECT e.id, e.firebase_uid, e.kind, e.title, e.body, e.metadata_json,
              e.read_at, e.created_at, u.email AS user_email, u.display_name AS user_display_name
       FROM user_account_events e
       LEFT JOIN users u ON u.firebase_uid = e.firebase_uid
       ORDER BY e.created_at DESC
       LIMIT ?`;

  const { results } = uid
    ? await db.prepare(sql).bind(uid, capped).all<EventRow>()
    : await db.prepare(sql).bind(capped).all<EventRow>();

  return (results ?? []).map(mapAdminEvent);
}
