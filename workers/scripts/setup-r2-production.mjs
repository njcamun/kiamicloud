/**
 * Cria token R2 via Cloudflare API, configura secrets producao e .dev.vars.
 * Uso: node scripts/setup-r2-production.mjs
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { homedir } from 'node:os';
import { spawnSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const accountId = 'fd1b514b0915d0f6fe4e866ae67ccc86';

function readOAuthToken() {
  const configPath = resolve(
    homedir(),
    'AppData/Roaming/xdg.config/.wrangler/config/default.toml',
  );
  const toml = readFileSync(configPath, 'utf8');
  const match = /oauth_token = "([^"]+)"/.exec(toml);
  if (!match) throw new Error('OAuth token wrangler em falta. Execute: npx wrangler login');
  return match[1];
}

async function cfApi(token, path, init = {}) {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(init.headers ?? {}),
    },
  });
  const json = await res.json();
  if (!json.success) {
    throw new Error(`Cloudflare API ${path}: ${JSON.stringify(json.errors ?? json)}`);
  }
  return json.result;
}

async function createR2Token(oauth) {
  const writeGroupId = 'bf7481a1826f439697cb59a20b22293e'; // Workers R2 Storage Write

  const body = {
    name: `kiamicloud-prod-${new Date().toISOString().slice(0, 10)}`,
    policies: [
      {
        effect: 'allow',
        resources: {
          [`com.cloudflare.api.account.${accountId}`]: {
            'com.cloudflare.edge.r2.bucket.*': '*',
          },
        },
        permission_groups: [{ id: writeGroupId }],
      },
    ],
  };

  const result = await cfApi(oauth, `/accounts/${accountId}/tokens`, {
    method: 'POST',
    body: JSON.stringify(body),
  });

  const accessKeyId = result.id;
  const secretAccessKey = createHash('sha256').update(result.value).digest('hex');
  return { accessKeyId, secretAccessKey };
}

function putSecret(name, value, env) {
  const args = ['wrangler', 'secret', 'put', name, '--env', env];
  const r = spawnSync('npx', args, {
    cwd: resolve(__dirname, '..'),
    input: `${value}\n`,
    encoding: 'utf8',
    shell: true,
  });
  if (r.status !== 0) {
    throw new Error(`secret put ${name} (${env}) falhou: ${r.stderr || r.stdout}`);
  }
}

function updateDevVars(accountId, accessKeyId, secretAccessKey) {
  const devVarsPath = resolve(__dirname, '../.dev.vars');
  const map = new Map();

  if (existsSync(devVarsPath)) {
    for (const line of readFileSync(devVarsPath, 'utf8').split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const i = trimmed.indexOf('=');
      if (i > 0) map.set(trimmed.slice(0, i).trim(), trimmed.slice(i + 1).trim());
    }
  }

  map.set('R2_ACCOUNT_ID', accountId);
  map.set('R2_ACCESS_KEY_ID', accessKeyId);
  map.set('R2_SECRET_ACCESS_KEY', secretAccessKey);

  const lines = [
    '# Local — nao commitar (ver .dev.vars.example)',
    '# R2 gerado por scripts/setup-r2-production.mjs',
    ...[...map.entries()].map(([k, v]) => `${k}=${v}`),
  ];
  writeFileSync(devVarsPath, `${lines.join('\n')}\n`, 'utf8');
}

async function main() {
  console.log('A obter token OAuth wrangler...');
  const oauth = readOAuthToken();

  console.log('A criar token R2 (beta + prod buckets)...');
  const { accessKeyId, secretAccessKey } = await createR2Token(oauth);

  console.log('A configurar secrets producao e beta...');
  for (const env of ['production', 'beta']) {
    putSecret('R2_ACCOUNT_ID', accountId, env);
    putSecret('R2_ACCESS_KEY_ID', accessKeyId, env);
    putSecret('R2_SECRET_ACCESS_KEY', secretAccessKey, env);
  }

  console.log('A actualizar workers/.dev.vars...');
  updateDevVars(accountId, accessKeyId, secretAccessKey);

  console.log('R2 configurado para producao e sync local.');
  console.log(`Access Key ID: ${accessKeyId.slice(0, 8)}...`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
