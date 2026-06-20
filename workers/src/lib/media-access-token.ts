import { SignJWT, jwtVerify } from 'jose';
import type { Env } from '../types';

export type MediaAccessKind = 'download' | 'thumbnail';

const TTL = '1h';

function mediaSigningKey(env: Env): Uint8Array {
  const secret =
    env.R2_SECRET_ACCESS_KEY ??
    env.PAYMENT_WEBHOOK_SECRET ??
    `${env.FIREBASE_PROJECT_ID}:media-dev`;
  return new TextEncoder().encode(`${env.FIREBASE_PROJECT_ID}:media:${secret}`);
}

export async function createMediaAccessToken(
  env: Env,
  input: { uid: string; fileId: string; kind: MediaAccessKind },
): Promise<{ token: string; expiresAt: string }> {
  const token = await new SignJWT({
    uid: input.uid,
    fileId: input.fileId,
    kind: input.kind,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(TTL)
    .sign(mediaSigningKey(env));

  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();
  return { token, expiresAt };
}

export async function verifyMediaAccessToken(
  env: Env,
  token: string | undefined,
  fileId: string,
  kind: MediaAccessKind,
): Promise<{ uid: string } | null> {
  if (!token?.trim()) return null;
  try {
    const { payload } = await jwtVerify(token.trim(), mediaSigningKey(env));
    if (payload.uid == null || typeof payload.uid !== 'string') return null;
    if (payload.fileId !== fileId) return null;
    if (payload.kind !== kind) return null;
    return { uid: payload.uid };
  } catch {
    return null;
  }
}
