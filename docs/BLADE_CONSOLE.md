# Consola Blade — monitorização local

Interface web no **ZimaBlade** (`ENVIRONMENT=development`). Login **local** — sem Firebase.

## Credenciais por defeito

| Campo | Valor |
|-------|--------|
| Utilizador | `admin` |
| Password | `admin` |

Alterar em `workers/wrangler.toml` (`BLADE_CONSOLE_USER` / `BLADE_CONSOLE_PASSWORD`).

## App CasaOS (recomendado)

Instala um ícone **「KiamiCloud Consola」** no painel CasaOS:

```bash
cd /home/casaos/kiamicloud/tools/casaos-kiamicloud-console
chmod +x install-casaos-app.sh
bash install-casaos-app.sh
```

Abrir pela app CasaOS ou: `http://192.168.100.170:8790/blade-console/`

Ver [tools/casaos-kiamicloud-console/README.md](../tools/casaos-kiamicloud-console/README.md).

## Acesso directo (sem app)

`http://192.168.100.170:8787/blade-console/`

Se `:8790` der **502 Bad Gateway**, a API pode estar parada ou o proxy nginx não alcança o contentor `kiamicloud-api`. No Blade:

```bash
docker network create kiamicloud-blade-net
docker network connect kiamicloud-blade-net kiamicloud-api
docker start kiamicloud-api
bash /home/casaos/kiamicloud/tools/casaos-kiamicloud-console/install-casaos-app.sh
```

Ou use sempre o acesso directo `:8787` (sem proxy).

## Actualizar código

```bash
curl -fsSL 'http://<IP-DO-SEU-PC>:8765/remote-install.sh' | bash
```

(O deploy inclui workers, database e app CasaOS.)
