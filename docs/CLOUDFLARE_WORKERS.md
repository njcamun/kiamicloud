# Cloudflare Workers — KiamiCloud API (Fase 4)

## Desenvolvimento local

```powershell
cd workers
npm install
npm run dev
```

- URL: http://127.0.0.1:8787
- Firebase Project ID: `kiamicloud` (var `FIREBASE_PROJECT_ID` em `wrangler.toml`)

## CORS

Permitido para Flutter Web:

- `http://localhost` e `http://localhost:*`
- `http://127.0.0.1` e `http://127.0.0.1:*`

## Endpoints

| Método | Rota | Auth |
|--------|------|------|
| GET | `/health` | Não |
| GET | `/me` | `Authorization: Bearer <Firebase idToken>` |

## Testar `/me`

1. Inicie sessão na app Flutter (Web ou desktop).
2. Obtenha o `idToken` (debug: `FirebaseAuth.instance.currentUser?.getIdToken()`).
3.:

```powershell
curl -H "Authorization: Bearer SEU_TOKEN" http://127.0.0.1:8787/me
```

Resposta esperada: `uid`, `email`, `email_verified`, etc.

## Segurança

- JWT validado via JWKS Google (`securetoken@system.gserviceaccount.com`).
- Sem service account no Worker.
- Não commitar `.dev.vars` (ver `workers/.dev.vars.example`).

## Fase 5 — D1

Migrações: `database/migrations/`. Ver `docs/D1_SETUP.md`.

| Método | Rota | Auth |
|--------|------|------|
| GET | `/plans` | Não |
| GET | `/me` | Bearer (perfil + quota na D1) |

## Fase 6 — R2

Ver `docs/R2_SETUP.md` — upload/download de ficheiros.

## Próximo (Fase 7)

- Integrar upload na app Flutter
