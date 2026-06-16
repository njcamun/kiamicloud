# Deploy — KiamiCloud (Fase 14)

Guia para publicar API (Workers + D1 + R2) e preparar testes beta.

## Pré-requisitos

- Conta Cloudflare com Workers, D1 e R2 activos
- `npm install` em `workers/`
- Firebase projecto `kiamicloud` configurado
- `flutterfire configure` nas apps

## 1. D1 remoto

```powershell
cd workers
npx wrangler d1 create kiamicloud-db
```

Copie o `database_id` para `wrangler.toml` (secções default, `[env.beta]` e `[env.production]`).

```powershell
npm run db:migrate:remote
# ou por ambiente:
npx wrangler d1 migrations apply kiamicloud-db --remote --env beta
```

## 2. R2

```powershell
npx wrangler r2 bucket create kiamicloud-files-beta
npx wrangler r2 bucket create kiamicloud-files-prod
```

Crie API token R2 (Dashboard → R2 → Manage API Tokens) e configure secrets:

```powershell
npx wrangler secret put R2_ACCOUNT_ID --env beta
npx wrangler secret put R2_ACCESS_KEY_ID --env beta
npx wrangler secret put R2_SECRET_ACCESS_KEY --env beta
```

Repita para `--env production` se necessário.

## 3. Outros secrets

```powershell
npx wrangler secret put PAYMENT_WEBHOOK_SECRET --env beta
```

Variáveis em `wrangler.toml` (não secretas):

- `ADMIN_UIDS` — Firebase UIDs dos administradores
- `API_ALLOWED_ORIGINS` — URLs da app web (ex. `https://app.kiamicloud.com`)

## 4. Deploy Workers

**Beta:**

```powershell
cd workers
npx wrangler deploy --env beta
```

**Produção:**

```powershell
npx wrangler deploy --env production
```

URL típica: `https://kiamicloud-api-beta.<subdominio>.workers.dev`

## 5. Validar deploy

```powershell
cd ..
.\scripts\smoke-test-api.ps1 -BaseUrl "https://SUA-URL.workers.dev"
```

## 6. App Flutter (beta testers)

```powershell
cd apps\cloud\mobile
flutter build apk --dart-define=KIAMI_ENV=beta --dart-define=KIAMI_API_BASE_URL=https://SUA-URL.workers.dev
```

## Ambientes (`wrangler.toml`)

| Ambiente | Comando | `ENVIRONMENT` |
|----------|---------|---------------|
| Local | `npm run dev` | development |
| Beta | `wrangler deploy --env beta` | beta |
| Produção | `wrangler deploy --env production` | production |

## Rollback

```powershell
npx wrangler deployments list --env beta
npx wrangler rollback --env beta
```

## Segurança

- Nunca commitar `.dev.vars` nem tokens R2
- `ADMIN_UIDS` mínimo necessário
- CORS restrito em produção via `API_ALLOWED_ORIGINS`
