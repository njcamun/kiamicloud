export type SecurityEventType =
  | 'auth_failed'
  | 'rate_limited'
  | 'webhook_invalid'
  | 'plan_changed'
  | 'checkout_created'
  | 'checkout_paid'
  | 'checkout_proof_submitted'
  | 'checkout_rejected'
  | 'subscription_renewed'
  | 'subscription_grace_period'
  | 'subscription_restricted'
  | 'subscription_suspended'
  | 'subscription_pending_deletion'
  | 'subscription_admin_adjust';

export async function logSecurityEvent(
  db: D1Database,
  input: {
    eventType: SecurityEventType;
    firebaseUid?: string;
    ipHash?: string;
    path?: string;
    metadata?: Record<string, unknown>;
  },
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO security_events (
         event_type, firebase_uid, ip_hash, path, metadata_json
       ) VALUES (?, ?, ?, ?, ?)`,
    )
    .bind(
      input.eventType,
      input.firebaseUid ?? null,
      input.ipHash ?? null,
      input.path ?? null,
      input.metadata ? JSON.stringify(input.metadata) : null,
    )
    .run();
}

export type FileActionDto = {
  id: number;
  action: string;
  fileId: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: string;
};

export async function listFileActions(
  db: D1Database,
  firebaseUid: string,
  limit = 50,
): Promise<FileActionDto[]> {
  const { results } = await db
    .prepare(
      `SELECT id, action, file_id, metadata_json, created_at
       FROM file_actions
       WHERE firebase_uid = ?
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .bind(firebaseUid, limit)
    .all<{
      id: number;
      action: string;
      file_id: string | null;
      metadata_json: string | null;
      created_at: string;
    }>();

  return (results ?? []).map((r) => ({
    id: r.id,
    action: r.action,
    fileId: r.file_id,
    metadata: r.metadata_json
      ? (JSON.parse(r.metadata_json) as Record<string, unknown>)
      : null,
    createdAt: r.created_at,
  }));
}
