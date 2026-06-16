# KiamiCloud — app CasaOS (ZimaBlade)

Arranca a **API local** (porta 8787) e a **consola admin** (porta 8790) a partir do CasaOS.

## Problema «Offline» no CasaOS

Causas comuns (corrigidas na versão actual do compose):

1. **Rede `external: true`** — CasaOS não criava a rede → contentores não arrancavam.
2. **`depends_on: service_healthy`** — nginx só iniciava se a API passasse healthcheck; durante `npm install` (1–3 min) a app ficava sempre offline.
3. **Healthcheck Docker** — falhas marcavam o contentor como unhealthy.

**Solução:** rede interna gerida pelo compose, nginx arranca logo, sem healthcheck na API.

Se a app aparecer offline nos **primeiros 1–3 minutos** após Start, é normal (npm install). Aguarde e clique **Open** ou teste `http://<blade-ip>:8787/health/ping`.

## Instalar / actualizar

```powershell
# A partir do PC
$env:BLADE_SSH_PASSWORD='sua_password'; .\scripts\deploy-blade.ps1 -SkipEmbed
```

Ou no Blade (SSH):

```bash
bash /home/casaos/kiamicloud/tools/casaos-kiamicloud-console/install-casaos-app.sh
```

## URLs

| Destino | URL |
|---------|-----|
| API (apps Flutter) | `http://192.168.100.170:8787` |
| Consola (CasaOS) | `http://192.168.100.170:8790/blade-console/` |
| Health | `http://192.168.100.170:8787/health/ping` |

Login consola: **admin** / **admin**

## Diagnóstico no Blade

```bash
docker ps -a --filter name=kiamicloud
docker logs --tail 80 kiamicloud-api
curl -s http://127.0.0.1:8787/health/ping
```

## Ficheiros

| Ficheiro | Função |
|----------|--------|
| `docker-compose.yml` | Stack CasaOS (API + nginx) |
| `api-entrypoint.sh` | Arranque wrangler no contentor |
| `nginx.conf` | Proxy :8790 → API |
| `install-casaos-app.sh` | Instalação / actualização |
