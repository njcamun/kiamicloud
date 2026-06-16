# KiamiCloud — Roadmap pós-MVP (Fases 15+)

Plano para implementação progressiva nos dias seguintes. Cada fase tem **objectivo**, **entregáveis**, **áreas do código** e **duração indicativa** (1 dia ≈ 4–6 h de desenvolvimento focado).

**Ordem recomendada:** respeitar dependências; fases 15 e 16 podem sobrepor-se ligeiramente se duas pessoas trabalharem em paralelo.

---

## Visão geral

| Fase | Nome | Duração | Prioridade |
|------|------|---------|------------|
| 15 | Polimento UX e base técnica | 1–2 dias | Concluída |
| 16 | Upload fiável (fila e retry) | 3–5 dias | MVP concluído |
| 17 | Confiança nos ficheiros | 2–3 dias | Concluída |
| 18 | Pré-visualização e miniaturas | 2–3 dias | Concluída |
| 19 | Conta, privacidade e definições | 2 dias | Parcial (falta sessões Firebase) |
| 20 | Billing e quota proactiva | 3–5 dias | Alta |
| 21 | Partilha por link | 3–4 dias | Concluída (MVP) |
| 22 | Offline e cache local | 2–3 dias | Concluída (MVP) |
| 23 | Pastas / organização | 3–4 dias | Baixa |
| 24 | Qualidade, i18n e escala | contínuo | Média |
| 25 | Funcionalidades avançadas | futuro | Baixa |

---

## Fase 15 — Polimento UX e base técnica

**Objectivo:** Melhorias rápidas que aumentam robustez percebida sem mudar o backend.

**Duração:** 1–2 dias

### Entregáveis

- [x] **Preferências locais** — guardar modo de vista (lista/mosaico/detalhes) e ordenação por categoria (`shared_preferences` ou Hive).
- [x] **Pesquisa global** — campo ou atalho (`Ctrl+K` no desktop) que pesquisa todos os ficheiros e navega para a categoria correcta.
- [x] **Serviço de erros** — `KiamiErrorPresenter`: mapeia API/rede/401/quota para mensagens + acções (re-login, ir a Planos).
- [x] **Drag-and-drop** — arrastar ficheiros para `KiamiUploadZone` (web/desktop).
- [x] **Testes unitários** — `sortKiamiFiles`, `readPlatformFileForUpload`, validação de quota.

### Áreas

- `packages/kiamicloud_core/lib/src/features/dashboard/`
- `packages/kiamicloud_core/lib/src/features/files/`
- `packages/kiamicloud_core/lib/src/utils/`
- `packages/kiamicloud_core/test/`

### Critério de conclusão

Utilizador reabre a app e mantém preferências de lista; pesquisa encontra ficheiro em qualquer categoria; erros de rede mostram mensagem clara e repetível.

---

## Fase 16 — Upload fiável (fila e retry)

**Objectivo:** Uploads não dependem de um único ecrã aberto; falhas de rede são recuperáveis.

**Duração:** 3–5 dias  
**Depende de:** Fase 15 (erros unificados ajuda)

### Entregáveis

- [x] **Modelo de fila** — estados: `pendente` → `a_enviar` → `concluído` | `falhou` (com motivo).
- [x] **UI de fila** — lista compacta sob a zona de upload ou bottom sheet; progresso por ficheiro; cancelar/retry.
- [x] **Retry automático** — 1–3 tentativas com backoff para erros transitórios.
- [ ] **API (opcional 16b)** — upload multipart/chunked no Workers + R2 para retomar envios grandes (pode ficar para sub-fase se o prazo apertar).

### Áreas

- Flutter: `dashboard_page.dart`, novo `upload_queue_provider.dart`, widgets de fila
- Workers: `files/upload` (init, complete, abort chunk)
- Docs: actualizar `docs/FLUTTER_API.md`

### Critério de conclusão

Utilizador inicia 3 uploads, minimiza ou muda de ecrã; vê progresso; um falha por rede e consegue “Tentar novamente” sem re-escolher o ficheiro.

### Notas

- **MVP da fase 16:** fila em memória + persistência simples (JSON local) sem chunked API.
- **Completo:** chunked + presigned URLs por parte.

---

## Fase 17 — Confiança nos ficheiros

**Objectivo:** Menos medo de apagar; mais controlo sobre o que aconteceu na conta.

**Duração:** 2–3 dias  
**Depende de:** D1 (schema); pode paralelizar com 16 após schema definido

### Entregáveis

