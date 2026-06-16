# KiamiCloud — Guia Flutter (Fase 2)

## Estrutura

```
packages/kiamicloud_core/   # Design system, rotas, ecrãs partilhados
apps/cloud/mobile/          # Android
apps/cloud/web/             # Web
apps/cloud/desktop/         # Windows
```

## Pré-requisitos

- Flutter SDK ≥ 3.24
- Melos (opcional): `dart pub global activate melos`

## Sincronizar logos

Coloque os ficheiros em `branding/assets/` e execute **um** dos métodos:

```powershell
# Opcao 1 — duplo-clique ou CMD
.\scripts\sync-branding-assets.cmd

# Opcao 2 — Dart (se PowerShell falhar)
dart run tool/sync_branding.dart

# Opcao 3 — Melos
melos run sync-branding
```

| Ficheiro | Uso |
|----------|-----|
| `logo.png` ou `Logo_barra.png` | Tema claro |
| `logo_dark.png` | Tema escuro |
| `icone.png` | **Ícone da app** (Android, Web, Windows) |
| `*.svg` | Fallback |

Ver também `scripts/README.md`.

## Executar

Antes de abrir qualquer app, inicie a API:

```powershell
# Recomendado — GUI (ligar / parar / reiniciar / testes)
# Duplo-clique: Iniciar-API-GUI.bat  (na raiz do projecto)

# Ou só wrangler dev:
# Duplo-clique: Iniciar-API-Local.bat

cd workers
npm run dev
```

```powershell
# Mobile (Android) — API via IP LAN (ver `KiamiConstants.bladeStaticHost`)
cd apps/cloud/mobile
flutter pub get
flutter run

# Web — API beta Cloudflare (por defeito, igual ao mobile)
cd apps/cloud/web
flutter pub get
flutter run -d chrome

# Desktop (Windows) — API beta Cloudflare (por defeito)
cd apps/cloud/desktop
flutter pub get
flutter run -d windows
```

Após alterações em `kiamicloud_core`, corra `flutter pub get` em **web** e **desktop** (ou `melos bootstrap`).

### Funcionalidades Web e Desktop (pós-fase 15+)

| Funcionalidade | Web | Desktop |
|----------------|-----|---------|
| Pesquisa global (ícone ou **Ctrl+K** / **Cmd+K**) | Sim | Sim |
| Arrastar ficheiros para upload | Sim | Sim |
| Fila de uploads com retry | Sim | Sim |
| Lixeira (Definições → Lixeira) | Sim | Sim |
| Modo offline (cache + banner) | Sim | Sim |
| Sidebar + categorias | Sidebar | Sidebar |
| Pré-visualização de imagens | Sim | Sim |
| Planos e pagamentos (plano actual, upgrade/downgrade) | Sim | Sim |
| Apagar conta (confirmação `APAGAR`) | Sim | Sim |
| Partilhas por link, miniaturas, exportar dados | Sim | Sim |

> **Nota:** Mobile, Web e Desktop usam o mesmo `KiamiApp` em `packages/kiamicloud_core`. Alterações na UI ou na API client aplicam-se às três apps após `melos run get` (ou `flutter pub get` em cada pasta).

### API — Cloudflare (apps)

| App | Por defeito (`main.dart`) |
|-----|---------------------------|
| Mobile, Web, Desktop | **Beta Cloudflare** — `https://kiamicloud-api-beta.kiamicloud.workers.dev` |

As apps **não** alternam para o servidor local. Monitorização de actividade e eventos de segurança dos utilizadores na LAN está na **Consola Blade** (`/blade-console/` no ZimaBlade) — ver [BLADE_CONSOLE.md](./BLADE_CONSOLE.md).

**Desenvolvimento local da API:** `npm run dev` em `workers/` e, se necessário, `--dart-define=KIAMI_API_BASE_URL=...`

**Produção:**

```dart
environment: KiamiAppEnvironment.production,
apiBaseUrl: 'https://kiamicloud-api.workers.dev',
```

## Melos (monorepo)

```powershell
cd "d:\Projectos Flutter\Novo"
melos bootstrap
melos run analyze
```

## Ecrãs (Fase 2 — placeholders)

1. **Splash** — logo + slogan → auth
2. **Auth** — formulário UI (Firebase Fase 3)
3. **Dashboard** — quota + estado vazio
4. **Definições** — tema claro/escuro/sistema

## Arquitectura do pacote core

```
lib/src/
├── app/           # KiamiApp, KiamiThemeScope
├── theme/         # Cores, tipografia, ThemeData
├── widgets/       # KiamiLogo, KiamiButton
├── routing/       # go_router
├── features/      # splash, auth, dashboard, shell, settings
└── constants/     # strings PT, limites MVP
```
