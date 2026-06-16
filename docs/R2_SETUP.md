# Cloudflare R2 — KiamiCloud (Fase 6)

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/files` | Lista ficheiros activos |
| POST | `/files/upload/init` | Inicia upload (quota + URL) |
| PUT | `/files/upload/direct/:fileId` | Upload local/dev (com Bearer) |
| POST | `/files/upload/complete` | Confirma após PUT na URL R2 |
| GET | `/files/:fileId/download` | URL de download temporária |
| GET | `/files/download/direct/:fileId` | Download local/dev (com Bearer) |

Todos exigem `Authorization: Bearer <Firebase idToken>` excepto o PUT para URL **pre-assinada** R2 (sem Bearer).

## Modo local (sem API tokens R2)

Se **não** tiveres `R2_ACCESS_KEY_ID` em `.dev.vars`:

1. `POST /files/upload/init` → `localDevUpload: true` e `uploadUrl` aponta para o Worker
2. `PUT` para essa URL **com** Bearer + corpo do ficheiro → activa automaticamente
3. `GET /files/:id/download` → `downloadUrl` directo com Bearer

O R2 é simulado em `.wrangler/state` via binding `FILES_BUCKET`.

## Modo producao (URLs pre-assinadas)

1. Criar bucket:

```powershell
cd workers
npx wrangler r2 bucket create kiamicloud-files-prod
```

2. Criar **R2 API Token** (Cloudflare Dashboard → R2 → Manage R2 API Tokens) com leitura/escrita no bucket.

3. Copiar `workers/.dev.vars.example` → `workers/.dev.vars`:

```env
R2_ACCOUNT_ID=seu_account_id
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
```

O Account ID está no dashboard Cloudflare (URL ou Overview).

4. Reiniciar `npm run dev`.

5. Fluxo:

   - `POST /files/upload/init` com JSON:

```json
{
  "name": "teste.pdf",
  "sizeBytes": 1024,
  "mimeType": "application/pdf"
}
```

   - `PUT` do ficheiro para `uploadUrl` (**sem** Authorization)
   - `POST /files/upload/complete` com `{ "fileId": "..." }`

6. Download: `GET /files/{fileId}/download` → `downloadUrl` (GET sem Bearer, expira ~15 min)

## Teste rapido (PowerShell, modo local)

```powershell
$token = "SEU_ID_TOKEN"
$base = "http://127.0.0.1:8787"

# 1. Iniciar
$init = Invoke-RestMethod -Uri "$base/files/upload/init" -Method POST -Headers @{
  Authorization = "Bearer $token"
  "Content-Type" = "application/json"
} -Body '{"name":"hello.txt","sizeBytes":11,"mimeType":"text/plain"}'

# 2. Upload (modo local)
$bytes = [System.Text.Encoding]::UTF8.GetBytes("Ola KiamiCloud")
Invoke-RestMethod -Uri $init.uploadUrl -Method PUT -Headers @{
  Authorization = "Bearer $token"
  "Content-Type" = "text/plain"
} -Body $bytes

# Se localDevUpload foi true, o PUT ja activou — saltar complete.
# Se presigned, apos PUT ao R2:
# Invoke-RestMethod -Uri "$base/files/upload/complete" -Method POST -Headers @{ Authorization = "Bearer $token"; "Content-Type"="application/json" } -Body (@{ fileId = $init.fileId } | ConvertTo-Json)

# 3. Listar
Invoke-RestMethod -Uri "$base/files" -Headers @{ Authorization = "Bearer $token" }
```

## Limites MVP

- 50 MB por ficheiro (`maxFileSizeBytes` em `/me`)
- Quota por plano (Free 15 GB)
- URLs pre-assinadas: 15 min (configurável em `R2_PRESIGN_EXPIRES_SECONDS`)

## Segurança

- Nunca commitar `.dev.vars`
- Bucket **privado** — sem acesso público
- Propriedade validada por `firebase_uid` em cada pedido
