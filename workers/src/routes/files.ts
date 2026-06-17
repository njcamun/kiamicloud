import { Hono } from 'hono';
import type { AppVariables, Env } from '../types';
import { requireAuth } from '../middleware/auth';
import { rateLimitByUser } from '../middleware/rate-limit';
import { formatMaxFileSizeMessage } from '../config/plans';
import {
  activateFile,
  createPendingFile,
  getFileById,
  getStorageContext,
  listActiveFiles,
  listTrashFiles,
  logDownload,
  permanentDeleteFile,
  renameFile,
  restoreFile,
  setFileThumbnailKey,
  softDeleteFile,
} from '../db/files';
import { deleteR2Objects } from '../lib/delete-r2-keys';
import { isThumbnailSource } from '../lib/image-mime';
import { buildThumbR2ObjectKey } from '../lib/r2-keys';
import { sanitizeFileName } from '../lib/sanitize';
import { isLocalUnlimitedMode } from '../lib/local_unlimited';
import {
  createFileShare,
  listFileSharesForUser,
  revokeFileShare,
} from '../db/shares';
import { canPresignR2, presignGet, presignPut } from '../lib/r2-presign';
import { enforceSubscriptionAccess } from '../middleware/subscription-access';

export const filesRoutes = new Hono<{ Bindings: Env; Variables: AppVariables }>();

filesRoutes.use('/*', requireAuth);
filesRoutes.use('/*', rateLimitByUser);

/** Lista ficheiros activos do utilizador. */
filesRoutes.get('/', async (c) => {
  const user = c.get('user');
  const files = await listActiveFiles(c.env.DB, user.uid);
  return c.json({ files });
});

/** Ficheiros na lixeira (soft delete, R2 mantido ate purge). */
filesRoutes.get('/trash', async (c) => {
  const user = c.get('user');
  const files = await listTrashFiles(c.env.DB, user.uid);
  return c.json({ files });
});

/** Lista links de partilha do utilizador. */
filesRoutes.get('/shares', async (c) => {
  const user = c.get('user');
  const shares = await listFileSharesForUser(c.env.DB, user.uid);
  return c.json({ shares });
});

/** Revoga um link de partilha. */
filesRoutes.delete('/shares/:shareId', async (c) => {
  const user = c.get('user');
  const shareId = c.req.param('shareId');
  const ok = await revokeFileShare(c.env.DB, shareId, user.uid);
  if (!ok) {
    return c.json({ error: 'not_found', message: 'Partilha não encontrada.' }, 404);
  }
  return c.json({ ok: true, shareId });
});

