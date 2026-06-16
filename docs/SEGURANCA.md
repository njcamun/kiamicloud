# KiamiCloud — Política de Segurança

## Regras obrigatórias

1. **Credenciais** — Nunca commitar `.env`, chaves R2, service accounts ou `firebase_options.dart` com segredos reais.
2. **R2 privado** — Bucket sem acesso público; apenas Workers com binding R2.
3. **URLs temporárias** — Presigned URLs com TTL curto (ex.: 15 min upload, 5 min download).
4. **Validação de utilizador** — Todo endpoint (excepto health) exige JWT Firebase válido.
5. **Validação de quota** — Antes de qualquer upload ou registo de metadado.
6. **Isolamento** — Utilizador A nunca acede prefixo `users/{uid_B}/`.
7. **Logs** — Sem conteúdo de ficheiros nos logs; apenas IDs e acções.

## Variáveis de ambiente

| Variável | Onde | Descrição |
|----------|------|-----------|
| `FIREBASE_PROJECT_ID` | Worker | Project ID para validação JWT |
| `R2_BUCKET_NAME` | Worker | Nome do bucket (binding Wrangler) |
| `API_ALLOWED_ORIGINS` | Worker | CORS restrito em produção |

Ver `.env.example` na raiz e `workers/.dev.vars.example`.

## Fase 11 — implementado

- **Rate limiting** (D1 `rate_limit_buckets`): por IP (global, auth fail, webhook) e por utilizador (API, upload init)
- **Cabeçalhos HTTP**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, HSTS em produção
- **CORS**: `API_ALLOWED_ORIGINS` em produção; localhost / LAN em desenvolvimento
- **Auditoria**: `GET /me/audit` (ficheiros) + tabela `security_events` (auth, rate limit, pagamentos)
- **Logs de auth falhado** com hash de IP (sem IP em claro na D1)

## Checklist pré-produção

- [ ] CORS restrito aos domínios da app (`API_ALLOWED_ORIGINS`)
- [x] Rate limiting no Worker (Fase 11)
- [ ] Rotação de secrets documentada
- [ ] Auditoria de dependências (npm + pub)
- [ ] HTTPS only
