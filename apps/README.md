# Apps Flutter — KiamiCloud

Monorepo: **`packages/kiamicloud_core`** + apps em `apps/cloud/`.

```
apps/
└── cloud/          # KiamiCloud (API Cloudflare ou CasaOS via Definições)
    ├── mobile/     # Android
    ├── web/
    └── desktop/    # Windows
```

| Plataforma | Pasta | Pacote Melos |
|------------|-------|--------------|
| Mobile | `cloud/mobile` | `kiamicloud_mobile` |
| Web | `cloud/web` | `kiamicloud_web` |
| Desktop | `cloud/desktop` | `kiamicloud_desktop` |

Após alterar `packages/kiamicloud_core/`:

```powershell
cd "d:\Projectos Flutter\Novo"
melos run get
```

## Executar

| Plataforma | Comando |
|------------|---------|
| Mobile | `cd apps/cloud/mobile && flutter run` |
| Web | `cd apps/cloud/web && flutter run -d chrome` |
| Desktop | `cd apps/cloud/desktop && flutter run -d windows` |

Beta: `.\scripts\run-flutter-beta.cmd`

Para API no ZimaBlade (LAN): **Definições → Mudar de servidor** (requer permissão de admin).

Guia completo: [docs/FLUTTER.md](../docs/FLUTTER.md)