/**
 * Copia objectos R2 beta -> prod via Cloudflare REST API (OAuth wrangler).
 * Uso: node scripts/sync-r2-beta-to-prod-api.mjs [--dry-run]
 */
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';
import { spawnSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const dryRun = process.argv.includes('--dry-run');
const accountId = 'fd1b514b0915d0f6fe4e866ae67ccc86';
const sourceBucket = 'kiamicloud-files-beta';
const targetBucket = 'kiamicloud-files-prod';

function readOAuthToken() {
  const configPath = resolve(
    homedir(),
    'AppData/Roaming/xdg.config/.wrangler/config/default.toml',
  );
  const toml = readFileSync(configPath, 'utf8');
  const match = /oauth_token = "([^"]+)"/.exec(toml);
  if (!match) throw new Error('OAuth wrangler em falta. Execute: npx wrangler login');
  return match[1];
}

async function cfFetch(oauth, path, init = {}) {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${oauth}`,
      ...(init.headers ?? {}),
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${path} -> ${res.status}: ${text.slice(0, 300)}`);
  }
  const ct = res.headers.get('content-type') ?? '';
  if (ct.includes('application/json')) {
    const json = await res.json();
    if (!json.success) {
      throw new Error(`${path} failed: ${JSON.stringify(json.errors ?? json)}`);
    }
    return json;
  }
  return res;
}

async function listAllObjects(oauth, bucket) {
  const objects = [];
  let cursor = null;
  do {
    const qs = new URLSearchParams({ per_page: '1000' });
    if (cursor) qs.set('cursor', cursor);
    const json = await cfFetch(
      oauth,
      `/accounts/${accountId}/r2/buckets/${bucket}/objects?${qs}`,
    );
    objects.push(...json.result);
    cursor = json.result_info?.is_truncated ? json.result_info.cursor : null;
  } while (cursor);
  return objects;
}

async function objectExists(oauth, bucket, key) {
  const encoded = key.split('/').map(encodeURIComponent).join('/');
  const res = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${bucket}/objects/${encoded}`,
    { method: 'HEAD', headers: { Authorization: `Bearer ${oauth}` } },
  );
  return res.ok;
}

async function copyObject(oauth, obj) {
  const key = obj.key;
  const encoded = key.split('/').map(encodeURIComponent).join('/');
  const getUrl = `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${sourceBucket}/objects/${encoded}`;
  const getRes = await fetch(getUrl, {
    headers: { Authorization: `Bearer ${oauth}` },
  });
  if (!getRes.ok) {
    throw new Error(`GET ${key} -> ${getRes.status}`);
  }
  const body = await getRes.arrayBuffer();
  const contentType =
    obj.http_metadata?.contentType ??
    getRes.headers.get('content-type') ??
    'application/octet-stream';

  const putUrl = `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${targetBucket}/objects/${encoded}`;
  const putRes = await fetch(putUrl, {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${oauth}`,
      'Content-Type': contentType,
    },
    body,
  });
  if (!putRes.ok) {
    const err = await putRes.text();
    throw new Error(`PUT ${key} -> ${putRes.status}: ${err.slice(0, 200)}`);
  }
}

function putSecret(name, value, env) {
  const r = spawnSync('npx', ['wrangler', 'secret', 'put', name, '--env', env], {
    cwd: resolve(__dirname, '..'),
    input: `${value}\n`,
    encoding: 'utf8',
    shell: true,
  });
  if (r.status !== 0) {
    throw new Error(`secret ${name}: ${r.stderr || r.stdout}`);
  }
}

async function ensureProductionR2Secrets() {
  const existing = spawnSync(
    'npx',
    ['wrangler', 'secret', 'list', '--env', 'production'],
    { cwd: resolve(__dirname, '..'), encoding: 'utf8', shell: true },
  );
  if ((existing.stdout ?? '').includes('R2_ACCESS_KEY_ID')) {
    console.log('Secrets R2 ja existem em producao.');
    return;
  }
  console.warn(
    'AVISO: R2 secrets ausentes em producao (upload nativo presign). Beta ja tem secrets; producao usa proxy Worker.',
  );
}

async function main() {
  const oauth = readOAuthToken();

  await ensureProductionR2Secrets();

  console.log(`A listar ${sourceBucket}...`);
  const objects = await listAllObjects(oauth, sourceBucket);
  console.log(`Objectos beta: ${objects.length}`);

  if (objects.length === 0) {
    console.log('Nada a copiar.');
    return;
  }

  let copied = 0;
  let skipped = 0;
  for (const obj of objects) {
    if (!dryRun && (await objectExists(oauth, targetBucket, obj.key))) {
      skipped++;
      continue;
    }
    if (dryRun) {
      console.log(`[dry-run] copy ${obj.key} (${obj.size} bytes)`);
      copied++;
      continue;
    }
    process.stdout.write(`copy ${obj.key} ... `);
    await copyObject(oauth, obj);
    copied++;
    console.log('OK');
  }

  console.log(`Concluido: ${copied} copiados, ${skipped} ja existiam em prod.`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
