# KiamiCloud — Roadmap de Desenvolvimento

## Fases concluídas (MVP)

| # | Fase | Estado |
|---|------|--------|
| 1 | Fundação e Branding | Concluída |
| 2 | Arquitetura Flutter | Concluída |
| 3 | Firebase Authentication | Concluída |
| 4 | Cloudflare Workers | Concluída |
| 5 | Cloudflare D1 | Concluída |
| 6 | Integração Cloudflare R2 | Concluída |
| 7 | Sistema Upload/Download | Concluída |
| 8 | Dashboard | Concluída |
| 9 | Gestão de ficheiros | Concluída |
| 10 | Sistema de quotas | Concluída |
| 11 | Segurança avançada | Concluída |
| 12 | Pagamentos | Concluída (mock MVP) |
| 13 | Painel administrativo | Concluída |
| 14 | Beta | Concluída |

## Fases pós-MVP (em implementação)

Detalhe completo, checklists e calendário: **[ROADMAP_POS_MVP.md](./ROADMAP_POS_MVP.md)**

| # | Fase | Duração | Estado |
|---|------|---------|--------|
| 15 | Polimento UX e base técnica | 1–2 dias | Concluída |
| 16 | Upload fiável (fila e retry) | 3–5 dias | MVP (sem chunked API) |
| 17 | Confiança nos ficheiros (lixeira, histórico, lote) | 2–3 dias | Concluída |
| 18 | Pré-visualização e miniaturas | 2–3 dias | Parcial |
| 19 | Conta, privacidade e definições | 2 dias | Pendente |
| 20 | Billing produção e quota proactiva | 3–5 dias | Pendente |
| 21 | Partilha por link | 3–4 dias | Pendente |
| 22 | Offline e cache local | 2–3 dias | MVP (sem fila offline) |
| 23 | Pastas e organização | 3–4 dias | Pendente |
| 24 | Qualidade, i18n e escala | contínuo | Pendente |
| 25 | Funcionalidades avançadas | futuro | Backlog |

**Começar por:** Fase 15 → 16 → 17 (robustez e confiança antes de partilha e pastas).

## Melhorias recentes (pré-fase 15)

- [x] Categorias com ecrã dedicado, vistas lista/mosaico/detalhes, ordenação
- [x] Upload seguro (validação de tamanho/quota antes de ler ficheiro)
- [x] Diálogos de limite de quota com CTA para planos
- [x] Ajuda na barra de armazenamento
- [x] Tema escuro, scroll e branding (login, splash, ícones)

## Marcos do MVP

- [x] Login/registo Firebase + Google
- [x] API Workers com validação JWT
- [x] Schema D1 completo
- [x] Upload/download manual até 50 MB
- [x] Dashboard com quota visual (alertas 80%/95%, bloqueio upload)
- [x] Gestão de ficheiros (listar, apagar, renomear)
- [x] Plano Free (15 GB) activo
- [x] Programa beta (feedback, deploy, diagnósticos)

## Backlog longo prazo (Fase 25)

- Upload em background (mobile)
- Sincronização automática de pastas
- Compressão inteligente
- Suporte multilingue (parcialmente na Fase 24)
- App iOS nativa
- Partilha em equipa / espaços partilhados
