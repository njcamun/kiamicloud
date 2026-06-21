/**
 * Copia objectos R2 de kiamicloud-files-beta -> kiamicloud-files-prod.
 * Credenciais: workers/.dev.vars ou variaveis R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY.
 *
 * Uso: node scripts/sync-r2-beta-to-prod.mjs [--dry-run]
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { AwsClient } from 'aws4fetch';

const __dirname = dirname(fileURLToPath(import.meta.url));
const dryRun = process.argv.includes('--dry-run');
const sourceBucket = 'kiamicloud-files-beta';
const targetBucket = 'kiamicloud-files-prod';

function loadDevVars() {
  const path = resolve(__dirname, '../.dev.vars');
  if (!existsSync(path)) return {};
  const out = {};
  for (const line of readFileSync(path, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const i = trimmed.indexOf('=');
    if (i <= 0) continue;
    out[trimmed.slice(0, i).trim()] = trimmed.slice(i + 1).trim();
  }
  return out;
}

function env(name, fileVars) {
  return process.env[name]?.trim() || fileVars[name]?.trim() || '';
}

function decodeXmlEntities(s) {
  return s
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&');
}

function parseListKeys(xml) {
  const keys = [];
  const re = /<Key>([^<]*)<\/Key>/g;
  let m;
  while ((m = re.exec(xml))) {
    keys.push(decodeXmlEntities(m[1]));
  }
  const truncated = /<IsTruncated>true<\/IsTruncated>/.test(xml);
  const tokenMatch = /<NextContinuationToken>([^<]*)<\/NextContinuationToken>/.exec(xml);
  return {
    keys,
    truncated,
    continuationToken: tokenMatch ? decodeXmlEntities(tokenMatch[1]) : null,
  };
}

async function listAllKeys(client, endpoint, bucket) {
  const keys = [];
  let token = null;
  do {
    const qs = new URLSearchParams({ 'list-type': '2', 'max-keys': '1000' });
    if (token) qs.set('continuation-token', token);
    const url = `${endpoint}/${bucket}?${qs}`;
    const res = await client.fetch(url);
    if (!res.ok) {
      throw new Error(`ListObjects failed (${res.status}): ${await res.text()}`);
    }
    const xml = await res.text();
    const page = parseListKeys(xml);
    keys.push(...page.keys);
    token = page.truncated ? page.continuationToken : null;
  } while (token);
  return keys;
}

async function objectUrl(endpoint, bucket, key) {
  const encodedKey = key.split('/').map((p) => encodeURIComponent(p)).join('/');
  return `${endpoint}/${bucket}/${encodedKey}`;
}

async function copyObject(client, endpoint, key) {
  const sourceUrl = await objectUrl(endpoint, sourceBucket, key);
  const getRes = await client.fetch(sourceUrl);
  if (!getRes.ok) {
    throw new Error(`GET ${key} failed (${getRes.status})`);
  }
  const body = await getRes.arrayBuffer();
  const contentType = getRes.headers.get('content-type') ?? 'application/octet-stream';
  const putUrl = await objectUrl(endpoint, targetBucket, key);
  const putRes = await client.fetch(putUrl, {
    method: 'PUT',
    headers: { 'Content-Type': contentType },
    body,
  });
  if (!putRes.ok) {
    throw new Error(`PUT ${key} failed (${putRes.status})`);
  }
}

async function main() {
  const fileVars = loadDevVars();
  const accountId = env('R2_ACCOUNT_ID', fileVars);
  const accessKeyId = env('R2_ACCESS_KEY_ID', fileVars);
  const secretAccessKey = env('R2_SECRET_ACCESS_KEY', fileVars);

  if (!accountId || !accessKeyId || !secretAccessKey) {
    console.error(
      'Credenciais R2 em falta. Preencha workers/.dev.vars (R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY).',
    );
    process.exit(1);
  }

  const client = new AwsClient({ accessKeyId, secretAccessKey, service: 's3' });
  const endpoint = `https://${accountId}.r2.cloudflarestorage.com`;

  console.log(`A listar ${sourceBucket}...`);
  const keys = await listAllKeys(client, endpoint, sourceBucket);
  console.log(`Objectos encontrados: ${keys.length}`);

  if (keys.length === 0) {
    console.log('Nada a copiar.');
    return;
  }

  let copied = 0;
  for (const key of keys) {
    if (dryRun) {
      console.log(`[dry-run] copy ${key}`);
      copied++;
      continue;
    }
    process.stdout.write(`copy ${key} ... `);
    await copyObject(client, endpoint, key);
    copied++;
    console.log('OK');
  }

  console.log(`${dryRun ? 'Simulados' : 'Copiados'}: ${copied} objecto(s).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
