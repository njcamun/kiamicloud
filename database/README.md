# Database (Cloudflare D1)

Migrações SQL e esquema de metadados da KiamiCloud.

## Responsabilidade

- Utilizadores e perfis (espelho do Firebase UID)
- Planos e subscrições
- Metadados de ficheiros (sem conteúdo binário)
- Quotas e uso de armazenamento
- Histórico de acções (`file_actions`)

## Ficheiros

| Ficheiro | Conteúdo |
|----------|----------|
| `migrations/0001_initial_schema.sql` | Tabelas iniciais |
| `migrations/0002_seed_plans.sql` | Planos Básico → Ultra (sem `max_file_size_bytes`) |
| `migrations/0003_plans_v2.sql` | Coluna `max_file_size_bytes` + limites + migração utilizadores |
| `migrations/0006_plan_checkouts_legacy.sql` | Migra códigos de plano em `payment_checkouts` |

## Comandos

```powershell
cd workers
npm run db:migrate:local
npm run db:migrate:remote
```

Ver `docs/D1_SETUP.md` para criar a base remota e deploy.

## Tabelas

| Tabela | Uso |
|--------|-----|
| `plans` | Quotas e preços |
| `users` | Perfil por `firebase_uid` |
| `folders` | Pastas (Fase 9) |
| `files` | Metadados + chave R2 (Fase 6–7) |
| `subscriptions` | Pagamentos (Fase 12) |
| `file_actions` | Auditoria |
