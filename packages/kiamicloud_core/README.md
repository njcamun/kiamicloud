# kiamicloud_core

Pacote Flutter partilhado da KiamiCloud.

## Conteúdo

- Design system (cores, tipografia Poppins, temas light/dark)
- Widgets: `KiamiLogo`, `KiamiButton`
- Rotas (`go_router`): splash → auth → dashboard / settings
- Shell responsivo (bottom nav / navigation rail)
- Textos em português (MVP)

## Assets

Logos em `assets/branding/`. Sincronizar a partir da raiz do monorepo:

```powershell
.\scripts\sync-branding-assets.ps1
```

## Uso nas apps

```dart
import 'package:kiamicloud_core/kiamicloud_core.dart';

void main() {
  runApp(const KiamiApp());
}
```
