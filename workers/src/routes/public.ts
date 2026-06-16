import { Hono } from 'hono';
import type { Env } from '../types';
import { getPublicShareFile, recordShareAccess } from '../db/shares';
import { canPresignR2, presignGet } from '../lib/r2-presign';

export const publicRoutes = new Hono<{ Bindings: Env }>();

/** Download público via token de partilha (sem JWT). */
publicRoutes.get('/share/:token', async (c) => {
  const token = c.req.param('token')?.trim();
  if (!token || token.length < 16) {
    return c.json({ error: 'not_found', message: 'Link inválido.' }, 404);
  }

  const resolved = await getPublicShareFile(c.env.DB, token);
  if (!resolved) {
    return c.json(
      {
        error: 'not_found',
        message: 'Link expirado, revogado ou ficheiro indisponível.',
      },
      404,
    );
  }

  await recordShareAccess(c.env.DB, resolved.shareId);

  if (!canPresignR2(c.env)) {
    const origin = new URL(c.req.url).origin;
    return c.json({
      name: resolved.name,
      sizeBytes: resolved.sizeBytes,
      mimeType: resolved.mimeType,
      downloadUrl: `${origin}/public/share/${token}/download`,
      localDevDownload: true,
      expiresAt: null,
    });
  }

  const signed = await presignGet(c.env, resolved.r2ObjectKey);
  return c.json({
    name: resolved.name,
    sizeBytes: resolved.sizeBytes,
    mimeType: resolved.mimeType,
    downloadUrl: signed.url,
    expiresAt: signed.expiresAt,
    expiresInSeconds: signed.expiresInSeconds,
    localDevDownload: false,
  });
});

/** Download directo em dev local (sem auth). */
publicRoutes.get('/share/:token/download', async (c) => {
  const token = c.req.param('token')?.trim();
  if (!token) {
    return c.json({ error: 'not_found', message: 'Link inválido.' }, 404);
  }

  const resolved = await getPublicShareFile(c.env.DB, token);
  if (!resolved) {
    return c.json({ error: 'not_found', message: 'Link indisponível.' }, 404);
  }

  await recordShareAccess(c.env.DB, resolved.shareId);

  const object = await c.env.FILES_BUCKET.get(resolved.r2ObjectKey);
  if (!object) {
    return c.json({ error: 'not_found', message: 'Ficheiro ausente.' }, 404);
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set(
    'Content-Disposition',
    `attachment; filename="${resolved.name}"`,
  );

  return new Response(object.body, { headers });
});