/** Inicia upload: valida quota, regista pendente, devolve URL de upload. */
filesRoutes.post('/upload/init', async (c) => {
  const blocked = await enforceSubscriptionAccess(c, 'upload');
  if (blocked) return blocked;

  const user = c.get('user');
  const body = await c.req.json<{
    name?: string;
    sizeBytes?: number;
    mimeType?: string;
    folderId?: string;
  }>();

  const name = body.name?.trim();
  const sizeBytes = body.sizeBytes;

  if (!name) {
    return c.json({ error: 'invalid_request', message: 'Nome do ficheiro em falta.' }, 400);
  }
  if (
    typeof sizeBytes !== 'number' ||
    !Number.isFinite(sizeBytes) ||
    sizeBytes < 1
  ) {
    return c.json(
      { error: 'invalid_request', message: 'sizeBytes invalido.' },
      400,
    );
  }
  const storage = await getStorageContext(c.env.DB, user.uid, c.env.ENVIRONMENT);
  if (!storage) {
    return c.json({ error: 'not_found', message: 'Utilizador nao encontrado.' }, 404);
  }

  const localUnlimited = isLocalUnlimitedMode(c.env.ENVIRONMENT);

  // maxFileSizeBytes = 0 → sem limite por ficheiro (KiamiLocal).
  if (storage.maxFileSizeBytes > 0 && sizeBytes > storage.maxFileSizeBytes) {
    return c.json(
      {
        error: 'file_too_large',
        message: formatMaxFileSizeMessage(storage.maxFileSizeBytes),
        maxFileSizeBytes: storage.maxFileSizeBytes,
      },
      413,
    );
  }

  if (!localUnlimited && storage.storageUsedBytes + sizeBytes > storage.quotaBytes) {
    return c.json(
      {
        error: 'quota_exceeded',
        message: 'Quota de armazenamento insuficiente.',
        storageUsedBytes: storage.storageUsedBytes,
        quotaBytes: storage.quotaBytes,
      },
      403,
    );
  }

  const fileId = crypto.randomUUID();
  const { r2ObjectKey, file } = await createPendingFile(c.env.DB, {
    id: fileId,
    firebaseUid: user.uid,
    name,
    sizeBytes,
    mimeType: body.mimeType,
    folderId: body.folderId,
  });

  const expires = canPresignR2(c.env)
    ? await presignPut(c.env, r2ObjectKey)
    : null;

  const origin = new URL(c.req.url).origin;
  const uploadUrl = expires
    ? expires.url
    : `${origin}/files/upload/direct/${fileId}`;

  const thumbR2ObjectKey = isThumbnailSource(body.mimeType, name)
    ? buildThumbR2ObjectKey(user.uid, fileId)
    : null;

  let thumbnail: {
    uploadUrl: string;
    method: string;
    r2ObjectKey: string;
    expiresAt: string | null;
    expiresInSeconds: number | null;
    localDevUpload: boolean;
  } | null = null;

  if (thumbR2ObjectKey) {
    const thumbExpires = canPresignR2(c.env)
      ? await presignPut(c.env, thumbR2ObjectKey)
      : null;
    thumbnail = {
      uploadUrl: thumbExpires
        ? thumbExpires.url
        : `${origin}/files/upload/thumb/direct/${fileId}`,
      method: 'PUT',
      r2ObjectKey: thumbR2ObjectKey,
      expiresAt: thumbExpires?.expiresAt ?? null,
      expiresInSeconds: thumbExpires?.expiresInSeconds ?? null,
      localDevUpload: !thumbExpires,
    };
  }

  return c.json({
    fileId,
    file,
    uploadUrl,
    method: 'PUT',
    r2ObjectKey,
    expiresAt: expires?.expiresAt ?? null,
    expiresInSeconds: expires?.expiresInSeconds ?? null,
    localDevUpload: !expires,
    thumbnail,
    instructions: expires
      ? 'Envie PUT para uploadUrl sem Authorization. Depois POST /files/upload/complete.'
      : 'Modo local: PUT para uploadUrl com Authorization Bearer (sem credenciais R2). Depois POST /files/upload/complete.',
  });
});

/**
 * Upload directo via Worker (dev local sem API tokens R2).
 * Em producao usar URL pre-assinada de upload/init.
 */
filesRoutes.put('/upload/direct/:fileId', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const row = await getFileById(c.env.DB, fileId, user.uid);

  if (!row || row.status !== 'pending') {
    return c.json(
      { error: 'not_found', message: 'Upload pendente nao encontrado.' },
      404,
    );
  }

  if (!row.r2_object_key) {
    return c.json({ error: 'server_error', message: 'Chave R2 em falta.' }, 500);
  }

  const contentLength = c.req.header('Content-Length');
  const declaredSize = Number(contentLength);
  if (
    contentLength &&
    (!Number.isFinite(declaredSize) || declaredSize > row.size_bytes)
  ) {
    return c.json(
      { error: 'invalid_request', message: 'Tamanho do corpo excede o declarado.' },
      400,
    );
  }

  const body = c.req.raw.body;
  if (!body) {
    return c.json({ error: 'invalid_request', message: 'Corpo vazio.' }, 400);
  }

  const mimeType =
    c.req.header('Content-Type') ?? row.mime_type ?? 'application/octet-stream';

  await c.env.FILES_BUCKET.put(row.r2_object_key, body, {
    httpMetadata: { contentType: mimeType },
  });

  const head = await c.env.FILES_BUCKET.head(row.r2_object_key);
  const actualSize = head?.size ?? row.size_bytes;

  const file = await activateFile(c.env.DB, {
    fileId,
    firebaseUid: user.uid,
    actualSizeBytes: actualSize,
  });

  return c.json({
    file,
    message: 'Upload concluido (modo directo / dev).',
  });
});

