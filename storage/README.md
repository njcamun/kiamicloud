# Storage (Cloudflare R2)

Ficheiros privados da KiamiCloud — **nunca** públicos.

## Estrutura de chaves

```
kiamicloud-files-prod/
  users/
    {firebase_uid}/
      {file_id}/
        {filename}
```

## Responsabilidade

- Binários apenas no R2
- Metadados e quotas no D1 (`files`, `users`)
- Cliente recebe URLs temporárias (pre-assinadas) ou proxy local em dev

## Configuração

Ver `docs/R2_SETUP.md`.

## Criar bucket (remoto)

```powershell
cd workers
npx wrangler r2 bucket create kiamicloud-files-prod
```
