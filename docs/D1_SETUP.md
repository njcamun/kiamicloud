# Cloudflare D1 — KiamiCloud (Fase 5)

## O que foi criado

- Migrações SQL em `database/migrations/`
- Tabelas: `plans`, `users`, `folders`, `files`, `subscriptions`, `file_actions`
- Plano **Free** (15 GB) atribuído automaticamente no primeiro `GET /me`

## Desenvolvimento local

```powershell
cd "D:\Projectos Flutter\Novo\workers"
npm run db:migrate:local
npm run dev
```

## Endpoints novos

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/plans` | Não | Lista planos activos |
| GET | `/me` | Sim | Perfil + quota (lê/grava D1) |
| GET | `/health` | Não | Inclui `"database": "ok"` |

## Testar

```powershell
curl http://127.0.0.1:8787/health
curl http://127.0.0.1:8787/plans
```

Com token Firebase (apos login na app):

```powershell
curl -H "Authorization: Bearer SEU_ID_TOKEN" http://127.0.0.1:8787/me
```

Resposta esperada em `/me`: `plan`, `storageUsedBytes`, `storageAvailableBytes`, `maxFileSizeBytes`.

## Base remota (producao)

1. Criar base na Cloudflare:

```powershell
cd workers
npx wrangler d1 create kiamicloud-db
```

2. Copiar o `database_id` para `workers/wrangler.toml` (substituir o placeholder).

3. Aplicar migrações:

```powershell
npm run db:migrate:remote
```

4. Deploy:

```powershell
npm run deploy
```

## Comandos uteis

| Comando | Efeito |
|---------|--------|
| `npm run db:migrate:local` | Migrações na D1 local |
| `npm run db:migrate:remote` | Migrações na D1 Cloudflare |
| `npm run db:studio:local` | Ver planos na D1 local |

## Esquema R2 (Fase 6)

Os ficheiros binários **nao** vao para o D1. A tabela `files` guarda apenas metadados; o conteudo fica em R2 sob `users/{firebase_uid}/...`.
