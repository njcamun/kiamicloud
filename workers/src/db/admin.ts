import { getPlanByCode } from '../config/plans';
import {
  effectiveMaxFileSizeBytes,
  validateTransferOverrideBytes,
} from '../lib/effective_max_file';
import {
  effectiveQuotaBytes,
  validateQuotaOverrideBytes,
} from '../lib/effective_quota';
import { insertAccountEvent } from './account_events';
import { activateOrRenewSubscription } from './subscriptions';
import {
  isLocalUnlimitedMode,
  LOCAL_UNLIMITED_QUOTA_BYTES,
  resolveMaxFileBytes,
} from '../lib/local_unlimited';

export type PlatformStats = {
  usersCount: number;
  activeFilesCount: number;
  totalStorageUsedBytes: number;
  pendingCheckoutsCount: number;
  securityEventsLast24h: number;
  pendingFeedbackCount: number;
};

export type AdminUserRow = {
  firebase_uid: string;
  email: string | null;
  display_name: string | null;
  plan_code: string;
  plan_name: string;
  plan_quota_bytes: number;
  quota_bytes_override: number | null;
  quota_bytes: number;
  plan_max_file_size_bytes: number;
  max_file_size_bytes_override: number | null;
  storage_used_bytes: number;
  can_switch_api_endpoint: number;
  files_count: number;
  pending_feedback_count: number;
  pending_checkouts_count: number;
  created_at: string;
  updated_at: string;
};

export type AdminUserSummary = {
  uid: string;
  email: string | null;
  displayName: string | null;
  planCode: string;
  planName: string;
  quotaBytes: number;
  planQuotaBytes: number;
  quotaOverrideBytes: number | null;
  planMaxFileSizeBytes: number;
  maxFileSizeBytes: number;
  transferOverrideBytes: number | null;
  storageUsedBytes: number;
  filesCount: number;
  pendingFeedbackCount: number;
  pendingCheckoutsCount: number;
  canSwitchApiEndpoint: boolean;
  createdAt: string;
  updatedAt: string;
};

import { ensureSupportChatSchema } from './support_chat_schema';

