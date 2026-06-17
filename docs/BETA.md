# Programa Beta — KiamiCloud (Fase 14)

## Versão

- **App:** `0.6.0-beta`
- **API:** `0.6.0-beta` (`GET /health`)

## O que inclui o beta

- Login Firebase + upload/lista/download/rename/delete
- Quotas com alertas 80% / 95%
- Upgrade de planos (pagamento **mock**)
- Painel admin (UIDs em `ADMIN_UIDS`)
- Feedback in-app (`POST /beta/feedback`)
- Faixa laranja **Versão Beta** na app

## Limitações conhecidas

- Pagamentos simulados (sem Multicaixa/Stripe real)
- Máximo **50 MB** por ficheiro
- Sem pastas na UI
- Sem partilha pública de links
- API beta em Cloudflare Workers (URL após deploy)

## Correr a app em modo beta (local → API local)

```powershell
cd apps\cloud\mobile
flutter run --dart-define=KIAMI_ENV=beta --dart-define=KIAMI_API_BASE_URL=http://192.168.100.170:8787
```

Web:

```powershell
cd apps\cloud\web
flutter run -d chrome --dart-define=KIAMI_ENV=beta
```

## Correr contra API beta na Cloudflare

Após `wrangler deploy --env beta`:

```powershell
flutter run --dart-define=KIAMI_ENV=beta --dart-define=KIAMI_API_BASE_URL=https://SEU-WORKER.workers.dev
```

## Enviar feedback

1. App em modo beta → **Definições** → **Enviar feedback beta**
2. Admin vê em **Painel administrativo** → secção Feedback beta

## Checklist do testador

- [ ] Registo / login (email e Google)
- [ ] Upload ficheiro &lt; 50 MB
- [ ] Download e renomear
- [ ] Apagar ficheiro (quota actualiza)
- [ ] Ver quota no dashboard
- [ ] Testar ligação API em Definições
- [ ] Enviar feedback se encontrar problemas

## Próximo

- Deploy produção (`docs/DEPLOY.md`)
- Gateway de pagamento real
