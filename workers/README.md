# KiamiCloud API — Cloudflare Workers (Fase 4)

API edge com validacao JWT Firebase e metadados D1.

## Requisitos

- Node.js 18+
- `wrangler login` (ja feito)

## Desenvolvimento local

```powershell
cd workers
npm install
npm run db:migrate:local
npm run dev
```

API: http://127.0.0.1:8787

## Testar

```powershell
curl http://127.0.0.1:8787/health
curl http://127.0.0.1:8787/
```

Com token Firebase (obtido apos login na app — nao partilhar):

```powershell
curl -H "Authorization: Bearer SEU_ID_TOKEN" http://127.0.0.1:8787/me
```

## Variaveis

| Variavel | Valor |
|----------|-------|
| `FIREBASE_PROJECT_ID` | `kiamicloud` (em wrangler.toml) |

## Endpoints

| Metodo | Rota | Auth |
|--------|------|------|
| GET | `/health` | Nao |
| GET | `/plans` | Nao |
| GET | `/me` | Bearer Firebase JWT |
| GET | `/files` | Bearer |
| POST | `/files/upload/init` | Bearer |
| POST | `/files/upload/complete` | Bearer |

Ver `docs/D1_SETUP.md` (Fase 5) e `docs/R2_SETUP.md` (Fase 6).

## Deploy (futuro)

```powershell
npm run deploy
```
