# KiamiCloud — Modelo de Planos

## Tabela oficial (v2)

| Código | Nome | Armazenamento | Transferência / ficheiro | Preço cobrado (Kz/mês) | Tabela (−15% no Plus+) |
|--------|------|---------------|---------------------------|------------------------|-------------------------|
| `basico` | Básico | 20 GB | 15 MB | **0** | — |
| `basico_plus` | Básico+ | 20 GB | 75 MB | **1 500** | 1 500 |
| `plus` | Plus | 40 GB | 150 MB | **2 550** | 3 000 |
| `start` | Start | 80 GB | 150 MB | **5 100** | 6 000 |
| `premium` | Premium | 160 GB | 150 MB | **10 200** | 12 000 |
| `pro` | Pro | 320 GB | 150 MB | **20 400** | 24 000 |
| `ultra` | Ultra | 500 GB | 150 MB | **40 800** | 48 000 |

**Regra de preço:** escada de tabela ×2 desde Básico+ (1 500 → 3 000 → 6 000 …). **A partir do Plus**, o valor cobrado é **tabela − 15%** (`× 0,85`).

Quotas em bytes (GiB): ver `workers/src/config/plans.ts`.

## Regras de negócio

- Novo utilizador recebe automaticamente o plano **Básico** (`basico`).
- `storage_used_bytes` nunca pode exceder `quota_bytes` do plano activo.
- Upload rejeitado se `storage_used + file_size > quota`.
- **Limite por ficheiro** depende do plano (`max_file_size_bytes`).
- A partir do **Plus**, transferência máxima por ficheiro: **150 MB**.

## Migração de utilizadores (legado)

| Plano antigo | Novo plano |
|--------------|------------|
| `free` | `basico` |
| `start` (30 GB) | `basico_plus` |
| `plus` | `plus` |
| `premium` | `start` |
| `pro` | `premium` |
| `ultra` | `pro` |

## Constantes partilhadas

- Workers: `workers/src/config/plans.ts`
- Flutter: preços via API; UI mostra tabela riscada quando há desconto
