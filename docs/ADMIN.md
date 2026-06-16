# Painel administrativo — KiamiCloud (Fase 13)

## Acesso

Administradores são definidos pela variável **`ADMIN_UIDS`** (Firebase UIDs separados por vírgula).

```toml
# workers/wrangler.toml
ADMIN_UIDS = "abc123firebaseUid, outroUid"
```

Ou em `workers/.dev.vars` (local):

```
ADMIN_UIDS=SEU_FIREBASE_UID
```

**Como obter o UID:** Firebase Console → Authentication → utilizador, ou na app (sessão activa) via token JWT (campo `sub`).

Reinicie a API após alterar `ADMIN_UIDS`.

## API (`/admin/*`)

Todas as rotas exigem `Authorization: Bearer <Firebase idToken>` e UID na lista de admins.

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/admin/me` | Confirma acesso admin |
| GET | `/admin/stats` | Métricas da plataforma |
| GET | `/admin/users?q=&limit=&offset=` | Lista utilizadores |
| GET | `/admin/users/:uid` | Detalhe |
| PATCH | `/admin/users/:uid` | Alterar `planCode` e/ou `storageUsedBytes` |
| GET | `/admin/security-events` | Eventos de segurança |
| GET | `/admin/checkouts` | Checkouts recentes |

### Exemplo PATCH

```bash
curl -X PATCH http://127.0.0.1:8787/admin/users/UID \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"planCode":"plus","storageUsedBytes":0}'
```

## App Flutter

- **Definições → Painel administrativo** (só visível se o UID estiver em `ADMIN_UIDS`)
- **Definições → Servidor API (admin)** — alternar entre Cloudflare beta e PC local (`npm run dev`); Web, Desktop e Android
- Métricas, pesquisa de utilizadores, edição de plano/uso, eventos de segurança

## Auditoria

Alterações ficam em `admin_actions` (migração `0004_admin_audit.sql`).

## Produção

- Use `wrangler secret` ou vars de ambiente para `ADMIN_UIDS`
- Mantenha a lista curta; prefira custom claims Firebase numa fase futura
