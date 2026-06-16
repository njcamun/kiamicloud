#!/bin/bash
# Arranque da API KiamiCloud no contentor Docker (CasaOS / ZimaBlade).
set -euo pipefail

cd /app/workers

if [[ ! -d node_modules ]] || [[ ! -f package-lock.json ]]; then
  echo "[kiamicloud-api] npm install (primeira vez ou node_modules em falta)..."
  npm install --silent
fi

echo "[kiamicloud-api] Migrar D1 (chat de suporte e demais)..."
npm run db:migrate:local || echo "[kiamicloud-api] AVISO: migracao D1 falhou — a API tenta criar tabelas em falta."

echo "[kiamicloud-api] wrangler dev em 0.0.0.0:8787 ..."
exec npx wrangler dev --ip 0.0.0.0 --port 8787