/** Upload directo da miniatura (dev local). */
filesRoutes.put('/upload/thumb/direct/:fileId', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const row = await getFileById(c.env.DB, fileId, user.uid);

  if (!row || row.status !== 'active') {
    return c.json(
      { error: 'not_found', message: 'Ficheiro activo nao encontrado.' },
      404,
    );
  }

  if (!isThumbnailSource(row.mime_type, row.name)) {
    return c.json(
      { error: 'invalid_request', message: 'Miniatura apenas para imagens.' },
      400,
    );
  }

  const body = c.req.raw.body;
  if (!body) {
    return c.json({ error: 'invalid_request', message: 'Corpo vazio.' }, 400);
  }

  const thumbKey = buildThumbR2ObjectKey(user.uid, fileId);
  await c.env.FILES_BUCKET.put(thumbKey, body, {
    httpMetadata: { contentType: 'image/jpeg' },
  });

  const head = await c.env.FILES_BUCKET.head(thumbKey);
  if (!head) {
    return c.json(
      { error: 'upload_incomplete', message: 'Miniatura nao gravada no R2.' },
      400,
    );
  }

  const file = await setFileThumbnailKey(c.env.DB, fileId, user.uid, thumbKey);
  if (!file) {
    return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado.' }, 404);
  }

  return c.json({ file, message: 'Miniatura guardada.' });
});

/** Confirma miniatura apos PUT na URL pre-assinada. */
filesRoutes.post('/upload/thumb/complete', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ fileId?: string }>();
  const fileId = body.fileId?.trim();

  if (!fileId) {
    return c.json({ error: 'invalid_request', message: 'fileId em falta.' }, 400);
  }

  const row = await getFileById(c.env.DB, fileId, user.uid);
  if (!row || row.status !== 'active') {
    return c.json(
      { error: 'not_found', message: 'Ficheiro activo nao encontrado.' },
      404,
    );
  }

  if (!isThumbnailSource(row.mime_type, row.name)) {
    return c.json(
      { error: 'invalid_request', message: 'Miniatura apenas para imagens.' },
      400,
    );
  }

  const thumbKey = buildThumbR2ObjectKey(user.uid, fileId);
  const head = await c.env.FILES_BUCKET.head(thumbKey);
  if (!head) {
    return c.json(
      {
        error: 'upload_incomplete',
        message: 'Miniatura ainda nao existe no R2.',
      },
      400,
    );
  }

  const file = await setFileThumbnailKey(c.env.DB, fileId, user.uid, thumbKey);
  if (!file) {
    return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado.' }, 404);
  }

  return c.json({ file });
});

/** Confirma upload apos PUT na URL pre-assinada R2. */
filesRoutes.post('/upload/complete', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ fileId?: string }>();
  const fileId = body.fileId?.trim();

  if (!fileId) {
    return c.json({ error: 'invalid_request', message: 'fileId em falta.' }, 400);
  }

  const row = await getFileById(c.env.DB, fileId, user.uid);
  if (!row || row.status !== 'pending') {
    return c.json(
      { error: 'not_found', message: 'Upload pendente nao encontrado.' },
      404,
    );
  }

  if (!row.r2_object_key) {
    return c.json({ error: 'server_error', message: 'Chave R2 em falta.' }, 500);
  }

  const head = await c.env.FILES_BUCKET.head(row.r2_object_key);
  if (!head) {
    return c.json(
      {
        error: 'upload_incomplete',
        message: 'Ficheiro ainda nao existe no R2. Envie PUT antes de completar.',
      },
      400,
    );
  }

  const actualSize = head.size;

  const storage = await getStorageContext(c.env.DB, user.uid, c.env.ENVIRONMENT);
  const localUnlimited = isLocalUnlimitedMode(c.env.ENVIRONMENT);

  if (
    storage &&
    storage.maxFileSizeBytes > 0 &&
    actualSize > storage.maxFileSizeBytes
  ) {
    return c.json(
      {
        error: 'file_too_large',
        message: formatMaxFileSizeMessage(storage.maxFileSizeBytes),
        maxFileSizeBytes: storage.maxFileSizeBytes,
      },
      413,
    );
  }

  if (!storage) {
    return c.json({ error: 'not_found', message: 'Utilizador nao encontrado.' }, 404);
  }
  if (
    storage &&
    !localUnlimited &&
    storage.storageUsedBytes + actualSize > storage.quotaBytes
  ) {
    return c.json(
      {
        error: 'quota_exceeded',
        message: 'Quota excedida apos upload.',
      },
      403,
    );
  }

  const file = await activateFile(c.env.DB, {
    fileId,
    firebaseUid: user.uid,
    actualSizeBytes: actualSize,
  });

  if (!file) {
    return c.json({ error: 'conflict', message: 'Estado do ficheiro invalido.' }, 409);
  }

  return c.json({ file });
});

