import { createMiddleware } from 'hono/factory';
import type { AppVariables, Env } from '../types';
import { isCloudSupportChatEnabled } from '../lib/local_unlimited';

/** Bloqueia chat de suporte no servidor local (Blade). */
export const requireCloudSupportChat = createMiddleware<{
  Bindings: Env;
  Variables: AppVariables;
}>(async (c, next) => {
  if (!isCloudSupportChatEnabled(c.env.ENVIRONMENT)) {
    return c.json(
      {
        error: 'support_cloud_only',
        message:
          'Chat de suporte disponivel apenas na API Cloudflare. ' +
          'Altere o servidor da app para Cloudflare.',
      },
      404,
    );
  }
  await next();
});