- [x] **Lixeira** — soft delete sem apagar R2; ecrã `/trash`; restaurar; apagar definitivo.
- [x] **Histórico de actividade** — já em Definições via `/me/audit`.
- [x] **Selecção múltipla** — modo selecção na `CategoryFilesPage`; apagar vários para lixeira.
- [x] **Purge automático** — cron Worker diário (04:00 UTC), 30 dias na lixeira.

### Áreas

- Workers: migrations D1, endpoints DELETE soft, restore, list trash
- Flutter: `category_files_page.dart`, `settings`, novos providers

### Critério de conclusão

Apagar ficheiro vai para lixeira; restaurar recupera; utilizador vê últimas 20 acções na conta.

---

## Fase 18 — Pré-visualização e miniaturas

**Objectivo:** Ver ficheiros antes de enviar e reconhecê-los na lista sem abrir download completo.

**Duração:** 2–3 dias

### Entregáveis

- [x] **Pré-upload** — diálogo após picker: nome, tamanho, cabe na quota?, botão Confirmar/Cancelar.
- [x] **Miniaturas** — JPEG no upload; grelha e lista com URL presigned; fallback ícone.
- [x] **Pré-visualização** — imagens, texto (≤512 KB) e PDF (≤10 MB) com `pdfx`.

### Áreas

- Flutter: widgets de tile, novo `file_preview_page.dart`
- Workers (opcional): endpoint `GET /files/:id/thumbnail` ou geração no upload

### Critério de conclusão

Imagem aparece em mosaico; toque abre pré-visualização; antes de enviar o utilizador confirma tamanho/quota.

---

## Fase 19 — Conta, privacidade e definições

**Objectivo:** Definições deixam de ser “placeholder”; requisitos legais mínimos.

**Duração:** 2 dias

### Entregáveis

- [x] **Renomear** `SettingsPage` (ex-placeholder; rotas inalteradas).
- [x] **Exportar dados** — `GET /me/export` JSON; guardar ficheiro nas Definições.
- [x] **Apagar conta** — `DELETE /me` + confirmação «APAGAR» na UI; purge D1 + R2.
- [x] **Legal** — links Termos / Privacidade (`url_launcher`, URLs em constantes).
- [ ] **Sessões** (opcional) — listar dispositivos / terminar outras sessões Firebase.

### Áreas

- `settings_page.dart`, Workers `users/me/export`, `users/me/delete`

### Critério de conclusão

Utilizador exporta dados e consegue pedir eliminação de conta com confirmação explícita.

---

## Fase 20 — Billing produção e quota proactiva

**Objectivo:** Upgrade de plano deixa de ser só simulação; utilizador é avisado antes da quota encher.

**Duração:** 3–5 dias  
**Depende de:** docs `PAGAMENTOS.md`, `PLANOS.md`

### Entregáveis

- [ ] **Gateway real ou sandbox** — integrar provedor definido (substituir `simulateCheckoutPayment` em prod).
- [ ] **Estado de subscrição** — plano actual, renovação, referência pendente, histórico.
- [ ] **Pós-upgrade** — invalidar profile; animar barra de quota; SnackBar de sucesso.
- [ ] **Alertas proactivos** — banner + (opcional) notificação local ao atingir 80%/95%; deep link para Billing.

### Áreas

- `billing_page.dart`, Workers checkout/webhook
- `quota_banner.dart`, profile provider

### Critério de conclusão

Pagamento de teste activa plano superior; quota reflecte novo limite; utilizador com 85% vê aviso mesmo sem ir ao dashboard.

---

## Fase 21 — Partilha por link

**Objectivo:** Partilhar ficheiro/pasta com terceiros de forma controlada.

**Duração:** 3–4 dias  
**Depende de:** Fase 17 (ficheiros estáveis); segurança em `SEGURANCA.md`

### Entregáveis

- [x] **Tabela `shares`** — token, `file_id`, expiração 7 dias (máx. 30), só leitura.
- [x] **API** — criar/revogar/listar; `GET /public/share/:token` download sem JWT.
- [x] **Flutter** — “Partilhar link” no menu; ecrã `/shares`; copiar URL.
- [ ] **Admin** — contagem de acessos por link (opcional; `access_count` já na API).

### Áreas

- Workers: rotas públicas + rate limit
- Flutter: `KiamiFileActionsButton`, nova página “Links partilhados”

### Critério de conclusão

Link público expira ao fim de X dias; revogação invalida imediatamente; download funciona sem login.

---

## Fase 22 — Offline e cache local

