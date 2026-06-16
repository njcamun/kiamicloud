# KiamiCloud — Identidade Visual Oficial

## Nome e slogan

- **Nome:** KiamiCloud
- **Significado:** "Kiami" = "Minha" (kimbundu)
- **Slogan:** *Minha Cloud. Meu mundo. Sem limites.*

## Tipografia

| Uso | Família | Pesos |
|-----|---------|-------|
| Títulos e UI | **Poppins** | 400, 500, 600, 700 |
| Monospace (código, IDs) | JetBrains Mono ou Roboto Mono | 400 |

**Fonte principal:** [Google Fonts — Poppins](https://fonts.google.com/specimen/Poppins)

## Paleta oficial

| Token | Hex | Uso |
|-------|-----|-----|
| `deepBlue` | `#0D1B2A` | Fundos escuros, app bar dark, texto em light |
| `primaryBlue` | `#1565FF` | CTAs, links, estados activos |
| `cloudBlue` | `#00C2FF` | Destaques, gradientes, ícones accent |
| `softWhite` | `#E6F2FF` | Texto em dark mode, superfícies suaves |
| `lightGray` | `#F2F4F7` | Fundos light, cards, divisores |

### Cores semânticas (derivadas)

| Token | Hex | Uso |
|-------|-----|-----|
| `success` | `#10B981` | Operações concluídas |
| `warning` | `#F59E0B` | Quota próxima do limite |
| `error` | `#EF4444` | Erros, acções destrutivas |
| `info` | `#00C2FF` | Informação (reutiliza cloudBlue) |

## Estilo visual

- Moderno, clean, premium, tecnológico, minimalista
- Inspiração: Notion, Dropbox, Linear, Google Drive, iCloud
- Detalhes africanos/angolanos: **subtis** (padrões geométricos leves, não ilustrações pesadas)

## Logo

- Versão principal: wordmark **Kiami** + ícone cloud estilizado
- Ficheiros em `branding/assets/` (SVG ou PNG)
- Após alterar logos: `.\scripts\sync-branding-assets.ps1` (copia para Flutter)
- Margem mínima: altura do ícone em todos os lados

## Dark mode

- Fundo principal: `#0D1B2A`
- Superfícies elevadas: `#1B2838`, `#243447`
- Texto primário: `#E6F2FF`
- Accent: `#1565FF` / `#00C2FF`

## Light mode

- Fundo principal: `#F2F4F7`
- Superfícies: `#FFFFFF`
- Texto primário: `#0D1B2A`
- Accent: `#1565FF`
