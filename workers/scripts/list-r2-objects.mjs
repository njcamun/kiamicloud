import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const __dirname = dirname(fileURLToPath(import.meta.url));
const toml = readFileSync(
  resolve(homedir(), 'AppData/Roaming/xdg.config/.wrangler/config/default.toml'),
  'utf8',
);
const oauth = /oauth_token = "([^"]+)"/.exec(toml)[1];
const accountId = 'fd1b514b0915d0f6fe4e866ae67ccc86';
const bucket = process.argv[2] ?? 'kiamicloud-files-beta';

const url = `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${bucket}/objects?limit=20`;
const res = await fetch(url, { headers: { Authorization: `Bearer ${oauth}` } });
const json = await res.json();
console.log(JSON.stringify(json, null, 2));
