import { cors } from 'hono/cors';

const LOCAL_ORIGIN_PREFIXES = [
  'http://localhost:',
  'http://127.0.0.1:',
  'http://localhost',
  'http://127.0.0.1',
  'http://192.168.',
  'http://10.',
];

function parseAllowedOrigins(raw: string | undefined): string[] {
  if (!raw?.trim()) return [];
  return raw
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

function isLocalDevOrigin(origin: string): boolean {
  return LOCAL_ORIGIN_PREFIXES.some(
    (p) => origin === p || origin.startsWith(p),
  );
}

/** Firebase Hosting, preview channels e dominios do projecto kiamicloud. */
export function isKiamiWebOrigin(origin: string): boolean {
  if (origin === 'null') return false;
  try {
    const host = new URL(origin).hostname.toLowerCase();
    if (host === 'kiamicloud.firebaseapp.com') return true;
    if (host === 'kiamicloud.web.app') return true;
    if (host.endsWith('.web.app') && host.includes('kiamicloud')) return true;
    if (host.endsWith('.firebaseapp.com') && host.includes('kiamicloud')) {
      return true;
    }
  } catch {
    return false;
  }
  return false;
}

/** Cliente browser (Flutter Web / Firebase Hosting) — força proxy Worker para R2. */
export function isBrowserClientOrigin(origin: string | undefined): boolean {
  if (!origin || origin === 'null') return false;
  if (isLocalDevOrigin(origin)) return true;
  return isKiamiWebOrigin(origin);
}

function resolveCorsOrigin(
  origin: string | undefined,
  env: string,
  extraAllowed: string[],
): string | null {
  if (!origin || origin === 'null') {
    if (env === 'beta' || env === 'production') return null;
    return 'http://localhost';
  }

  if (extraAllowed.includes(origin)) return origin;

  if ((env === 'beta' || env === 'production') && isKiamiWebOrigin(origin)) {
    return origin;
  }

  // Flutter Web local (flutter run -d chrome) — origem localhost no browser do dev.
  if ((env === 'beta' || env === 'production') && isLocalDevOrigin(origin)) {
    return origin;
  }

  if (env !== 'production' && env !== 'beta' && isLocalDevOrigin(origin)) {
    return origin;
  }

  if (
    env !== 'production' &&
    env !== 'beta' &&
    (origin.startsWith('http://localhost:') ||
      origin.startsWith('http://127.0.0.1:') ||
      origin === 'http://localhost' ||
      origin === 'http://127.0.0.1')
  ) {
    return origin;
  }

  return null;
}

/** CORS: localhost em dev; Firebase Hosting em beta/prod; API_ALLOWED_ORIGINS extra. */
export const kiamiCors = () =>
  cors({
    origin: (origin, c) => {
      const env = c.env.ENVIRONMENT ?? 'development';
      const allowed = parseAllowedOrigins(c.env.API_ALLOWED_ORIGINS);
      return resolveCorsOrigin(origin, env, allowed);
    },
    allowHeaders: [
      'Authorization',
      'Content-Type',
      'Accept',
      'Range',
      'X-Kiami-Upload-Via',
      'X-Kiami-Media-Via',
    ],
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    exposeHeaders: ['Content-Length', 'Content-Range', 'Accept-Ranges'],
    maxAge: 86400,
    credentials: false,
  });

