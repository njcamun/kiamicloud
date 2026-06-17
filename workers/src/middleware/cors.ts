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

/** Firebase Hosting / preview channels do projecto kiamicloud. */
function isKiamiWebOrigin(origin: string): boolean {
  try {
    const host = new URL(origin).hostname.toLowerCase();
    if (host === 'kiamicloud.firebaseapp.com') return true;
    if (host === 'kiamicloud.web.app') return true;
  } catch {
    return false;
  }
  return false;
}

/** CORS: localhost em dev; Firebase Hosting em beta/prod; API_ALLOWED_ORIGINS extra. */
export const kiamiCors = () =>
  cors({
    origin: (origin, c) => {
      if (!origin) return 'http://localhost';

      const allowed = parseAllowedOrigins(c.env.API_ALLOWED_ORIGINS);
      if (allowed.includes(origin)) return origin;

      const env = c.env.ENVIRONMENT ?? 'development';
      if (
        (env === 'beta' || env === 'production') &&
        isKiamiWebOrigin(origin)
      ) {
        return origin;
      }

      if (env !== 'production' && isLocalDevOrigin(origin)) {
        return origin;
      }

      if (
        origin.startsWith('http://localhost:') ||
        origin.startsWith('http://127.0.0.1:') ||
        origin === 'http://localhost' ||
        origin === 'http://127.0.0.1'
      ) {
        return origin;
      }

      return null;
    },
    allowHeaders: ['Authorization', 'Content-Type', 'Accept'],
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    exposeHeaders: ['Content-Length'],
    maxAge: 86400,
    credentials: true,
  });
