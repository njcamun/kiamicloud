import { createMiddleware } from 'hono/factory';
import type { Env } from '../types';

/** Cabecalhos de seguranca HTTP (Fase 11). */
export const securityHeaders = () =>
  createMiddleware<{ Bindings: Env }>(async (c, next) => {
    await next();
    c.header('X-Content-Type-Options', 'nosniff');
    c.header('X-Frame-Options', 'DENY');
    c.header('Referrer-Policy', 'strict-origin-when-cross-origin');
    c.header('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    c.header('X-KiamiCloud-API', '1');
    if (c.env.ENVIRONMENT === 'production') {
      c.header(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains',
      );
    }
  });