function mapUserSummary(
  row: AdminUserRow,
  environment?: string,
): AdminUserSummary {
  const planMax = row.plan_max_file_size_bytes;
  const transferOverride = row.max_file_size_bytes_override;
  const localUnlimited = isLocalUnlimitedMode(environment);
  return {
    uid: row.firebase_uid,
    email: row.email,
    displayName: row.display_name,
    planCode: row.plan_code,
    planName: row.plan_name,
    quotaBytes: localUnlimited ? LOCAL_UNLIMITED_QUOTA_BYTES : row.quota_bytes,
    planQuotaBytes: row.plan_quota_bytes,
    quotaOverrideBytes: localUnlimited ? null : row.quota_bytes_override,
    planMaxFileSizeBytes: planMax,
    maxFileSizeBytes: resolveMaxFileBytes(planMax, transferOverride, environment),
    transferOverrideBytes: localUnlimited ? null : transferOverride,
    storageUsedBytes: row.storage_used_bytes,
    filesCount: row.files_count,
    pendingFeedbackCount: row.pending_feedback_count ?? 0,
    pendingCheckoutsCount: row.pending_checkouts_count ?? 0,
    canSwitchApiEndpoint: row.can_switch_api_endpoint === 1,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

const USER_ORDER_BY = `
  ORDER BY pending_feedback_count DESC,
           pending_checkouts_count DESC,
           LOWER(COALESCE(u.display_name, u.email, u.firebase_uid)) ASC
`;

function pendingFeedbackCountExpr(environment?: string): string {
  const betaPending = `(SELECT COUNT(*) FROM beta_feedback bf
     WHERE bf.firebase_uid = u.firebase_uid AND bf.reviewed_at IS NULL)`;
  if (isLocalUnlimitedMode(environment)) {
    return `${betaPending} AS pending_feedback_count`;
  }
  return `${betaPending}
    +
    (SELECT COUNT(*) FROM support_chat_messages scm
     WHERE scm.firebase_uid = u.firebase_uid
       AND scm.sender_role = 'user'
       AND scm.id > COALESCE(
         (SELECT admin_last_read_id FROM support_chat_read_state rs
          WHERE rs.firebase_uid = u.firebase_uid), 0)) AS pending_feedback_count`;
}

function buildUserListSql(environment?: string): string {
  return `
  SELECT
    u.firebase_uid,
    u.email,
    u.display_name,
    u.plan_code,
    p.name AS plan_name,
    p.quota_bytes AS plan_quota_bytes,
    u.quota_bytes_override,
    COALESCE(u.quota_bytes_override, p.quota_bytes) AS quota_bytes,
    p.max_file_size_bytes AS plan_max_file_size_bytes,
    u.max_file_size_bytes_override,
    u.storage_used_bytes,
    COALESCE(u.can_switch_api_endpoint, 0) AS can_switch_api_endpoint,
    u.created_at,
    u.updated_at,
    (SELECT COUNT(*) FROM files f
     WHERE f.firebase_uid = u.firebase_uid
       AND f.status = 'active' AND f.deleted_at IS NULL) AS files_count,
    ${pendingFeedbackCountExpr(environment)},
    (SELECT COUNT(*) FROM payment_checkouts pc
     WHERE pc.firebase_uid = u.firebase_uid AND pc.status = 'awaiting_review') AS pending_checkouts_count
  FROM users u
  INNER JOIN plans p ON p.code = u.plan_code
`;
}

function platformPendingFeedbackSql(environment?: string): string {
  const betaPending = `(SELECT COUNT(*) FROM beta_feedback WHERE reviewed_at IS NULL)`;
  if (isLocalUnlimitedMode(environment)) {
    return `${betaPending} AS pending_feedback_count`;
  }
  return `${betaPending}
         +
         (SELECT COUNT(*) FROM support_chat_messages scm
          WHERE scm.sender_role = 'user'
            AND scm.id > COALESCE(
              (SELECT admin_last_read_id FROM support_chat_read_state rs
               WHERE rs.firebase_uid = scm.firebase_uid), 0)) AS pending_feedback_count`;
}

export async function getPlatformStats(
  db: D1Database,
  environment?: string,
): Promise<PlatformStats> {
  if (!isLocalUnlimitedMode(environment)) {
    await ensureSupportChatSchema(db);
  }
  const row = await db
    .prepare(
      `SELECT
         (SELECT COUNT(*) FROM users) AS users_count,
         (SELECT COUNT(*) FROM files
          WHERE status = 'active' AND deleted_at IS NULL) AS active_files_count,
         (SELECT COALESCE(SUM(storage_used_bytes), 0) FROM users) AS total_storage_used_bytes,
         (SELECT COUNT(*) FROM payment_checkouts WHERE status = 'awaiting_review') AS pending_checkouts_count,
         (SELECT COUNT(*) FROM security_events
          WHERE created_at >= datetime('now', '-1 day')) AS security_events_last24h,
         ${platformPendingFeedbackSql(environment)}`,
    )
    .first<{
      users_count: number;
      active_files_count: number;
      total_storage_used_bytes: number;
      pending_checkouts_count: number;
      security_events_last24h: number;
      pending_feedback_count: number;
    }>();

  return {
    usersCount: row?.users_count ?? 0,
    activeFilesCount: row?.active_files_count ?? 0,
    totalStorageUsedBytes: row?.total_storage_used_bytes ?? 0,
    pendingCheckoutsCount: row?.pending_checkouts_count ?? 0,
    securityEventsLast24h: row?.security_events_last24h ?? 0,
    pendingFeedbackCount: row?.pending_feedback_count ?? 0,
  };
}

export async function listUsersAdmin(
  db: D1Database,
  input: { search?: string; limit: number; offset: number; environment?: string },
): Promise<{ users: AdminUserSummary[]; total: number }> {
  const env = input.environment;
  if (!isLocalUnlimitedMode(env)) {
    await ensureSupportChatSchema(db);
  }
  const userListSql = buildUserListSql(env);
  const search = input.search?.trim();
  const limit = Math.min(100, Math.max(1, input.limit));
  const offset = Math.max(0, input.offset);

  if (search) {
    const pattern = `%${search.replace(/%/g, '')}%`;
    const countRow = await db
      .prepare(
        `SELECT COUNT(*) AS total FROM users u
         WHERE u.email LIKE ? OR u.display_name LIKE ? OR u.firebase_uid LIKE ?`,
      )
      .bind(pattern, pattern, pattern)
      .first<{ total: number }>();

    const { results } = await db
      .prepare(
        `${userListSql}
         WHERE u.email LIKE ? OR u.display_name LIKE ? OR u.firebase_uid LIKE ?
         ${USER_ORDER_BY}
         LIMIT ? OFFSET ?`,
      )
      .bind(pattern, pattern, pattern, limit, offset)
      .all<AdminUserRow>();

    return {
      users: (results ?? []).map((row) => mapUserSummary(row, env)),
      total: countRow?.total ?? 0,
    };
  }

  const countRow = await db
    .prepare(`SELECT COUNT(*) AS total FROM users`)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(
      `${userListSql}
       ${USER_ORDER_BY}
       LIMIT ? OFFSET ?`,
    )
    .bind(limit, offset)
    .all<AdminUserRow>();

  return {
    users: (results ?? []).map((row) => mapUserSummary(row, env)),
    total: countRow?.total ?? 0,
  };
}

export async function getUserAdminDetail(
  db: D1Database,
  uid: string,
  environment?: string,
): Promise<AdminUserSummary | null> {
  if (!isLocalUnlimitedMode(environment)) {
    await ensureSupportChatSchema(db);
  }
  const row = await db
    .prepare(`${buildUserListSql(environment)} WHERE u.firebase_uid = ?`)
    .bind(uid)
    .first<AdminUserRow>();
  return row ? mapUserSummary(row, environment) : null;
}

export async function logAdminAction(
  db: D1Database,
  input: {
    adminUid: string;
    targetUid?: string;
    action: string;
    metadata?: Record<string, unknown>;
  },
): Promise<void> {
  try {
    await db
      .prepare(
        `INSERT INTO admin_actions (admin_uid, target_uid, action, metadata_json)
         VALUES (?, ?, ?, ?)`,
      )
      .bind(
        input.adminUid,
        input.targetUid ?? null,
        input.action,
        input.metadata ? JSON.stringify(input.metadata) : null,
      )
      .run();
  } catch (err) {
    console.warn('[admin] audit log failed:', input.action, err);
  }
}

async function usersTableHasColumn(
  db: D1Database,
  column: string,
): Promise<boolean> {
  const { results } = await db
    .prepare(`PRAGMA table_info(users)`)
    .all<{ name: string }>();
  return (results ?? []).some((r) => r.name === column);
}

export async function updateUserByAdmin(
  db: D1Database,
  input: {
    targetUid: string;
    adminUid: string;
    environment?: string;
    planCode?: string;
    quotaBytesOverride?: number | null;
    clearQuotaOverride?: boolean;
    maxFileSizeBytesOverride?: number | null;
    clearTransferOverride?: boolean;
    canSwitchApiEndpoint?: boolean;
  },
): Promise<{ user: AdminUserSummary } | { error: string }> {
  const localUnlimited = isLocalUnlimitedMode(input.environment);
  const existing = await getUserAdminDetail(
    db,
    input.targetUid,
    input.environment,
  );
  if (!existing) return { error: 'Utilizador nao encontrado.' };

  let mustClearLocalOverrides = false;
  if (localUnlimited) {
    const raw = await db
      .prepare(
        `SELECT quota_bytes_override, max_file_size_bytes_override
         FROM users WHERE firebase_uid = ?`,
      )
      .bind(input.targetUid)
      .first<{
        quota_bytes_override: number | null;
        max_file_size_bytes_override: number | null;
      }>();
    mustClearLocalOverrides =
      raw?.quota_bytes_override != null ||
      raw?.max_file_size_bytes_override != null;
  }

  const incomingPlanCode =
    typeof input.planCode === 'string' && input.planCode.trim() !== ''
      ? input.planCode.trim()
      : undefined;
  const hasPlanChange =
    incomingPlanCode !== undefined && incomingPlanCode !== existing.planCode;
  let hasQuotaOverrideChange =
    input.quotaBytesOverride !== undefined || input.clearQuotaOverride === true;
  let hasOverrideChange =
    input.maxFileSizeBytesOverride !== undefined ||
    input.clearTransferOverride === true;
  const hasSwitchChange = input.canSwitchApiEndpoint !== undefined;

  if (localUnlimited) {
    hasQuotaOverrideChange = false;
    hasOverrideChange = false;
  }

  if (
    !hasPlanChange &&
    !hasQuotaOverrideChange &&
    !hasOverrideChange &&
    !hasSwitchChange &&
    !mustClearLocalOverrides
  ) {
    return { error: 'Nada para actualizar.' };
  }

  if (hasQuotaOverrideChange) {
    const hasCol = await usersTableHasColumn(db, 'quota_bytes_override');
    if (!hasCol) {
      return {
        error:
          'Migracao 0018 pendente (quota_bytes_override). No servidor API execute: npm run db:migrate:local',
      };
    }
  }

  if (hasOverrideChange) {
    const hasCol = await usersTableHasColumn(db, 'max_file_size_bytes_override');
    if (!hasCol) {
      return {
        error:
          'Migracao 0009 pendente (max_file_size_bytes_override). No servidor API execute: npm run db:migrate:local',
      };
    }
  }

  let planCode = existing.planCode;
  let quotaOverride: number | null = localUnlimited
    ? null
    : existing.quotaOverrideBytes;
  if (!localUnlimited) {
    if (input.clearQuotaOverride === true) {
      quotaOverride = null;
    } else if (input.quotaBytesOverride !== undefined) {
      if (input.quotaBytesOverride === null) {
        quotaOverride = null;
      } else {
        const err = validateQuotaOverrideBytes(input.quotaBytesOverride);
        if (err) return { error: err };
        quotaOverride = Math.floor(input.quotaBytesOverride);
      }
    }
  }

  if (hasPlanChange) {
    const plan = getPlanByCode(incomingPlanCode!);
    if (!plan) return { error: 'Plano invalido.' };
    if (!localUnlimited) {
      const effectiveQuota = effectiveQuotaBytes(plan.quotaBytes, quotaOverride);
      if (existing.storageUsedBytes > effectiveQuota) {
        return {
          error:
            'Uso de armazenamento excede a quota do novo plano. O utilizador deve libertar espaco primeiro.',
        };
      }
    }
    planCode = incomingPlanCode!;
  }

  if (!localUnlimited) {
    const effectiveQuotaAfter = effectiveQuotaBytes(
      hasPlanChange
        ? (getPlanByCode(planCode)?.quotaBytes ?? existing.planQuotaBytes)
        : existing.planQuotaBytes,
      quotaOverride,
    );
    if (existing.storageUsedBytes > effectiveQuotaAfter) {
      return {
        error:
          'Uso actual excede a capacidade definida. O utilizador deve apagar ficheiros primeiro.',
      };
    }
  }

  let transferOverride: number | null = localUnlimited
    ? null
    : existing.transferOverrideBytes;
  if (!localUnlimited) {
    if (input.clearTransferOverride === true) {
      transferOverride = null;
    } else if (input.maxFileSizeBytesOverride !== undefined) {
      if (input.maxFileSizeBytesOverride === null) {
        transferOverride = null;
      } else {
        const err = validateTransferOverrideBytes(
          input.maxFileSizeBytesOverride,
        );
        if (err) return { error: err };
        transferOverride = Math.floor(input.maxFileSizeBytesOverride);
      }
    }
  }

  const canSwitchApiEndpoint = hasSwitchChange
    ? input.canSwitchApiEndpoint!
    : existing.canSwitchApiEndpoint;

  await db
    .prepare(
      `UPDATE users SET
         plan_code = ?,
         quota_bytes_override = ?,
         max_file_size_bytes_override = ?,
         can_switch_api_endpoint = ?,
         updated_at = datetime('now')
       WHERE firebase_uid = ?`,
    )
    .bind(
      planCode,
      quotaOverride,
      transferOverride,
      canSwitchApiEndpoint ? 1 : 0,
      input.targetUid,
    )
    .run();

  if (hasPlanChange) {
    await activateOrRenewSubscription(db, {
      firebaseUid: input.targetUid,
      planCode,
    });
  }

  const changes: Record<string, unknown> = {};
  if (hasPlanChange) {
    changes.planCode = { from: existing.planCode, to: planCode };
  }
  if (hasQuotaOverrideChange) {
    changes.quotaOverrideBytes = {
      from: existing.quotaOverrideBytes,
      to: quotaOverride,
    };
  }
  if (hasOverrideChange) {
    changes.transferOverrideBytes = {
      from: existing.transferOverrideBytes,
      to: transferOverride,
    };
  }
  if (hasSwitchChange) {
    changes.canSwitchApiEndpoint = {
      from: existing.canSwitchApiEndpoint,
      to: canSwitchApiEndpoint,
    };
  }

  const action =
    hasSwitchChange &&
    !hasPlanChange &&
    !hasOverrideChange &&
    !hasQuotaOverrideChange
      ? 'can_switch_api_change'
      : hasPlanChange
        ? hasOverrideChange || hasQuotaOverrideChange
          ? 'user_update_plan_transfer'
          : 'plan_change'
        : hasQuotaOverrideChange && hasOverrideChange
          ? 'user_update_quota_transfer'
          : hasQuotaOverrideChange
            ? 'quota_override'
            : 'transfer_override';

  await logAdminAction(db, {
    adminUid: input.adminUid,
    targetUid: input.targetUid,
    action,
    metadata: changes,
  });

  const updated = await getUserAdminDetail(
    db,
    input.targetUid,
    input.environment,
  );
  if (!updated) return { error: 'Falha ao actualizar utilizador.' };

  if (!localUnlimited && (hasQuotaOverrideChange || hasOverrideChange)) {
    const quotaGb = (updated.quotaBytes / (1024 * 1024 * 1024)).toFixed(0);
    const transferMb = (updated.maxFileSizeBytes / (1024 * 1024)).toFixed(0);
    const eventBody = hasOverrideChange
      ? `Armazenamento: ${quotaGb} GB · Transferência máx.: ${transferMb} MB por ficheiro.`
      : `Armazenamento: ${quotaGb} GB.`;
    await insertAccountEvent(db, {
      firebaseUid: input.targetUid,
      kind: 'quota_updated',
      title: 'Limites actualizados',
      body: eventBody,
      metadata: {
        quotaBytes: updated.quotaBytes,
        maxFileSizeBytes: updated.maxFileSizeBytes,
        quotaOverrideBytes: updated.quotaOverrideBytes,
        transferOverrideBytes: updated.transferOverrideBytes,
      },
    });
  }

  return { user: updated };
}

export type SecurityEventDto = {
  id: number;
  eventType: string;
  firebaseUid: string | null;
  ipHash: string | null;
  path: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: string;
};

export async function listSecurityEventsAdmin(
  db: D1Database,
  limit = 50,
): Promise<SecurityEventDto[]> {
  const { results } = await db
    .prepare(
      `SELECT id, event_type, firebase_uid, ip_hash, path, metadata_json, created_at
       FROM security_events
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .bind(Math.min(100, Math.max(1, limit)))
    .all<{
      id: number;
      event_type: string;
      firebase_uid: string | null;
      ip_hash: string | null;
      path: string | null;
      metadata_json: string | null;
      created_at: string;
    }>();

  return (results ?? []).map((r) => ({
    id: r.id,
    eventType: r.event_type,
    firebaseUid: r.firebase_uid,
    ipHash: r.ip_hash,
    path: r.path,
    metadata: r.metadata_json
      ? (JSON.parse(r.metadata_json) as Record<string, unknown>)
      : null,
    createdAt: r.created_at,
  }));
}

export type ActivityFeedItem = {
  id: number;
  action: string;
  fileId: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: string;
  uid: string;
  email: string | null;
  displayName: string | null;
};

export async function listActivityFeedAdmin(
  db: D1Database,
  limit = 50,
): Promise<ActivityFeedItem[]> {
  const capped = Math.min(200, Math.max(1, limit));
  const { results } = await db
    .prepare(
      `SELECT
         fa.id,
         fa.action,
         fa.file_id,
         fa.metadata_json,
         fa.created_at,
         u.firebase_uid,
         u.email,
         u.display_name
       FROM file_actions fa
       INNER JOIN users u ON u.firebase_uid = fa.firebase_uid
       ORDER BY fa.created_at DESC
       LIMIT ?`,
    )
    .bind(capped)
    .all<{
      id: number;
      action: string;
      file_id: string | null;
      metadata_json: string | null;
      created_at: string;
      firebase_uid: string;
      email: string | null;
      display_name: string | null;
    }>();

  return (results ?? []).map((r) => ({
    id: r.id,
    action: r.action,
    fileId: r.file_id,
    metadata: r.metadata_json
      ? (JSON.parse(r.metadata_json) as Record<string, unknown>)
      : null,
    createdAt: r.created_at,
    uid: r.firebase_uid,
    email: r.email,
    displayName: r.display_name,
  }));
}

export type ActiveUserSummary = {
  uid: string;
  email: string | null;
  displayName: string | null;
  lastSeenAt: string;
  filesCount: number;
};

/** Utilizadores com actividade recente na API local (updated_at). */
export async function listRecentlyActiveUsersAdmin(
  db: D1Database,
  minutes = 30,
): Promise<ActiveUserSummary[]> {
  const window = Math.min(24 * 60, Math.max(5, minutes));
  const { results } = await db
    .prepare(
      `SELECT
         u.firebase_uid,
         u.email,
         u.display_name,
         u.updated_at,
         (SELECT COUNT(*) FROM files f
          WHERE f.firebase_uid = u.firebase_uid
            AND f.status = 'active' AND f.deleted_at IS NULL) AS files_count
       FROM users u
       WHERE u.updated_at >= datetime('now', ?)
       ORDER BY u.updated_at DESC
       LIMIT 50`,
    )
    .bind(`-${window} minutes`)
    .all<{
      firebase_uid: string;
      email: string | null;
      display_name: string | null;
      updated_at: string;
      files_count: number;
    }>();

  return (results ?? []).map((r) => ({
    uid: r.firebase_uid,
    email: r.email,
    displayName: r.display_name,
    lastSeenAt: r.updated_at,
    filesCount: r.files_count,
  }));
}

export type BladeFileListItem = {
  id: string;
  name: string;
  mimeType: string | null;
  category: string;
  sizeBytes: number;
  status: string;
  createdAt: string;
};

export type BladeUserFilesGroup = {
  uid: string;
  email: string | null;
  displayName: string | null;
  filesCount: number;
  totalSizeBytes: number;
  files: BladeFileListItem[];
};

function fileCategoryFromMime(mime: string | null): string {
  if (!mime) return 'outros';
  const m = mime.toLowerCase();
  if (m.startsWith('image/')) return 'imagens';
  if (m.startsWith('video/')) return 'video';
  if (m.startsWith('audio/')) return 'audio';
  if (
    m.startsWith('text/') ||
    m.includes('pdf') ||
    m.includes('document') ||
    m.includes('spreadsheet') ||
    m.includes('presentation')
  ) {
    return 'documentos';
  }
  return 'outros';
}

/** Ficheiros activos agrupados por utilizador (metadados — sem download). */
export async function listFilesGroupedByUserAdmin(
  db: D1Database,
  limitPerUser = 100,
): Promise<BladeUserFilesGroup[]> {
  const perUser = Math.min(500, Math.max(1, limitPerUser));
  const { results } = await db
    .prepare(
      `SELECT
         f.id,
         f.firebase_uid,
         f.name,
         f.mime_type,
         f.size_bytes,
         f.status,
         f.created_at,
         u.email,
         u.display_name
       FROM files f
       INNER JOIN users u ON u.firebase_uid = f.firebase_uid
       WHERE f.deleted_at IS NULL AND f.status = 'active'
       ORDER BY
         LOWER(COALESCE(u.display_name, u.email, u.firebase_uid)) ASC,
         LOWER(f.name) ASC`,
    )
    .all<{
      id: string;
      firebase_uid: string;
      name: string;
      mime_type: string | null;
      size_bytes: number;
      status: string;
      created_at: string;
      email: string | null;
      display_name: string | null;
    }>();

  const byUser = new Map<string, BladeUserFilesGroup>();

  for (const row of results ?? []) {
    let group = byUser.get(row.firebase_uid);
    if (!group) {
      group = {
        uid: row.firebase_uid,
        email: row.email,
        displayName: row.display_name,
        filesCount: 0,
        totalSizeBytes: 0,
        files: [],
      };
      byUser.set(row.firebase_uid, group);
    }
    if (group.files.length >= perUser) continue;
    group.files.push({
      id: row.id,
      name: row.name,
      mimeType: row.mime_type,
      category: fileCategoryFromMime(row.mime_type),
      sizeBytes: row.size_bytes,
      status: row.status,
      createdAt: row.created_at,
    });
    group.totalSizeBytes += row.size_bytes;
    group.filesCount += 1;
  }

  // Contagem total por utilizador (mesmo quando truncado por limitPerUser)
  const { results: counts } = await db
    .prepare(
      `SELECT firebase_uid, COUNT(*) AS cnt, COALESCE(SUM(size_bytes), 0) AS total
       FROM files
       WHERE deleted_at IS NULL AND status = 'active'
       GROUP BY firebase_uid`,
    )
    .all<{ firebase_uid: string; cnt: number; total: number }>();

  for (const c of counts ?? []) {
    const g = byUser.get(c.firebase_uid);
    if (g) {
      g.filesCount = c.cnt;
      g.totalSizeBytes = c.total;
    }
  }

  return [...byUser.values()];
}

export type AdminFeedbackDto = {
  id: number;
  firebaseUid: string | null;
  email: string | null;
  message: string;
  appVersion: string | null;
  platform: string | null;
  createdAt: string;
  reviewedAt: string | null;
};

function mapFeedbackRow(r: {
  id: number;
  firebase_uid: string | null;
  email: string | null;
  message: string;
  app_version: string | null;
  platform: string | null;
  created_at: string;
  reviewed_at: string | null;
}): AdminFeedbackDto {
  return {
    id: r.id,
    firebaseUid: r.firebase_uid,
    email: r.email,
    message: r.message,
    appVersion: r.app_version,
    platform: r.platform,
    createdAt: r.created_at,
    reviewedAt: r.reviewed_at,
  };
}

export async function listBetaFeedbackAdmin(
  db: D1Database,
  limit = 30,
): Promise<AdminFeedbackDto[]> {
  const { results } = await db
    .prepare(
      `SELECT id, firebase_uid, email, message, app_version, platform, created_at, reviewed_at
       FROM beta_feedback
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .bind(Math.min(100, Math.max(1, limit)))
    .all<{
      id: number;
      firebase_uid: string | null;
      email: string | null;
      message: string;
      app_version: string | null;
      platform: string | null;
      created_at: string;
      reviewed_at: string | null;
    }>();

  return (results ?? []).map(mapFeedbackRow);
}

export async function listUserFeedbackAdmin(
  db: D1Database,
  firebaseUid: string,
  limit = 50,
): Promise<AdminFeedbackDto[]> {
  const { results } = await db
    .prepare(
      `SELECT id, firebase_uid, email, message, app_version, platform, created_at, reviewed_at
       FROM beta_feedback
       WHERE firebase_uid = ?
       ORDER BY reviewed_at IS NULL DESC, created_at DESC
       LIMIT ?`,
    )
    .bind(firebaseUid, Math.min(100, Math.max(1, limit)))
    .all<{
      id: number;
      firebase_uid: string | null;
      email: string | null;
      message: string;
      app_version: string | null;
      platform: string | null;
      created_at: string;
      reviewed_at: string | null;
    }>();

  return (results ?? []).map(mapFeedbackRow);
}

export async function markFeedbackReviewedAdmin(
  db: D1Database,
  input: { feedbackId: number; adminUid: string },
): Promise<{ feedback: AdminFeedbackDto } | { error: string }> {
  const row = await db
    .prepare(
      `SELECT id, firebase_uid, email, message, app_version, platform, created_at, reviewed_at
       FROM beta_feedback WHERE id = ?`,
    )
    .bind(input.feedbackId)
    .first<{
      id: number;
      firebase_uid: string | null;
      email: string | null;
      message: string;
      app_version: string | null;
      platform: string | null;
      created_at: string;
      reviewed_at: string | null;
    }>();

  if (!row) return { error: 'Feedback nao encontrado.' };
  if (row.reviewed_at) {
    return { feedback: mapFeedbackRow(row) };
  }

  await db
    .prepare(
      `UPDATE beta_feedback SET reviewed_at = datetime('now') WHERE id = ?`,
    )
    .bind(input.feedbackId)
    .run();

  await logAdminAction(db, {
    adminUid: input.adminUid,
    targetUid: row.firebase_uid ?? undefined,
    action: 'feedback_reviewed',
    metadata: { feedbackId: input.feedbackId },
  });

  const updated = await db
    .prepare(
      `SELECT id, firebase_uid, email, message, app_version, platform, created_at, reviewed_at
       FROM beta_feedback WHERE id = ?`,
    )
    .bind(input.feedbackId)
    .first<{
      id: number;
      firebase_uid: string | null;
      email: string | null;
      message: string;
      app_version: string | null;
      platform: string | null;
      created_at: string;
      reviewed_at: string | null;
    }>();

  if (!updated) return { error: 'Falha ao actualizar feedback.' };

  if (row.firebase_uid) {
    await insertAccountEvent(db, {
      firebaseUid: row.firebase_uid,
      kind: 'support_reviewed',
      title: 'Suporte tratado',
      body: 'A equipa KiamiCloud marcou a sua mensagem como tratada.',
      metadata: { feedbackId: input.feedbackId },
    });
  }

  return { feedback: mapFeedbackRow(updated) };
}

export async function listCheckoutsAdmin(
  db: D1Database,
  input: { limit?: number; status?: string } = {},
): Promise<
  Array<{
    id: string;
    firebaseUid: string;
    userEmail: string | null;
    planCode: string;
    amountKz: number;
    reference: string;
    status: string;
    hasProof: boolean;
    proofSubmittedAt: string | null;
    rejectionReason: string | null;
    createdAt: string;
  }>
> {
  const limit = Math.min(100, Math.max(1, input.limit ?? 30));
  const status = input.status?.trim();
  const sql = status
    ? `SELECT c.id, c.firebase_uid, u.email AS user_email, c.plan_code, c.amount_kz,
              c.reference, c.status, c.proof_r2_key, c.proof_submitted_at,
              c.rejection_reason, c.created_at
       FROM payment_checkouts c
       LEFT JOIN users u ON u.firebase_uid = c.firebase_uid
       WHERE c.status = ?
       ORDER BY c.created_at DESC
       LIMIT ?`
    : `SELECT c.id, c.firebase_uid, u.email AS user_email, c.plan_code, c.amount_kz,
              c.reference, c.status, c.proof_r2_key, c.proof_submitted_at,
              c.rejection_reason, c.created_at
       FROM payment_checkouts c
       LEFT JOIN users u ON u.firebase_uid = c.firebase_uid
       ORDER BY c.created_at DESC
       LIMIT ?`;

  const { results } = await db
    .prepare(sql)
    .bind(...(status ? [status, limit] : [limit]))
    .all<{
      id: string;
      firebase_uid: string;
      user_email: string | null;
      plan_code: string;
      amount_kz: number;
      reference: string;
      status: string;
      proof_r2_key: string | null;
      proof_submitted_at: string | null;
      rejection_reason: string | null;
      created_at: string;
    }>();

  return (results ?? []).map((r) => ({
    id: r.id,
    firebaseUid: r.firebase_uid,
    userEmail: r.user_email,
    planCode: r.plan_code,
    amountKz: r.amount_kz,
    reference: r.reference,
    status: r.status,
    hasProof: Boolean(r.proof_r2_key),
    proofSubmittedAt: r.proof_submitted_at,
    rejectionReason: r.rejection_reason,
    createdAt: r.created_at,
  }));
}
