#!/bin/bash
# Instala/atualiza KiamiCloud API no ZimaBlade (Docker + CasaOS).
set -euo pipefail
REMOTE_ROOT="/home/casaos/kiamicloud"
ARCHIVE_URL="http://192.168.100.107:8765/kiamicloud-blade.tar.gz"
TMP="/tmp/kiamicloud-blade.tar.gz"
CONTAINER="kiamicloud-api"

echo "== KiamiCloud API â€” ZimaBlade =="

if ! command -v docker >/dev/null 2>&1; then
  echo "ERRO: Docker nao encontrado no Blade."
  exit 1
fi

echo ">> Download $ARCHIVE_URL"
curl -fsSL "$ARCHIVE_URL" -o "$TMP"

echo ">> Extrair para $REMOTE_ROOT"
mkdir -p "$REMOTE_ROOT"
tar xzf "$TMP" -C "$REMOTE_ROOT"
rm -f "$TMP"

echo ">> Parar contentores antigos (se existirem)"
docker stop "$CONTAINER" kiamicloud-blade-console 2>/dev/null || true

echo ">> App CasaOS (API :8787 + consola :8790)"
if [[ -f "$REMOTE_ROOT/tools/casaos-kiamicloud-console/install-casaos-app.sh" ]]; then
  bash "$REMOTE_ROOT/tools/casaos-kiamicloud-console/install-casaos-app.sh"
else
  echo "ERRO: install-casaos-app.sh nao encontrado."
  exit 1
fi

echo ">> Aguardar API..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  if curl -fsS -m 3 "http://127.0.0.1:8787/health" >/dev/null 2>&1; then
    echo "OK: GET /health (200)"
    curl -fsS "http://127.0.0.1:8787/health" || true
    echo ""
    curl -fsS -m 5 "http://127.0.0.1:8787/blade-console/" -o /dev/null \
      && echo "OK: /blade-console/ (200)" \
      || echo "AVISO: /blade-console/ ainda nao responde"
    exit 0
  fi
  sleep 4
done

echo "AVISO: API nao respondeu a tempo. Ver logs:"
echo "  docker logs --tail 80 $CONTAINER"
docker logs --tail 40 "$CONTAINER" 2>&1 || true
exit 1