/** Cria link de partilha pública (só leitura). */
filesRoutes.post('/:fileId/shares', async (c) => {
  const blocked = await enforceSubscriptionAccess(c, 'share');
  if (blocked) return blocked;

  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const body = (await c.req
    .json<{ expiresInDays?: number }>()
    .catch(() => ({}))) as { expiresInDays?: number };

  const share = await createFileShare(c.env.DB, {
    firebaseUid: user.uid,
    fileId,
    expiresInDays: body.expiresInDays,
  });

  if (!share) {
    return c.json(
      { error: 'not_found', message: 'Ficheiro não encontrado ou inactivo.' },
      404,
    );
  }

  const origin = new URL(c.req.url).origin;
  const shareUrl = `${origin}/public/share/${share.token}`;

  return c.json({
    share,
    shareUrl,
    expiresInDays: body.expiresInDays ?? 7,
  });
});

/** Renomear ficheiro (metadado D1; objecto R2 mantem chave original). */
filesRoutes.patch('/:fileId', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const body = await c.req.json<{ name?: string }>();
  const name = body.name?.trim();

  if (!name) {
    return c.json({ error: 'invalid_request', message: 'Nome em falta.' }, 400);
  }

  const safeName = sanitizeFileName(name);
  if (!safeName) {
    return c.json({ error: 'invalid_request', message: 'Nome invalido.' }, 400);
  }

  try {
    const file = await renameFile(c.env.DB, {
      fileId,
      firebaseUid: user.uid,
      newName: safeName,
    });

    if (!file) {
      return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado.' }, 404);
    }

    return c.json({ file });
  } catch (err) {
    if (err instanceof Error && err.message === 'DUPLICATE_NAME') {
      return c.json(
        {
          error: 'duplicate_name',
          message: 'Ja existe um ficheiro com este nome.',
        },
        409,
      );
    }
    throw err;
  }
});

/** Apagar ficheiro (soft delete — mantem R2 para restauracao na lixeira). */
filesRoutes.delete('/:fileId', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');

  const row = await softDeleteFile(c.env.DB, fileId, user.uid);
  if (!row) {
    return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado.' }, 404);
  }

  return c.json({
    ok: true,
    fileId,
    message: 'Ficheiro movido para a lixeira.',
  });
});

/** Restaurar ficheiro da lixeira. */
filesRoutes.post('/:fileId/restore', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');

  try {
    const file = await restoreFile(c.env.DB, fileId, user.uid, c.env.ENVIRONMENT);
    if (!file) {
      return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado na lixeira.' }, 404);
    }
    return c.json({ ok: true, file });
  } catch (err) {
    if (err instanceof Error && err.message === 'QUOTA_EXCEEDED') {
      return c.json(
        {
          error: 'quota_exceeded',
          message: 'Sem espaco na quota para restaurar este ficheiro.',
        },
        409,
      );
    }
    throw err;
  }
});

/** Apagar definitivamente (remove do R2 e da base de dados). */
filesRoutes.delete('/:fileId/permanent', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');

  const row = await permanentDeleteFile(c.env.DB, fileId, user.uid);
  if (!row) {
    return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado na lixeira.' }, 404);
  }

  await deleteR2Objects(c.env.FILES_BUCKET, [
    row.r2_object_key,
    row.thumb_r2_object_key,
  ]);

  return c.json({
    ok: true,
    fileId,
    message: 'Ficheiro apagado definitivamente.',
  });
});

