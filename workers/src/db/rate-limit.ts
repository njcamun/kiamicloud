export type RateLimitResult = {
  allowed: boolean;
  remaining: number;
  limit: number;
  retryAfterSeconds?: number;
};

/**
 * Rate limit por bucket (D1) — janela fixa em segundos.
 * Funciona em dev local e producao sem KV extra.
 */
export async function checkRateLimit(
  db: D1Database,
  bucketKey: string,
  limit: number,
  windowSeconds: number,
): Promise<RateLimitResult> {
  const nowMs = Date.now();
  const windowMs = windowSeconds * 1000;

  const row = await db
    .prepare(
      `SELECT count, window_start_ms FROM rate_limit_buckets WHERE bucket_key = ?`,
    )
    .bind(bucketKey)
    .first<{ count: number; window_start_ms: number }>();

  if (!row || nowMs - row.window_start_ms >= windowMs) {
    await db
      .prepare(
        `INSERT INTO rate_limit_buckets (bucket_key, count, window_start_ms)
         VALUES (?, 1, ?)
         ON CONFLICT(bucket_key) DO UPDATE SET
           count = 1,
           window_start_ms = excluded.window_start_ms`,
      )
      .bind(bucketKey, nowMs)
      .run();
    return { allowed: true, remaining: limit - 1, limit };
  }

  const nextCount = row.count + 1;
  if (nextCount > limit) {
    const retryAfterSeconds = Math.ceil(
      (row.window_start_ms + windowMs - nowMs) / 1000,
    );
    return {
      allowed: false,
      remaining: 0,
      limit,
      retryAfterSeconds: Math.max(1, retryAfterSeconds),
    };
  }

  await db
    .prepare(`UPDATE rate_limit_buckets SET count = ? WHERE bucket_key = ?`)
    .bind(nextCount, bucketKey)
    .run();

  return {
    allowed: true,
    remaining: limit - nextCount,
    limit,
  };
}