**Objectivo:** App útil com rede fraca; lista de ficheiros disponível offline.

**Duração:** 2–3 dias  
**Depende de:** Fase 15 (erros); beneficia da Fase 16 (fila persistida)

### Entregáveis

- [x] **Cache da lista** — `shared_preferences` com última snapshot de ficheiros + profile.
- [x] **Indicador offline** — banner “Sem ligação · a mostrar dados guardados”.
- [x] **Fila offline** — apagar/renomear enfileirados; sincronizar ao reconectar.

### Áreas

- Novo pacote ou módulo `lib/src/data/local/`
- `connectivity_plus` + providers Riverpod

### Critério de conclusão

Modo avião mostra ficheiros da última sincronização; acção enfileirada executa ao reconectar.

---

## Fase 23 — Pastas e organização

**Objectivo:** Além de categorias por tipo, pastas escolhidas pelo utilizador.

**Duração:** 3–4 dias

### Entregáveis

- [ ] **Schema** — `folders` (id, user_id, name, parent_id); `files.folder_id` nullable.
- [ ] **API** — CRUD pastas; mover ficheiro.
- [ ] **UI** — árvore ou lista de pastas no dashboard; breadcrumb na lista de ficheiros.

### Áreas

- D1 migration, Workers, Flutter dashboard + category ou novo ecrã “Pastas”

### Critério de conclusão

Utilizador cria pasta “Trabalho”, move ficheiros, navega sem perder categorias automáticas (opcional: filtro por pasta + categoria).

---

## Fase 24 — Qualidade, i18n e escala

**Objectivo:** Preparar crescimento de utilizadores e manutenção longa.

**Duração:** contínua (parcelar em sprints de 1–2 dias)

### Entregáveis

- [ ] **CI** — `flutter analyze`, `flutter test`, deploy Workers em PR (GitHub Actions).
- [ ] **Observabilidade** — Sentry Flutter + logs JSON Workers; métricas upload/erro.
- [ ] **API versionada** — prefixo `/v1`; política de deprecação.
- [ ] **i18n** — `flutter_localizations`; PT + EN; strings fora de `KiamiStrings` hardcoded restantes.
- [ ] **Acessibilidade** — semantics nos ícones quota/upload; tamanhos mínimos de toque.
- [ ] **Testes integração** — fluxo login → upload → quota com mock server.

### Critério de conclusão

PR não mergeia com analyze vermelho; erros em produção têm stack trace; app alterna idioma.

---

## Fase 25 — Funcionalidades avançadas (futuro)

**Objectivo:** Diferenciação a médio prazo; não bloquear fases 15–24.

### Backlog

- Upload em **background** (mobile: workmanager / foreground service)
- **Sincronização** automática de pasta no desktop
- **Compressão** inteligente antes do upload (imagens/vídeo)
- **2FA** Firebase para contas sensíveis
- **App iOS** nativa (`apps/ios` + `kiamicloud_core`)
- Partilha com **equipas** / espaços partilhados

---

## Calendário sugerido (≈ 3–4 semanas)

| Semana | Fases | Foco |
|--------|-------|------|
| 1 | 15 → 16 (início) | UX rápido + início da fila de upload |
| 2 | 16 (fim) → 17 | Upload fiável + lixeira/actividade |
| 3 | 18 → 19 → 20 (início) | Pré-visualização, conta, billing |
| 4 | 20 (fim) → 21 | Pagamentos reais + partilha |
| 5+ | 22 → 23 → 24 | Offline, pastas, CI/i18n parcelado |

Ajuste o ritmo conforme o tempo disponível por dia; **não avançar para Fase 21 sem Fase 20 estável** se o objectivo for monetização real.

---

## Ligação ao código actual (já feito recentemente)

Estes itens **já estão implementados** e servem de base para as fases acima:

- Vista lista/mosaico/detalhes e ordenação por categoria
- Upload seguro (sem carregar ficheiro gigante à cega na memória)
- Diálogos de quota + sugestão de upgrade
- Ajuda (?) na barra de armazenamento
- Navegação por categoria dedicada
- Tema claro/escuro e scroll/safe area

---

## Como usar este documento

1. Antes de cada dia: escolher **uma fase** (ou um bloco de entregáveis).
2. Marcar `[x]` nos checkboxes ao concluir.
3. Actualizar a tabela em `docs/ROADMAP.md` (estado da fase).
4. Registar bloqueios em `docs/BETA.md` ou issue interna.

**Próximo passo recomendado:** iniciar **Fase 15** amanhã (preferências + pesquisa global + testes).