/** URL pre-assinada GET temporaria para miniatura. */
filesRoutes.get('/:fileId/thumbnail', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const row = await getFileById(c.env.DB, fileId, user.uid);

  if (!row || row.status !== 'active' || !row.thumb_r2_object_key) {
    return c.json(
      { error: 'not_found', message: 'Miniatura nao disponivel.' },
      404,
    );
  }

  if (!canPresignR2(c.env)) {
    const origin = new URL(c.req.url).origin;
    return c.json({
      thumbnailUrl: `${origin}/files/thumbnail/direct/${fileId}`,
      expiresAt: null,
      localDevThumbnail: true,
    });
  }

  const signed = await presignGet(c.env, row.thumb_r2_object_key);
  return c.json({
    fileId,
    thumbnailUrl: signed.url,
    expiresAt: signed.expiresAt,
    expiresInSeconds: signed.expiresInSeconds,
    localDevThumbnail: false,
  });
});

/** Miniatura directa via Worker (dev local). */
filesRoutes.get('/thumbnail/direct/:fileId', async (c) => {
  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const row = await getFileById(c.env.DB, fileId, user.uid);

  if (!row || row.status !== 'active' || !row.thumb_r2_object_key) {
    return c.json({ error: 'not_found', message: 'Miniatura nao disponivel.' }, 404);
  }

  const object = await c.env.FILES_BUCKET.get(row.thumb_r2_object_key);
  if (!object) {
    return c.json({ error: 'not_found', message: 'Objecto ausente no R2.' }, 404);
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('Content-Type', 'image/jpeg');
  headers.set('Cache-Control', 'private, max-age=3600');

  return new Response(object.body, { headers });
});

/** URL pre-assinada GET temporaria para download. */
filesRoutes.get('/:fileId/download', async (c) => {
  const blocked = await enforceSubscriptionAccess(c, 'download');
  if (blocked) return blocked;

  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const row = await getFileById(c.env.DB, fileId, user.uid);

  if (!row || row.status !== 'active') {
    return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado.' }, 404);
  }

  if (!row.r2_object_key) {
    return c.json({ error: 'server_error', message: 'Chave R2 em falta.' }, 500);
  }

  if (!canPresignR2(c.env)) {
    const origin = new URL(c.req.url).origin;
    return c.json({
      downloadUrl: `${origin}/files/download/direct/${fileId}`,
      expiresAt: null,
      localDevDownload: true,
      instructions:
        'Modo local: GET downloadUrl com Authorization Bearer (configure R2 API tokens para URLs pre-assinadas).',
    });
  }

  const signed = await presignGet(c.env, row.r2_object_key);
  await logDownload(c.env.DB, user.uid, fileId);

  return c.json({
    fileId,
    name: row.name,
    sizeBytes: row.size_bytes,
    mimeType: row.mime_type,
    downloadUrl: signed.url,
    expiresAt: signed.expiresAt,
    expiresInSeconds: signed.expiresInSeconds,
    localDevDownload: false,
  });
});

/** Download directo via Worker (dev local). */
filesRoutes.get('/download/direct/:fileId', async (c) => {
  const blocked = await enforceSubscriptionAccess(c, 'download');
  if (blocked) return blocked;

  const user = c.get('user');
  const fileId = c.req.param('fileId');
  const row = await getFileById(c.env.DB, fileId, user.uid);

  if (!row || row.status !== 'active' || !row.r2_object_key) {
    return c.json({ error: 'not_found', message: 'Ficheiro nao encontrado.' }, 404);
  }

  const object = await c.env.FILES_BUCKET.get(row.r2_object_key);
  if (!object) {
    return c.json({ error: 'not_found', message: 'Objecto ausente no R2.' }, 404);
  }

  await logDownload(c.env.DB, user.uid, fileId);

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('Content-Disposition', `attachment; filename="${row.name}"`);

  return new Response(object.body, { headers });
});
