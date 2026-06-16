import { AwsClient } from 'aws4fetch';
import type { Env } from '../types';

export function canPresignR2(env: Env): boolean {
  return !!(
    env.R2_ACCOUNT_ID &&
    env.R2_ACCESS_KEY_ID &&
    env.R2_SECRET_ACCESS_KEY &&
    env.R2_BUCKET_NAME
  );
}

function getExpiresSeconds(env: Env): number {
  const parsed = Number(env.R2_PRESIGN_EXPIRES_SECONDS ?? '900');
  if (!Number.isFinite(parsed) || parsed < 60) return 900;
  return Math.min(parsed, 3600);
}

function buildObjectUrl(env: Env, objectKey: string): URL {
  const bucket = env.R2_BUCKET_NAME;
  const accountId = env.R2_ACCOUNT_ID!;
  const encodedKey = objectKey
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/');
  return new URL(
    `https://${accountId}.r2.cloudflarestorage.com/${bucket}/${encodedKey}`,
  );
}

async function presign(
  env: Env,
  objectKey: string,
  method: 'GET' | 'PUT',
): Promise<{ url: string; expiresAt: string; expiresInSeconds: number }> {
  const expiresInSeconds = getExpiresSeconds(env);
  const client = new AwsClient({
    accessKeyId: env.R2_ACCESS_KEY_ID!,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY!,
  });

  const url = buildObjectUrl(env, objectKey);
  url.searchParams.set('X-Amz-Expires', String(expiresInSeconds));

  const signed = await client.sign(
    new Request(url.toString(), { method }),
    {
      aws: { signQuery: true, service: 's3', region: 'auto' },
    },
  );

  const expiresAt = new Date(
    Date.now() + expiresInSeconds * 1000,
  ).toISOString();

  return {
    url: signed.url,
    expiresAt,
    expiresInSeconds,
  };
}

export function presignPut(env: Env, objectKey: string) {
  return presign(env, objectKey, 'PUT');
}

export function presignGet(env: Env, objectKey: string) {
  return presign(env, objectKey, 'GET');
}
