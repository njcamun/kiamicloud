import { createMiddleware } from 'hono/factory';
import type { AppVariables, Env } from '../types';
import { isLocalUnlimitedMode } from '../lib/local_unlimited';

/** Exige e-mail Firebase verificado (excepto em dev local ilimitado). */
export const requireEmailVerified = createMiddleware<{
  Bindings: Env;
  Variables: AppVariables;
}>(async (c, next) => {
  if (isLocalUnlimitedMode(c.env.ENVIRONMENT)) {
    await next();
    return;
  }

  const user = c.get('user');
  if (user.emailVerified !== true) {
    return c.json(
      {
        error: 'email_not_verified',
        message: 'Confirme o seu e-mail antes de usar esta funcionalidade.',
      },
      403,
    );
  }

  await next();
});
