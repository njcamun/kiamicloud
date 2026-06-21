import type { Context } from 'hono';
import type { Env } from '../types';

/** IP do cliente (Cloudflare ou ligacao directa em dev). */
export function getClientIp(c: Context): string {
  return (
    c.req.header('CF-Connecting-IP') ??
    c.req.header('X-Forwarded-For')?.split(',')[0]?.trim() ??
    'unknown'
  );
}

/** Pepper para hash de IP — preferir secret dedicado ou webhook secret. */
export function getIpHashPepper(
  env: Pick<Env, 'SECURITY_IP_PEPPER' | 'PAYMENT_WEBHOOK_SECRET' | 'MEDIA_TOKEN_SECRET'>,
): string {
  return (
    env.SECURITY_IP_PEPPER?.trim() ||
    env.PAYMENT_WEBHOOK_SECRET?.trim() ||
    env.MEDIA_TOKEN_SECRET?.trim() ||
    'kiami-dev-ip-pepper'
  );
}

/** Hash curto para logs sem guardar IP em claro. */
export async function hashIp(ip: string, pepper?: string): Promise<string> {
  const data = new TextEncoder().encode(`${pepper ?? 'kiami:'}:${ip}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return hex.slice(0, 16);
}
