#!/bin/bash
# Instala a app CasaOS "KiamiCloud" no ZimaBlade (API + consola).
# Uso: bash install-casaos-app.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="kiamicloud-blade-console"
API_CONTAINER="kiamicloud-api"
CONSOLE_CONTAINER="kiamicloud-blade-console"
COMPOSE_PROJECT="kiamicloud-blade-console"
PROJECT_ROOT="/home/casaos/kiamicloud"
APP_DIR="/DATA/AppData/${APP_NAME}"

echo "== KiamiCloud — CasaOS (API + Consola) =="

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker nao encontrado."
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT/workers" ]]; then
  echo "ERRO: Projecto nao encontrado em $PROJECT_ROOT"
  echo "Corra primeiro o deploy (scripts/deploy-blade.ps1)."
  exit 1
fi

migrate_d1() {
  echo ">> Migrar D1 (local)"
  docker run --rm \
    -v "$PROJECT_ROOT:/app" \
    -w /app/workers \
    node:22-bookworm \
    bash -c "npm install --silent && npm run db:migrate:local"
}

prepare_app_dir() {
  sudo mkdir -p "$APP_DIR"
  sudo cp "$SCRIPT_DIR/nginx.conf" "$APP_DIR/"
  sudo cp "$SCRIPT_DIR/api-entrypoint.sh" "$APP_DIR/"
  sudo sed -i 's/\r$//' "$APP_DIR/api-entrypoint.sh"
  sudo chmod +x "$APP_DIR/api-entrypoint.sh"
  sudo cp "$SCRIPT_DIR/docker-compose.yml" "$APP_DIR/docker-compose.casaos.yml"
  sudo sed "s/\\\$AppID/${APP_NAME}/g" "$SCRIPT_DIR/docker-compose.yml" \
    | sudo tee "$APP_DIR/docker-compose.yml" >/dev/null

  if [[ -f "$SCRIPT_DIR/icon.png" ]]; then
    sudo cp "$SCRIPT_DIR/icon.png" "$APP_DIR/"
  else
    echo ">> Gerar icon.png minimo"
    python3 - <<'PY' | sudo tee "$APP_DIR/icon.png" >/dev/null
import base64, sys
sys.stdout.buffer.write(base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
))
PY
  fi
}

register_casaos() {
  if command -v casaos-cli >/dev/null 2>&1; then
    echo ">> Registar/atualizar no CasaOS"
    sudo casaos-cli app-management uninstall "$APP_NAME" --yes 2>/dev/null || true
    sudo casaos-cli app-management install -f "$APP_DIR/docker-compose.casaos.yml" --yes 2>/dev/null || \
      sudo casaos-cli app-management install "$APP_NAME" --file "$APP_DIR/docker-compose.casaos.yml" 2>/dev/null || true
  fi
}

stop_legacy_stack() {
  echo ">> Parar stack anterior (se existir)"
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$APP_DIR/docker-compose.yml" -p "$COMPOSE_PROJECT" down --remove-orphans 2>/dev/null || true
  fi
  docker rm -f "$CONSOLE_CONTAINER" "$API_CONTAINER" 2>/dev/null || true
  # Rede criada pelo compose antigo (external: true) impede o novo stack bridge.
  docker network rm kiamicloud-blade-net 2>/dev/null || true
}

start_stack() {
  echo ">> Arrancar stack Docker (API :8787 + consola :8790)"
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$APP_DIR/docker-compose.yml" -p "$COMPOSE_PROJECT" up -d --remove-orphans
    return 0
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f "$APP_DIR/docker-compose.yml" -p "$COMPOSE_PROJECT" up -d --remove-orphans
    return 0
  fi
  echo "ERRO: docker compose nao disponivel."
  exit 1
}

wait_for_api() {
  echo ">> Aguardar API (ate 4 min — npm install na 1.ª vez)..."
  for _ in $(seq 1 48); do
    if curl -fsS -m 3 "http://127.0.0.1:8787/health/ping" >/dev/null 2>&1; then
      echo "OK: GET /health/ping (200)"
      return 0
    fi
    sleep 5
  done
  echo "AVISO: API ainda nao responde. Ver logs:"
  echo "  docker logs --tail 80 $API_CONTAINER"
  docker logs --tail 50 "$API_CONTAINER" 2>&1 || true
  return 1
}

migrate_d1
prepare_app_dir
register_casaos
stop_legacy_stack
start_stack
wait_for_api || true

sleep 2
echo ""
docker ps -a --filter "name=kiamicloud" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true
echo ""

if curl -fsS -m 5 -o /dev/null "http://127.0.0.1:8790/blade-console/"; then
  echo "OK — Consola: http://$(hostname -I | awk '{print $1}'):8790/blade-console/"
else
  echo "AVISO: proxy :8790 ainda nao responde (API pode estar a instalar dependencias)."
  echo "Directo: http://$(hostname -I | awk '{print $1}'):8787/blade-console/"
fi
echo "API: http://$(hostname -I | awk '{print $1}'):8787/health/ping"
echo ""
echo "No CasaOS: app «KiamiCloud» — se aparecer offline nos primeiros minutos, aguarde e clique Open."
echo "Reinstalar manualmente: $APP_DIR/docker-compose.casaos.yml"
