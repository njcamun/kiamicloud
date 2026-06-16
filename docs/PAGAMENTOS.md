# Pagamentos e planos — KiamiCloud (Fase 12)

## Estado actual (MVP mock)

O fluxo de pagamento está implementado com **provider `mock`** para desenvolvimento e testes. A integração com gateway real (Multicaixa Express, Stripe, etc.) fica para produção.

## Fluxo

1. Utilizador abre **Definições → Planos e pagamentos**
2. Escolhe plano (Start, Plus, Premium, Pro, Ultra)
3. `POST /billing/checkout` → referência `KIA-YYYYMMDD-XXXXXXXX` e valor em Kz
4. Confirmação:
   - **Dev:** `POST /billing/checkout/:id/simulate-pay` (com Bearer) ou webhook
   - **Produção:** `POST /billing/webhook` com segredo

## API

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/billing/status` | Bearer | Plano actual, quota, subscrição, checkouts pendentes |
| POST | `/billing/checkout` | Bearer | Cria checkout `{ "planCode": "plus" }` |
| GET | `/billing/checkout/:id` | Bearer | Detalhe do checkout |
| GET | `/billing/checkouts` | Bearer | Histórico |
| POST | `/billing/checkout/:id/simulate-pay` | Bearer | Só em `ENVIRONMENT != production` |
| POST | `/billing/webhook` | `X-Kiami-Webhook-Secret` | Confirma pagamento |

### Webhook (exemplo curl)

```bash
curl -X POST http://127.0.0.1:8787/billing/webhook \
  -H "Content-Type: application/json" \
  -H "X-Kiami-Webhook-Secret: dev-kiami-webhook-change-me" \
  -d "{\"reference\": \"KIA-20260516-AB12CD34\"}"
```

## Configuração

Em `workers/.dev.vars` (copiar de `.dev.vars.example`):

```
PAYMENT_WEBHOOK_SECRET=dev-kiami-webhook-change-me
```

Em produção:

```bash
cd workers
npx wrangler secret put PAYMENT_WEBHOOK_SECRET
```

## Base de dados

- `payment_checkouts` — pedidos de pagamento
- `subscriptions` — subscrição activa após pagamento
- `users.plan_code` — actualizado ao confirmar

## Regras

- Não é possível fazer checkout do plano `free`
- Downgrade bloqueado se `storage_used_bytes` > quota do novo plano
- Checkout expira em 24 h (estado `expired`)

## Próximo passo

Integrar gateway de pagamento angolano ou internacional; manter o mesmo webhook com validação de assinatura do provider.
