# Sistema de quotas — KiamiCloud (Fase 10)

## Resumo

Cada utilizador tem um plano com `quota_bytes`. O uso actual vem de `storage_used_bytes` na D1. A API calcula estados e bloqueia uploads quando a quota está cheia.

## Estados (`quota.status`)

| Estado | Condição | UI |
|--------|----------|-----|
| `ok` | &lt; 80% | Barra azul |
| `warning` | ≥ 80% | Banner amarelo |
| `critical` | ≥ 95% | Banner laranja |
| `full` | ≥ 100% ou sem bytes livres | Banner vermelho; upload desactivado |

## API

### `GET /me` (Bearer)

Inclui objecto `quota`:

```json
{
  "quota": {
    "status": "warning",
    "usagePercent": 82.5,
    "canUpload": true,
    "message": "A usar mais de 80% do armazenamento..."
  }
}
```

Lógica em `workers/src/lib/quota.ts` (`computeQuotaInfo`).

### Upload

- `POST /files/upload/init` e `PUT .../upload/direct/:id` validam quota no servidor.
- Resposta `403` com mensagem se quota cheia ou ficheiro maior que espaço disponível.

## Flutter

- Modelo: `KiamiQuotaInfo` em `packages/kiamicloud_core/lib/src/api/models/kiami_quota.dart`
- Dashboard: banner + barra colorida + botão upload desactivado quando `canUpload == false`
- Definições: cartão com plano, barra e avisos
- Pré-validação local: tamanho do ficheiro vs `storageAvailableBytes` antes de enviar

## Testar em dev

1. Reiniciar API: `scripts/restart-api-clean.ps1`
2. `GET /me` com token — confirmar campo `quota`
3. Na app: dashboard mostra % e banner ao ultrapassar 80% (pode simular com SQL na D1 local ou uploads até encher)

## Próximo

- Fase 12: upgrade de plano via pagamentos
- Fase 13: admin alterar quotas por utilizador
