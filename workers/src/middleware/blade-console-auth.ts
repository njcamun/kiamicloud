import { createMiddleware } from 'hono/factory';
import { getCookie } from 'hono/cookie';
import type { Env } from '../types';
import {
  BLADE_CONSOLE_COOKIE,
  verifyBladeConsoleSession,
} from '../lib/blade-console-session';

export type BladeConsoleCredentials = {
  user: string;
  password: string;
};

export function bladeConsoleCredentials(env: Env): BladeConsoleCredentials | null {
  if (env.ENVIRONMENT !== 'development') return null;
  return {
    user: env.BLADE_CONSOLE_USER?.trim() || 'admin',
    password: env.BLADE_CONSOLE_PASSWORD?.trim() || 'admin',
  };
}

export function isBladeConsoleEnabled(env: Env): boolean {
  return env.ENVIRONMENT === 'development';
}

/** Sessao local da consola Blade (cookie HttpOnly — sem Firebase). */
export const requireBladeConsoleSession = createMiddleware<{ Bindings: Env }>(
  async (c, next) => {
    if (!isBladeConsoleEnabled(c.env)) {
      return c.text('Not found', 404);
    }

    const creds = bladeConsoleCredentials(c.env)!;
    const token = getCookie(c, BLADE_CONSOLE_COOKIE);
    if (!token) {
      return c.json(
        { error: 'unauthorized', message: 'Inicie sessao na consola.' },
        401,
      );
    }

    const ok = await verifyBladeConsoleSession(
      token,
      creds.user,
      creds.password,
    );
    if (!ok) {
      return c.json(
        { error: 'unauthorized', message: 'Sessao invalida ou expirada.' },
        401,
      );
    }

    await next();
  },
);
