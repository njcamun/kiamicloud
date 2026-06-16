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

/** CORS: localhost em dev; API_ALLOWED_ORIGINS em producao (Fase 11). */
export const kiamiCors = () =>
  cors({
    origin: (origin, c) => {
      if (!origin) return 'http://localhost';

      const allowed = parseAllowedOrigins(c.env.API_ALLOWED_ORIGINS);
      if (allowed.includes(origin)) return origin;

      if (
        c.env.ENVIRONMENT !== 'production' &&
        isLocalDevOrigin(origin)
      ) {
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
