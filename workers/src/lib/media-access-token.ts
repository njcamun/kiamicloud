import { SignJWT, jwtVerify } from 'jose';
import type { Env } from '../types';
import { isLocalUnlimitedMode } from './local_unlimited';

export type MediaAccessKind = 'download' | 'thumbnail';

const TTL = '1h';

function resolveMediaTokenSecret(env: Env): string | null {
  const dedicated = env.MEDIA_TOKEN_SECRET?.trim();
  if (dedicated) return dedicated;

  if (isLocalUnlimitedMode(env.ENVIRONMENT)) {
    return (
      env.PAYMENT_WEBHOOK_SECRET?.trim() ??
      `${env.FIREBASE_PROJECT_ID}:media-dev-only`
    );
  }

  return null;
}

function mediaSigningKey(env: Env): Uint8Array | null {
  const secret = resolveMediaTokenSecret(env);
  if (!secret) return null;
  return new TextEncoder().encode(`${env.FIREBASE_PROJECT_ID}:media:${secret}`);
}

export function isMediaTokenConfigured(env: Env): boolean {
  return mediaSigningKey(env) !== null;
}

export async function createMediaAccessToken(
  env: Env,
  input: { uid: string; fileId: string; kind: MediaAccessKind },
): Promise<{ token: string; expiresAt: string } | null> {
  const key = mediaSigningKey(env);
  if (!key) return null;

  const token = await new SignJWT({
    uid: input.uid,
    fileId: input.fileId,
    kind: input.kind,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(TTL)
    .sign(key);

  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();
  return { token, expiresAt };
}

export async function verifyMediaAccessToken(
  env: Env,
  token: string | undefined,
  fileId: string,
  kind: MediaAccessKind,
): Promise<{ uid: string } | null> {
  const key = mediaSigningKey(env);
  if (!key || !token?.trim()) return null;
  try {
    const { payload } = await jwtVerify(token.trim(), key);
    if (payload.uid == null || typeof payload.uid !== 'string') return null;
    if (payload.fileId !== fileId) return null;
    if (payload.kind !== kind) return null;
    return { uid: payload.uid };
  } catch {
    return null;
  }
}
