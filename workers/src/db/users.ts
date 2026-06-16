import { effectiveMaxFileSizeBytes } from '../lib/effective_max_file';
import { effectiveQuotaBytes } from '../lib/effective_quota';
import type { AuthUser } from '../types';
import type { UserProfile, UserRow } from './schema';

const USER_WITH_PLAN_SQL = `
  SELECT
    u.firebase_uid,
    u.email,
    u.display_name,
    u.photo_url,
    u.plan_code,
    u.storage_used_bytes,
    COALESCE(u.can_switch_api_endpoint, 0) AS can_switch_api_endpoint,
    u.created_at,
    u.updated_at,
    p.name AS plan_name,
    p.quota_bytes AS plan_quota_bytes,
    p.price_kz_month AS plan_price_kz_month,
    p.max_file_size_bytes AS plan_max_file_size_bytes,
    u.max_file_size_bytes_override,
    u.quota_bytes_override
  FROM users u
  INNER JOIN plans p ON p.code = u.plan_code
  WHERE u.firebase_uid = ?
`;

type UserWithPlanRow = UserRow & {
  plan_name: string;
  plan_quota_bytes: number;
  plan_price_kz_month: number;
  plan_max_file_size_bytes: number;
  max_file_size_bytes_override: number | null;
  quota_bytes_override: number | null;
};

function mapProfile(row: UserWithPlanRow): UserProfile {
  const used = row.storage_used_bytes;
  const quota = effectiveQuotaBytes(
    row.plan_quota_bytes,
    row.quota_bytes_override,
  );
  return {
    uid: row.firebase_uid,
    email: row.email,
    displayName: row.display_name,
    photoUrl: row.photo_url,
    plan: {
      code: row.plan_code,
      name: row.plan_name,
      quotaBytes: quota,
      priceKzMonth: row.plan_price_kz_month,
      maxFileSizeBytes: effectiveMaxFileSizeBytes(
        row.plan_max_file_size_bytes,
        row.max_file_size_bytes_override,
      ),
    },
    storageUsedBytes: used,
    storageAvailableBytes: Math.max(0, quota - used),
    canSwitchApiEndpoint: row.can_switch_api_endpoint === 1,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function fetchProfile(
  db: D1Database,
  uid: string,
): Promise<UserProfile | null> {
  const row = await db
    .prepare(USER_WITH_PLAN_SQL)
    .bind(uid)
    .first<UserWithPlanRow>();
  return row ? mapProfile(row) : null;
}

/**
 * Cria ou actualiza perfil D1 a partir do JWT Firebase.
 * Novo utilizador recebe plano `basico` automaticamente.
 */
export async function ensureUser(
  db: D1Database,
  auth: AuthUser,
): Promise<UserProfile> {
  const existing = await fetchProfile(db, auth.uid);

  if (!existing) {
    await db
      .prepare(
        `INSERT INTO users (firebase_uid, email, display_name, photo_url, plan_code, can_switch_api_endpoint)
         VALUES (?, ?, ?, ?, 'basico', 0)`,
      )
      .bind(
        auth.uid,
        auth.email ?? null,
        auth.name ?? null,
        auth.picture ?? null,
      )
      .run();

    const created = await fetchProfile(db, auth.uid);
    if (!created) {
      throw new Error('Falha ao criar perfil do utilizador.');
    }
    return created;
  }

  await db
    .prepare(
      `UPDATE users SET
         email = COALESCE(?, email),
         display_name = COALESCE(?, display_name),
         photo_url = COALESCE(?, photo_url),
         updated_at = datetime('now')
       WHERE firebase_uid = ?`,
    )
    .bind(
      auth.email ?? null,
      auth.name ?? null,
      auth.picture ?? null,
      auth.uid,
    )
    .run();

  const updated = await fetchProfile(db, auth.uid);
  return updated ?? existing;
}

export async function getUserProfile(
  db: D1Database,
  uid: string,
): Promise<UserProfile | null> {
  return fetchProfile(db, uid);
}

export type UserProfileWithOverrides = UserProfile & {
  quotaBytesOverride: number | null;
  maxFileSizeBytesOverride: number | null;
};

export async function getUserProfileWithOverrides(
  db: D1Database,
  uid: string,
): Promise<UserProfileWithOverrides | null> {
  const row = await db
    .prepare(USER_WITH_PLAN_SQL)
    .bind(uid)
    .first<UserWithPlanRow>();
  if (!row) return null;
  return {
    ...mapProfile(row),
    quotaBytesOverride: row.quota_bytes_override,
    maxFileSizeBytesOverride: row.max_file_size_bytes_override,
  };
}
