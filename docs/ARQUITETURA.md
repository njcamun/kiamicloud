# KiamiCloud — Arquitetura Oficial

## Visão geral

A KiamiCloud segue uma arquitetura **serverless edge-first**, optimizada para latência global, custo previsível no MVP e escalabilidade sem VPS própria.

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENTES (Flutter)                        │
│         Android  │  Web  │  Windows Desktop  │  (iOS futuro) │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTPS + Firebase ID Token
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase Authentication                         │
│   Email/senha │ Google │ Recuperação │ Apenas identidade    │
└───────────────────────────┬─────────────────────────────────┘
                            │ Bearer token (JWT)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Cloudflare Workers (API única)                  │
│  Validação JWT │ Quotas │ Upload/Download │ Regras negócio  │
└───────────────┬─────────────────────────┬───────────────────┘
                │                         │
                ▼                         ▼
┌───────────────────────┐   ┌─────────────────────────────────┐
│   Cloudflare D1       │   │   Cloudflare R2 (bucket privado) │
│   Metadados, planos   │   │   users/{uid}/ficheiros/         │
└───────────────────────┘   └─────────────────────────────────┘
```

## Princípios arquitecturais

| Princípio | Decisão |
|-----------|---------|
| **Separação de responsabilidades** | Auth no Firebase; dados e ficheiros na Cloudflare |
| **Zero trust no cliente** | Toda quota e permissão validada no Worker |
| **R2 nunca exposto** | Cliente nunca recebe credenciais R2; apenas URLs pré-assinadas temporárias |
| **D1 sem blobs** | Ficheiros reais apenas no R2 |
| **Modularidade** | Monorepo com apps, workers e schema independentes |

## Fluxo de autenticação

1. Utilizador autentica-se via Firebase Auth no cliente Flutter.
2. Cliente obtém `idToken` (JWT) renovável.
3. Cada pedido à API inclui `Authorization: Bearer <idToken>`.
4. Worker valida o token com as chaves públicas Firebase (JWKS).
5. Worker resolve `firebase_uid` e aplica regras de quota/permissão.

## Fluxo de upload (MVP — manual)

1. Cliente pede `POST /files/upload/init` com nome, tamanho, tipo MIME.
2. Worker valida quota, limite 50 MB e regista metadado pendente no D1.
3. Worker devolve URL pré-assinada PUT (temporária) para R2.
4. Cliente envia bytes directamente para a URL (sem passar pelo Worker no corpo).
5. Cliente confirma `POST /files/upload/complete`.
6. Worker verifica objecto no R2 e activa metadado no D1.

## Fluxo de download (MVP — manual)

1. Cliente pede `GET /files/{id}/download`.
2. Worker valida propriedade do ficheiro.
3. Worker gera URL pré-assinada GET temporária.
4. Cliente descarrega via URL (expira em minutos).

## Estrutura R2 obrigatória

```
{bucket}/
  users/
    {firebase_uid}/
      {file_id}/
        {filename}
```

**Justificação:** prefixo por utilizador permite políticas IAM futuras, listagens eficientes e isolamento lógico sem múltiplos buckets.

## O que NÃO usar no MVP

- Firebase Storage
- Firestore como storage principal
- FastAPI / PostgreSQL / VPS
- Buckets R2 públicos
- Partilha pública de links

## Escalabilidade futura

- Durable Objects para locks de upload concorrente
- Queues para processamento assíncrono (compressão, thumbnails)
- CDN cache apenas para assets estáticos da app
- Pagamentos locais (Fase 12) via webhook isolado
