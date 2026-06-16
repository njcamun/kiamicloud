# KiamiCloud — Convenções de Armazenamento R2

## Bucket

- **Nome sugerido:** `kiamicloud-files-prod` (e `-staging` para testes)
- **Acesso:** Privado, sem domínio público
- **Binding Wrangler:** `FILES_BUCKET`

## Estrutura de chaves (object keys)

```
users/{firebase_uid}/{file_id}/{sanitized_filename}
```

| Segmento | Regra |
|----------|-------|
| `firebase_uid` | UID Firebase Auth, sem caracteres especiais |
| `file_id` | UUID v4 gerado no Worker |
| `sanitized_filename` | Nome original normalizado (sem `..`, sem `/`) |

## Exemplo

```
users/abc123xyz/def456-uuid-7890/relatorio_2026.pdf
```

## URLs temporárias

- **Upload (PUT):** TTL 15 minutos, content-type validado
- **Download (GET):** TTL 5 minutos
- Geradas exclusivamente pelo Worker após autenticação

## Limites MVP

- Tamanho máximo por ficheiro: **52_428_800 bytes (50 MB)**
- Tipos MIME: todos permitidos inicialmente (validação futura opcional)

## Não fazer

- Bucket público
- Credenciais R2 no cliente Flutter
- Bucket separado por utilizador (desnecessário no MVP)
