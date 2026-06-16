# Flutter ↔ API Workers (Fase 7)

## Funcionalidades na app

- Quota e plano reais (`GET /me`)
- Lista de ficheiros (`GET /files`)
- Upload até 50 MB (`file_picker` + API)
- Download (`saveFile`)

## API local

1. Terminal 1 — API:

```powershell
cd workers
npm run db:migrate:local
npm run dev
```

2. Terminal 2 — App:

```powershell
cd apps/cloud/mobile
flutter run --release
```

### Android (telefone físico)

A app mobile usa por defeito:

`http://192.168.100.170:8787`

(constante `KiamiConstants.localApiBaseUrl` / `bladeStaticHost` em `kiamicloud_core`).

O PC e o telemóvel devem estar na **mesma rede Wi‑Fi**. A API deve correr com `ip = "0.0.0.0"` em `workers/wrangler.toml` (já configurado).

Teste no telemóvel (browser): `http://192.168.100.170:8787/health`

Alternativa com USB (sem Wi‑Fi): `adb reverse tcp:8787 tcp:8787` e usar `http://127.0.0.1:8787` via `--dart-define=KIAMI_LOCAL_API_URL=...`.

### Web / Windows

`http://127.0.0.1:8787` por defeito.

## Configuração explícita

Em `main.dart`:

```dart
await kiamiBootstrap(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  apiBaseUrl: 'http://127.0.0.1:8787',
);
```

## Resolução de problemas

| Sintoma | Solução |
|---------|---------|
| `connection abort` / sem ligação | Ver checklist abaixo |
| Erro ao carregar quota | API desligada ou URL errada |
| 401 na API | Token expirado — voltar a login |

### Checklist «connection abort»

1. **API a correr** no PC: `cd workers` → `npm run dev` → `Ready on http://0.0.0.0:8787`
2. **Mesmo Wi‑Fi** (telefone não em dados móveis)
3. **IP correcto**: ZimaBlade em `192.168.100.170` (`KiamiConstants.bladeStaticHost`)
4. **Teste no telemóvel** (Chrome): `http://192.168.100.170:8787/health` → JSON ok
5. **Firewall Windows**: Permitir Node/Wrangler ou porta **8787** (rede privada)
6. **Reiniciar** `npm run dev` após mudar IP ou firewall

Se o IP do Blade mudar, edite `bladeStaticHost` em `packages/kiamicloud_core/lib/src/constants/kiami_constants.dart` e reinstale a app.
