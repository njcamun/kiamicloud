#!/bin/bash
# Remove KiamiCloud do ZimaBlade (contentores, ficheiros, app CasaOS).
set -euo pipefail

REMOTE_ROOT="/home/casaos/kiamicloud"
APP_NAME="kiamicloud-blade-console"
APP_DIR="/DATA/AppData/${APP_NAME}"

echo "== KiamiCloud — desinstalacao no ZimaBlade =="

echo ">> Parar e remover contentores Docker (kiamicloud*)"
mapfile -t KIAMI_CONTAINERS < <(docker ps -a --format '{{.Names}}' | grep -i kiamicloud || true)
for c in "${KIAMI_CONTAINERS[@]}"; do
  [[ -z "$c" ]] && continue
  echo "   - $c"
  docker stop "$c" 2>/dev/null || true
  docker rm -f "$c" 2>/dev/null || true
done

for legacy in kiamicloud-api kiamicloud-blade-console; do
  docker stop "$legacy" 2>/dev/null || true
  docker rm -f "$legacy" 2>/dev/null || true
done

if docker compose version >/dev/null 2>&1 && [[ -f "$APP_DIR/docker-compose.yml" ]]; then
  docker compose -f "$APP_DIR/docker-compose.yml" -p "$APP_NAME" down -v 2>/dev/null || true
elif command -v docker-compose >/dev/null 2>&1 && [[ -f "$APP_DIR/docker-compose.yml" ]]; then
  docker-compose -f "$APP_DIR/docker-compose.yml" -p "$APP_NAME" down -v 2>/dev/null || true
fi

for project in kiamicloud-api kiamicloud-blade-console; do
  docker compose -p "$project" down -v 2>/dev/null || true
  docker-compose -p "$project" down -v 2>/dev/null || true
done

if command -v casaos-cli >/dev/null 2>&1; then
  echo ">> Remover app CasaOS (se existir)"
  sudo casaos-cli app-management uninstall "$APP_NAME" --yes 2>/dev/null || true
fi

echo ">> Remover dados CasaOS"
if [[ -d "$APP_DIR" ]]; then
  sudo rm -rf "$APP_DIR"
fi

echo ">> Remover projecto"
if [[ -d "$REMOTE_ROOT" ]]; then
  rm -rf "$REMOTE_ROOT" 2>/dev/null || true
  sudo rm -rf "$REMOTE_ROOT" 2>/dev/null || true
fi

echo ">> Limpar temporarios"
rm -f /tmp/kiamicloud-blade.tar.gz

echo ">> Verificacao"
left_containers="$(docker ps -a --format '{{.Names}}' | grep -i kiamicloud || true)"
left_dirs=""
[[ -d "$REMOTE_ROOT" ]] && left_dirs="$REMOTE_ROOT"
[[ -d "$APP_DIR" ]] && left_dirs="$left_dirs $APP_DIR"

if [[ -n "$left_containers" || -n "$left_dirs" ]]; then
  echo "AVISO — restos encontrados:"
  [[ -n "$left_containers" ]] && echo "  contentores: $left_containers"
  [[ -n "$left_dirs" ]] && echo "  pastas: $left_dirs"
  exit 1
fi

if curl -fsS -m 2 http://127.0.0.1:8787/health >/dev/null 2>&1; then
  echo "AVISO: algo ainda responde em :8787"
else
  echo "OK: porta 8787 livre"
fi

if curl -fsS -m 2 http://127.0.0.1:8790/ >/dev/null 2>&1; then
  echo "AVISO: algo ainda responde em :8790"
else
  echo "OK: porta 8790 livre"
fi

echo ""
echo "KiamiCloud removido do ZimaBlade."
