import type { Context } from 'hono';

/** IP do cliente (Cloudflare ou ligacao directa em dev). */
export function getClientIp(c: Context): string {
  return (
    c.req.header('CF-Connecting-IP') ??
    c.req.header('X-Forwarded-For')?.split(',')[0]?.trim() ??
    'unknown'
  );
}

/** Hash curto para logs sem guardar IP em claro. */
export async function hashIp(ip: string): Promise<string> {
  const data = new TextEncoder().encode(`kiami:${ip}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return hex.slice(0, 16);
}
