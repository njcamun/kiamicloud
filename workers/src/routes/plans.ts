import { Hono } from 'hono';
import type { Env } from '../types';

export const plansRoutes = new Hono<{ Bindings: Env }>();

/** Lista planos activos (publico, sem auth). */
plansRoutes.get('/', async (c) => {
  const db = c.env.DB;
  if (!db) {
    return c.json(
      { error: 'server_misconfigured', message: 'Base D1 nao configurada.' },
      500,
    );
  }

  const { results } = await db
    .prepare(
      `SELECT code, name, quota_bytes, price_kz_month, max_file_size_bytes
       FROM plans
       WHERE is_active = 1
       ORDER BY quota_bytes ASC`,
    )
    .all<{
      code: string;
      name: string;
      quota_bytes: number;
      price_kz_month: number;
      max_file_size_bytes: number;
    }>();

  return c.json({
    plans: (results ?? []).map((p) => ({
      code: p.code,
      name: p.name,
      quotaBytes: p.quota_bytes,
      priceKzMonth: p.price_kz_month,
      maxFileSizeBytes: p.max_file_size_bytes,
    })),
  });
});
