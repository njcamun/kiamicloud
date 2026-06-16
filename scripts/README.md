# Scripts — KiamiCloud

## Sincronizar logos (branding → Flutter)

Coloque ficheiros em `branding\assets\` e escolha **um** método:

| Método | Comando |
|--------|---------|
| **CMD (recomendado)** | Duplo-clique em `scripts\sync-branding-assets.cmd` |
| PowerShell | Na raiz: `.\scripts\sync-branding-assets.ps1` |
| Dart (sem PowerShell) | Na raiz: `dart run tool/sync_branding.dart` |
| Melos | Na raiz: `melos run sync-branding` |

### Nomes de ficheiros reconhecidos

| Ficheiro | Uso |
|----------|-----|
| `logo_claro.png` | Splash Flutter, logos tema claro |
| `logo_dark.png` | Sidebar / logos tema escuro |
| `Logo_barra_claro.png` / `Logo_barra_dark.png` | Ecrã de login |
| `icone.png` | **Ícone da app** (launcher Android, Web, Windows) |
| `icon_claro.png` / `icon_dark.png` | Zona de upload |
| `img.png`, `video.png`, … | Cards do dashboard → `assets/categories/` |
| `*.svg` | Fallback se PNG não existir |

**Não coloque** em `branding/assets/`: `logo.png`, `Logo_barra.png`, `icon.png` nem PNG de categorias duplicados (o sync ignora-os).

### Problemas comuns

- **Erro PowerShell / ExecutionPolicy:** use o ficheiro `.cmd` ou `dart run tool/sync_branding.dart`
- **Pasta vazia:** confirme que os logos estão em `branding\assets\` (não só na raiz)
- **Logos não aparecem na app:** execute sync e depois `flutter pub get` em `packages\kiamicloud_core`

## Outros

| Script | Descrição |
|--------|-----------|
| `start-api-local.bat` | Inicia `wrangler dev` na porta 8787 |
| `start-api-gui.bat` | Consola web (ligar/parar/reiniciar API) em http://127.0.0.1:3847 |
| `launch-api-manager.cmd` | Atalho para `start-api-gui.bat` |
| `restart-api-clean.ps1` | Para workerd e liberta porta 8787 |
| `allow-kiamicloud-api-firewall.ps1` | Regra firewall porta 8787 (Admin) |
| `setup-android-api-usb.ps1` | `adb reverse` para API no USB |
| `verify-structure.ps1` | Valida pastas obrigatórias do monorepo |

### API local — atalhos na raiz

| Ficheiro | Uso |
|----------|-----|
| `Iniciar-API-Local.bat` | Só a API (`npm run dev`) |
| `Iniciar-API-GUI.bat` | GUI de gestão (recomendado) |
