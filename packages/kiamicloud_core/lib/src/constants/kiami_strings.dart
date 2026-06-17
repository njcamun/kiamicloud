import '../api/kiami_api_config.dart';

/// Textos da UI em português (MVP).
abstract final class KiamiStrings {
  static const String appName = 'KiamiCloud';
  static const String slogan = 'Minha Cloud. Meu mundo. Sem limites.';

  static const String splashLoading = 'A preparar a tua cloud…';

  static const String uploadDropTitle = 'Clique para fazer upload…';
  static const String noTransferLimit = 'Sem limite';
  static String uploadDropSubtitle(String maxPerFileLabel) =>
      maxPerFileLabel == noTransferLimit
          ? 'Sem limite por ficheiro · vários permitidos'
          : 'Até $maxPerFileLabel por ficheiro · vários permitidos';

  static const String authTitle = 'Bem-vindo de volta';
  static const String authSubtitle =
      'Inicia sessão para aceder aos teus ficheiros na cloud.';
  static const String registerTitle = 'Criar conta';
  static const String registerSubtitle =
      'Regista-te para começar a usar a tua cloud.';
  static const String authBrandHint =
      'A tua cloud africana — simples, segura e preparada para crescer contigo.';
  static const String emailLabel = 'E-mail';
  static const String passwordLabel = 'Palavra-passe';
  static const String loginButton = 'Entrar';
  static const String registerButton = 'Criar conta';
  static const String googleButton = 'Continuar com Google';
  static const String forgotPassword = 'Esqueceste a palavra-passe?';
  static const String switchToRegister = 'Ainda não tens conta? Regista-te';
  static const String switchToLogin = 'Já tens conta? Inicia sessão';
  static const String forgotPasswordTitle = 'Recuperar palavra-passe';
  static const String forgotPasswordSent =
      'Enviámos um e-mail com instruções de recuperação.';
  static const String sendButton = 'Enviar';
  static const String cancelButton = 'Cancelar';
  static const String okButton = 'OK';
  static const String closeButton = 'Fechar';
  static const String firebaseNotConfigured =
      'Firebase não configurado. Execute flutterfire configure (ver docs/FIREBASE_SETUP.md).';
  static const String googleDesktopNotConfigured =
      'Google no Windows: edite apps/cloud/desktop/lib/google_oauth_client.dart com o Client ID OAuth (Google Cloud → Credenciais → App para computador). Depois reinicie a app (R).';

  static const String dashboardGreeting = 'Olá';
  static const String dashboardTitle = 'Os meus ficheiros';
  static const String dashboardSearchHint = 'Pesquisar ficheiros…';
  static const String filesCountOne = '1 ficheiro';
  static const String filesCountMany = 'ficheiros';

  static const String categoryFilterAll = 'Todos';
  static const String categoryImages = 'Imagens';
  static const String categoryDocuments = 'Documentos';
  static const String categoryVideo = 'Vídeo';
  static const String categoryAudio = 'Áudio';
  static const String categoryOthers = 'Outros';
  static const String categoryUnknown = 'Desconhecido';
  static const String categorySearchEmpty =
      'Nenhum ficheiro nesta categoria para a pesquisa actual.';
  static const String categoryFilesEmpty = 'Nenhum ficheiro nesta categoria.';
  static const String categorySelectHint =
      'Toque numa categoria para ver os ficheiros.';
  static const String fileListSort = 'Ordenar';
  static const String fileListSortNameAsc = 'Nome (A → Z)';
  static const String fileListSortNameDesc = 'Nome (Z → A)';
  static const String fileListSortSizeAsc = 'Tamanho (menor primeiro)';
  static const String fileListSortSizeDesc = 'Tamanho (maior primeiro)';
  static const String fileListSortDateAsc = 'Data (mais antigo)';
  static const String fileListSortDateDesc = 'Data (mais recente)';
  static const String fileListViewList = 'Lista';
  static const String fileListViewGrid = 'Mosaico';
  static const String fileListViewDetails = 'Detalhes';
  static String fileListCount(int count) =>
      count == 1 ? '1 ficheiro' : '$count ficheiros';
  static const String storagePercent = 'utilizado';
  static const String quotaWarning =
      'A usar mais de 80% do armazenamento. Considere apagar ficheiros.';
  static const String quotaCritical =
      'Quota quase cheia (95%). Liberte espaço em breve.';
  static const String quotaFull =
      'Quota cheia. Apague ficheiros para voltar a enviar.';
  static const String quotaAvailable = 'Disponível';
  static const String quotaUploadBlocked = 'Sem espaço disponível na quota.';
  static const String quotaFileTooBigForQuota =
      'Ficheiro maior que o espaço disponível na quota.';
  static const String quotaFileTooBigForQuotaDetail =
      'O ficheiro seleccionado excede o espaço livre do seu plano. '
      'Apague ficheiros antigos ou faça upgrade para aumentar a quota.';
  static const String quotaLimitDialogTitle = 'Limite de armazenamento';
  static const String quotaLimitUpgradeHint =
      'Faça upgrade do plano para obter mais espaço e voltar a enviar ficheiros maiores.';
  static const String quotaLimitUpgradeButton = 'Ver planos';
  static String quotaLimitDialogSizes(String fileSize, String available) =>
      'Tamanho do ficheiro: $fileSize · Espaço disponível: $available';
  static const String storageHelpTitle = 'Como funciona o armazenamento';
  static const String storageHelpUsageTitle = 'Barra de utilização';
  static const String storageHelpUsageBody =
      'Mostra quanto do seu plano já está ocupado. A percentagem reflecte o total '
      'de ficheiros na cloud em relação à quota do plano actual.';
  static String storageHelpPlanTitle(String plan, String quota) =>
      'Plano actual ($plan · $quota)';
  static const String storageHelpPlanBody =
      'Cada plano define a quota total de armazenamento. Quando o espaço livre '
      'acaba, novos uploads são bloqueados até libertar espaço ou fazer upgrade.';
  static String storageHelpUploadTitle(String maxPerFile) =>
      'Limite por ficheiro ($maxPerFile)';
  static const String storageHelpUploadBody =
      'Cada envio tem um tamanho máximo por ficheiro. Ficheiros acima desse limite '
      'são recusados antes do envio, para proteger a app e a rede.';
  static const String storageHelpAlertsTitle = 'Avisos (80% e 95%)';
  static const String storageHelpAlertsBody =
      'Acima de 80% aparece um aviso amarelo; acima de 95%, aviso crítico. '
      'Com a quota cheia (100%), o upload fica desactivado até libertar espaço.';
  static const String storageHelpUpgradeTitle = 'Upgrade do plano';
  static const String storageHelpUpgradeBody =
      'Em Planos e pagamentos pode escolher um plano com mais armazenamento. '
      'Após o pagamento (ou confirmação em modo desenvolvimento), a nova quota '
      'é aplicada de imediato e pode voltar a enviar ficheiros.';
  static const String storageHelpUpgradeButton = 'Fazer upgrade';
  static const String storageHelpTooltip = 'Como funciona o armazenamento';
  static const String settingsQuotaTitle = 'Armazenamento e plano';
  static const String settingsUpgradeHint =
      'Faça upgrade para mais armazenamento.';
  static const String settingsBilling = 'Planos e pagamentos';
  static const String settingsPrivacySection = 'Privacidade e conta';
  static const String settingsExportData = 'Exportar os meus dados';
  static const String settingsExportDataHint =
      'Descarrega um JSON com perfil, ficheiros e actividade.';
  static const String settingsExportSuccess = 'Exportação guardada.';
  static const String settingsExportError = 'Não foi possível exportar os dados.';
  static const String settingsTerms = 'Termos de utilização';
  static const String settingsPrivacy = 'Política de privacidade';
  static const String settingsLegal = 'Legal';
  static const String settingsDeleteAccount = 'Apagar conta';
  static const String settingsDeleteAccountTitle = 'Apagar conta?';
  static const String settingsDeleteAccountBody =
      'Remove todos os ficheiros e dados do KiamiCloud. Esta ação é irreversível.\n\n'
      'Escreve APAGAR para confirmar.';
  static const String settingsDeleteConfirmHint = 'APAGAR';
  static const String settingsDeleteSuccess = 'Conta removida do KiamiCloud.';
  static const String settingsDeleteError =
      'Não foi possível apagar a conta. Tente novamente.';
  static const String previewTextTooLarge =
      'Ficheiro de texto demasiado grande para pré-visualizar (máx. 512 KB).';
  static const String previewPdfTooLarge =
      'PDF demasiado grande para pré-visualizar (máx. 10 MB).';
  static const String previewPdfError =
      'Não foi possível abrir este PDF.';
  static const String previewLoadError =
      'Não foi possível carregar a pré-visualização.';
  static const String previewDocxTooLarge =
      'Documento Word demasiado grande para pré-visualizar (máx. 20 MB).';
  static const String previewDocxError =
      'Não foi possível ler o conteúdo deste documento Word.';
  static const String previewMediaError =
      'Não foi possível reproduzir este ficheiro neste dispositivo. '
      'Use «Download» para o abrir noutra app.';
  static const String galleryPrevious = 'Anterior';
  static const String galleryNext = 'Seguinte';
  static const String galleryNoPreview =
      'Pré-visualização não disponível para este tipo de ficheiro.';
  static String galleryPosition(int current, int total) => '$current / $total';
  static const String quotaBannerUpgradeHint = 'Toque para ver planos';
  static const String billingUpgradeSuccessAction = 'Ver armazenamento';
  static const String settingsAudit = 'Actividade recente';
  static const String settingsAuditEmpty = 'Sem actividade registada.';
  static const String billingTitle = 'Planos e pagamentos';
  static const String billingCurrentPlan = 'Plano actual';
  static const String billingFreePlan = 'Gratuito';
  static const String billingPerMonth = '/mês';
  static const String billingUpgradeTitle = 'Fazer upgrade';
  static const String billingUpgradeHint =
      'Escolha um plano superior. Efectue a transferência e envie o comprovativo.';
  static const String billingUpgradeButton = 'Escolher';
  static const String billingCurrentBadge = 'Actual';
  static const String billingCheckoutCreated = 'Referência de pagamento criada.';
  static const String billingPlanActivated = 'Plano activado com sucesso.';
  static const String billingPendingTitle = 'Pagamento pendente';
  static const String billingAwaitingReviewTitle = 'Comprovativo em análise';
  static String billingAwaitingReviewHint(int hours) =>
      'Recebemos o seu comprovativo. O upgrade será activado em até $hours horas.';
  static const String billingRejectedTitle = 'Pagamento rejeitado';
  static const String billingRejectedReason = 'Motivo';
  static const String billingPaymentInstructionsTitle = 'Como pagar';
  static const String billingPaymentHolder = 'Titular';
  static const String billingPaymentIban = 'IBAN';
  static const String billingPaymentMbWay = 'MB Way';
  static const String billingPaymentNote = 'Nota';
  static String billingPaymentSla(int hours) =>
      'Após enviar o comprovativo, o upgrade é activado em até $hours horas.';
  static const String billingCopyRef = 'Copiar referência';
  static const String billingRefCopied = 'Referência copiada.';
  static const String billingCopyIban = 'Copiar IBAN';
  static const String billingIbanCopied = 'IBAN copiado.';
  static const String billingSubmitProof = 'Enviar comprovativo';
  static const String billingProofUploading = 'A enviar comprovativo…';
  static const String billingProofSubmitted =
      'Comprovativo enviado. Aguarde a confirmação.';
  static const String billingProofHint =
      'Foto ou PDF do comprovativo (máx. 5 MB).';
  static const String billingProofTooLarge =
      'Comprovativo demasiado grande (máx. 5 MB).';
  static const String billingDevSimulateHint =
      'Modo desenvolvimento: confirme o pagamento abaixo para activar o plano sem comprovativo.';
  static const String billingSimulatePay = 'Confirmar pagamento (dev)';
  static const String subscriptionBannerAction = 'Renovar plano';
  static const String subscriptionStatusTitle = 'Estado da subscrição';
  static const String subscriptionStatusActive = 'Activa';
  static const String subscriptionStatusGrace = 'Período de tolerância';
  static const String subscriptionStatusRestricted = 'Restrita (só download)';
  static const String subscriptionStatusSuspended = 'Suspensa';
  static const String subscriptionStatusPendingDeletion = 'Eliminação agendada';
  static const String subscriptionStatusCancelled = 'Cancelada';
  static const String subscriptionEndsAt = 'Válida até';
  static const String subscriptionGraceEndsAt = 'Tolerância até';
  static const String subscriptionDeletionAt = 'Eliminação em';
  static String subscriptionMessageFor({
    required String effectiveStatus,
    String? blockReason,
  }) {
    if (blockReason == 'storage_over_quota') {
      return subscriptionStorageOverQuota;
    }
    return switch (effectiveStatus) {
      'grace_period' => subscriptionGracePeriod,
      'restricted' => subscriptionRestricted,
      'suspended' => subscriptionSuspended,
      'pending_deletion' => subscriptionPendingDeletion,
      'deleted' => subscriptionDeleted,
      _ => subscriptionInactive,
    };
  }

  static const String subscriptionStorageOverQuota =
      'O espaço utilizado excede o limite do plano. Remova ficheiros ou actualize a subscrição.';
  static const String subscriptionGracePeriod =
      'A subscrição expirou. Renove nos próximos dias para manter todos os acessos.';
  static const String subscriptionRestricted =
      'Subscrição em atraso: novos uploads bloqueados. Renove o plano para continuar.';
  static const String subscriptionSuspended =
      'Conta suspensa por falta de pagamento. Renove para recuperar acesso.';
  static const String subscriptionPendingDeletion =
      'Conta será eliminada em breve. Renove imediatamente para evitar perda de dados.';
  static const String subscriptionDeleted = 'Conta eliminada.';
  static const String subscriptionInactive =
      'Operação não permitida no estado actual da subscrição.';
  static const String subscriptionUploadBlocked =
      'Upload bloqueado pelo estado da subscrição.';
  static const String adminSubscriptionsTitle = 'Subscrições';
  static const String adminSubscriptionsEmpty = 'Nenhuma subscrição encontrada.';
  static const String adminSubscriptionsFilterAll = 'Todas';
  static const String adminSubscriptionReactivate = 'Reactivar';
  static const String adminSubscriptionReactivated = 'Subscrição reactivada.';
  static const String adminSubscriptionAdjustEnds = 'Ajustar vencimento';
  static const String adminSubscriptionEndsAtUpdated = 'Data de vencimento actualizada.';
  static const String adminViewSubscriptions = 'Ver subscrições';
  static const String dashboardEmpty = 'Ainda não tens ficheiros na cloud.';
  static String dashboardEmptyHint(String maxPerFileLabel) =>
      'Carrega o teu primeiro ficheiro (até $maxPerFileLabel por ficheiro).';
  static const String uploadButton = 'Carregar ficheiro';
  static const String uploadInProgress = 'A enviar…';
  static String uploadInProgressCount(int current, int total) =>
      'A enviar $current de $total…';
  static const String uploadSuccess = 'Ficheiro enviado com sucesso.';
  static String uploadSuccessMultiple(int count) => count == 1
      ? uploadSuccess
      : '$count ficheiros enviados com sucesso.';
  static String uploadPartialSuccess(int ok, int failed) =>
      '$ok enviado(s), $failed não enviado(s).';
  static String uploadPartialSuccessWithLimit(int ok, int failed, String maxPerFileLabel) =>
      '$ok enviado(s). $failed ignorado(s) — limite do plano: $maxPerFileLabel por ficheiro.';
  static String uploadSkippedTooLarge(int count, String maxPerFileLabel) =>
      count == 1
          ? uploadTooLarge(maxPerFileLabel)
          : '$count ficheiros ignorados (máximo $maxPerFileLabel cada).';
  static String uploadTooLarge(String maxPerFileLabel) =>
      'Ficheiro demasiado grande para o teu plano (máximo $maxPerFileLabel).';
  static String uploadTooLargeForPlan(String planName, String maxPerFileLabel) =>
      'O plano $planName permite até $maxPerFileLabel por ficheiro.';
  static const String uploadNoBytes =
      'Não foi possível ler o ficheiro. Tente outro ficheiro.';
  static String uploadNoBytesMultiple(int count) =>
      '$count ficheiro(s) sem dados — não foi possível ler.';
  static const String downloadButton = 'Descarregar';
  static const String downloadSaved = 'Ficheiro guardado.';
  static const String fileRename = 'Renomear';
  static const String fileShare = 'Partilhar link';
  static const String fileShareCreated =
      'Link de partilha copiado (válido 7 dias).';
  static const String fileShareError =
      'Não foi possível criar o link de partilha.';
  static const String sharesTitle = 'Links partilhados';
  static const String sharesEmpty = 'Nenhum link de partilha activo.';
  static const String sharesRevoke = 'Revogar';
  static const String sharesRevoked = 'Link revogado.';
  static const String sharesAccessCount = 'acessos';
  static const String sharesExpired = 'Expirado';
  static const String sharesActive = 'Activo';
  static const String offlineDeleteQueued =
      'Sem rede — apagar enfileirado. Sincroniza ao reconectar.';
  static const String offlineRenameQueued =
      'Sem rede — renomear enfileirado. Sincroniza ao reconectar.';
  static const String offlineSyncDone = 'Alterações offline sincronizadas.';
  static const String settingsShares = 'Links partilhados';
  static const String fileDelete = 'Apagar';
  static const String fileRenameTitle = 'Novo nome';
  static const String fileDeleteTitle = 'Apagar ficheiro?';
  static const String fileDeleteConfirm =
      'O ficheiro vai para a lixeira durante 30 dias. Podes restaurá-lo nesse prazo; depois é apagado automaticamente.';
  static const String fileDeleted = 'Ficheiro movido para a lixeira.';
  static const String fileRestored = 'Ficheiro restaurado.';
  static const String filePermanentDeleted = 'Ficheiro apagado definitivamente.';
  static const String trashTitle = 'Lixeira';
  static const String trashEmpty = 'A lixeira está vazia.';
  static const String trashHint =
      'Restaura ou apaga definitivamente. Após 30 dias na lixeira, os ficheiros são removidos automaticamente.';
  static const String trashRestore = 'Restaurar';
  static const String trashDeleteForever = 'Apagar definitivamente';
  static const String trashDeleteForeverConfirm =
      'Este ficheiro será removido de forma permanente. Continuar?';
  static const String selectionMode = 'Seleccionar';
  static const String selectionDelete = 'Apagar seleccionados';
  static const String selectionCount = 'seleccionado(s)';
  static const String offlineBannerMessage =
      'Sem ligação. A mostrar os últimos dados guardados.';
  static String uploadQueueTitle(int n) =>
      n == 1 ? '1 envio na fila' : '$n envios na fila';
  static const String uploadQueueRetry = 'Repetir';
  static String uploadBackgroundStarted(int n) => n == 1
      ? '1 ficheiro na fila. O envio continua em segundo plano — avisamos quando terminar.'
      : '$n ficheiros na fila. Os envios continuam em segundo plano — avisamos quando terminar.';
  static String uploadBackgroundComplete(int ok, int failed) {
    if (failed == 0) {
      return ok == 1
          ? 'Envio concluído com sucesso.'
          : '$ok envios concluídos com sucesso.';
    }
    if (ok == 0) {
      return failed == 1
          ? 'O envio falhou. Veja a fila para repetir.'
          : 'Todos os $failed envios falharam. Veja a fila para repetir.';
    }
    return '$ok enviado(s), $failed falhou/falharam. Veja a fila para repetir.';
  }
  static const String fileRenamed = 'Nome actualizado.';
  static const String fileMoreActions = 'Mais acções';
  static const String apiUnavailableTitle = 'Servidor temporariamente indisponível';
  static const String apiErrorTitle = 'Não foi possível concluir o pedido';
  static const String apiUnavailableRetry = 'Tentar novamente';
  static String apiUnavailableBody(String baseUrl) {
    if (KiamiApiConfig.isLocalApiUrl) {
      return 'Não conseguimos falar com $baseUrl.\n'
          'Confirme que a API está a correr no ZimaBlade (contentor kiamicloud-api) '
          'e que o dispositivo está na mesma rede Wi‑Fi.';
    }
    return 'Não conseguimos falar com $baseUrl.\n'
        'Pode ser uma falha temporária na cloud — tente de novo dentro de momentos.';
  }
  static const String apiUnavailableTimeout =
      'O servidor demorou demasiado a responder. Tente novamente.';
  static const String storageUsed = 'Armazenamento usado';
  static const String planBasico = 'Plano Básico — 20 GB · 15 MB/ficheiro';

  static const String navFiles = 'Ficheiros';
  static const String navRecent = 'Recentes';
  static const String navSettings = 'Definições';

  static const String settingsTitle = 'Definições';
  static const String settingsAccount = 'Conta';
  static const String settingsTheme = 'Tema';
  static const String settingsThemeSystem = 'Sistema';
  static const String settingsThemeLight = 'Claro';
  static const String settingsThemeDark = 'Escuro';
  static const String settingsChangeServer = 'Mudar de servidor';
  static const String settingsChangeServerHint =
      'Cloudflare ou CasaOS na sua rede';
  static const String settingsServerTitle = 'Servidor';
  static const String settingsServerCurrent = 'Servidor actual';
  static const String settingsServerModeLabel = 'Destino';
  static const String settingsServerModeCloud = 'Cloud (Cloudflare)';
  static const String settingsServerModeLocal = 'Local (CasaOS)';
  static const String settingsServerIpLabel = 'Endereço IP do Blade';
  static const String settingsServerIpHint = 'Ex.: 192.168.100.170';
  static String settingsServerLocalPortHint(int port) =>
      'Porta API: $port (predefinida no CasaOS)';
  static const String settingsServerTest = 'Testar ligação';
  static const String settingsServerSave = 'Guardar servidor';
  static const String settingsServerTestOk = 'Ligação OK — pode guardar.';
  static const String settingsServerTestRequired =
      'Teste a ligação antes de guardar.';
  static const String settingsServerSaved = 'Servidor guardado.';
  static const String adminCanSwitchServer = 'Permitir mudar de servidor';
  static const String adminCanSwitchServerHint =
      'Nas Definições da app cloud, o utilizador pode escolher Cloud ou CasaOS.';
  static const String settingsLogout = 'Terminar sessão';

  static const String settingsVersion = 'Versão';
  static const String settingsDevUnlocked =
      'Ferramentas de API desbloqueadas (sessão actual).';
  static const String settingsDevApiTitle = 'Token API (Firebase)';
  static const String settingsDevApiSubtitle =
      'Para testar curl / Workers. Válido ~1 hora.';
  static const String settingsDevCopyToken = 'Copiar token';
  static const String settingsDevRefreshToken = 'Renovar e copiar';
  static const String settingsDevTokenCopied =
      'Token copiado. Não partilhe com ninguém.';
  static const String settingsDevNoSession =
      'Sem sessão activa. Inicie sessão primeiro.';
  static const String settingsDevFirebaseOff =
      'Firebase não configurado nesta app.';
  static const String settingsDevTokenError =
      'Não foi possível obter o token. Tente novamente.';

  static const String settingsAdmin = 'Painel administrativo';
  static const String settingsAdminSection = 'Administração';
  static const String adminTitle = 'Administração';
  static const String adminSearchHint = 'Pesquisar por email, nome ou UID…';
  static const String adminUsersTitle = 'Utilizadores';
  static const String adminSecurityTitle = 'Eventos de segurança';
  static const String adminEditUser = 'Editar utilizador';
  static const String adminPlanLabel = 'Plano';
  static const String adminStorageSection = 'Armazenamento';
  static const String adminStorageCapacity = 'Capacidade do plano';
  static const String adminStorageInUse = 'Em uso';
  static const String adminStorageCustom = 'Personalizar capacidade';
  static const String adminStoragePlanDefault = 'Padrão do plano';
  static const String adminStorageReadOnlyHint =
      'A capacidade segue o plano seleccionado. O uso reflecte os ficheiros do utilizador.';
  static const String adminLocalUnlimitedHint =
      'Servidor local (Blade): armazenamento e transferência sem limite. '
      'Os ajustes de capacidade e taxa de transferência aplicam-se apenas na cloud Cloudflare.';
  static const String adminTransferSection = 'Taxa de transferência';
  static const String adminTransferPerFile = 'Limite máximo por ficheiro';
  static const String adminTransferPlanDefault = 'Padrão do plano';
  static const String adminTransferCustom = 'Personalizar para este utilizador';
  static const String adminTransferCustomHint =
      'Útil para excepções temporárias. Não altera a quota de armazenamento.';
  static const String adminTransferOverrideBadge = 'Personalizado';
  static const String adminTransferPreset15 = '15 MB';
  static const String adminTransferPreset75 = '75 MB';
  static const String adminTransferPreset150 = '150 MB';
  static const String adminSave = 'Guardar';
  static const String adminUserUpdated = 'Utilizador actualizado.';
  static String adminUserUpdatedMismatch(
    String savedStorage,
    String expectedStorage,
    String savedTransfer,
    String expectedTransfer,
  ) =>
      'Guardado, mas a API devolveu valores diferentes: '
      'armazenamento $savedStorage (esperado $expectedStorage), '
      'transferência $savedTransfer (esperado $expectedTransfer). '
      'Confirme a migração 0018 na API se o armazenamento não gravou.';
  static const String adminStatUsers = 'Utilizadores';
  static const String adminStatFiles = 'Ficheiros activos';
  static const String adminStatStorage = 'Armazenamento total';
  static const String adminStatPending = 'Pagamentos pendentes';
  static const String adminStatSecurity = 'Eventos (24 h)';
  static const String adminOverviewTitle = 'Resumo';
  static const String adminCfUsageTitle = 'Cloudflare (métricas)';
  static const String adminCfWorkers = 'Workers';
  static const String adminCfD1 = 'D1';
  static const String adminCfR2 = 'R2';
  static const String adminCfWorkersValue = 'Pedidos/mês (est.)';
  static const String adminCfWorkersCpu = 'CPU/mês (est.)';
  static const String adminCfD1Storage = 'Armazenamento';
  static const String adminCfD1Reads = 'Leituras/mês (est.)';
  static const String adminCfD1Writes = 'Escritas/mês (est.)';
  static const String adminCfR2Storage = 'Armazenamento';
  static const String adminCfR2ClassA = 'Ops. escrita/mês (est.)';
  static const String adminCfR2ClassB = 'Ops. leitura/mês (est.)';
  static const String adminCfCostTitle = 'Estimativa de custo';
  static const String adminCfCostTotal = 'Total mensal (est.)';
  static const String adminCfCostWorkers = 'Workers (incl. plano base)';
  static const String adminCfCostD1 = 'D1 (extra)';
  static const String adminCfCostR2 = 'R2 (extra)';
  static const String adminCfMetricInfoTitle = 'O que é esta métrica?';
  static const String adminCfTapForInfo = 'Toque para saber mais';
  static const String adminCfLoadHint =
      'Actualize a página ou confirme que a API Cloudflare está activa nas Definições.';
  static const String adminViewPendingPayments = 'Ver pagamentos pendentes';
  static const String adminCheckoutsTitle = 'Pagamentos';
  static const String adminCheckoutsPending = 'Por rever';
  static const String adminCheckoutReference = 'Referência';
  static const String adminCheckoutAmount = 'Valor';
  static const String adminCheckoutPlan = 'Plano';
  static const String adminCheckoutUser = 'Utilizador';
  static const String adminCheckoutEmail = 'E-mail';
  static const String adminCheckoutDate = 'Data';
  static const String adminCheckoutConfirm = 'Confirmar pagamento';
  static const String adminCheckoutConfirmed = 'Pagamento confirmado.';
  static const String adminCheckoutReject = 'Rejeitar';
  static const String adminCheckoutRejectTitle = 'Rejeitar comprovativo';
  static const String adminCheckoutRejectHint =
      'Indique o motivo (mín. 5 caracteres). O utilizador verá esta mensagem.';
  static const String adminCheckoutRejected = 'Comprovativo rejeitado.';
  static const String adminCheckoutViewProof = 'Ver comprovativo';
  static const String adminCheckoutProofTitle = 'Comprovativo';
  static const String adminCheckoutNoProof = 'Sem comprovativo';
  static const String adminCheckoutEmpty = 'Nenhum comprovativo por rever.';
  static const String adminUserDetailTitle = 'Utilizador';
  static const String adminUserFiles = 'Ficheiros';
  static const String adminFeedbackSection = 'Suporte / feedback';
  static const String adminFeedbackMarkDone = 'Marcar como tratado';
  static const String adminFeedbackReviewed = 'Mensagem marcada como tratada.';
  static const String adminFeedbackNotification = 'Novo suporte';
  static const String settingsSupport = 'Suporte';
  static const String settingsSupportHint = 'WhatsApp ou e-mail';
  static const String supportWhatsAppDefaultMessage =
      'Olá, preciso de ajuda com a app KiamiCloud.';
  static const String supportWhatsAppUnavailable =
      'WhatsApp de suporte ainda não configurado.';
  static const String supportEmailUnavailable =
      'Não foi possível abrir o cliente de e-mail.';
  static const String supportEmailSubject = 'Suporte KiamiCloud';
  static const String supportContactTitle = 'Contactar suporte';
  static const String supportContactBody =
      'Escolha como prefere falar connosco.';
  static const String supportContactWhatsApp = 'WhatsApp';
  static const String supportContactEmail = 'E-mail';
  static const String storageSupportTooltip = 'Suporte';
  static const String legalDocumentTitle = 'Documentação legal';
  static const String legalAcceptanceTitle = 'Termos e privacidade';
  static const String legalAcceptanceBody =
      'Antes de continuar, leia a documentação legal da KiamiCloud '
      'e confirme que concorda com os termos e a política de privacidade.';
  static const String legalAcceptanceReadButton = 'Ler documentação legal';
  static const String legalAcceptanceReadAgain = 'Abrir documentação novamente';
  static const String legalAcceptanceCheckbox =
      'Li e aceito os termos de utilização e a política de privacidade.';
  static const String legalAcceptanceOpenFirst =
      'Abra o documento antes de aceitar.';
  static const String legalAcceptanceContinue = 'Continuar';
  static const String settingsDangerSection = 'Zona de risco';
  static const String accountActivityTitle = 'Suporte e actividade';
  static const String notificationsTitle = 'Notificações';
  static const String notificationsTooltip = 'Notificações do plano';
  static const String notificationsHint =
      'Avisos sobre o plano, subscrição e armazenamento. Para suporte, use o ícone ao lado.';
  static const String notificationsEmpty = 'Sem notificações.';
  static const String notificationsMarkAllRead = 'Marcar todas como lidas';
  static const String accountActivityHint =
      'Historico de mensagens, pagamentos e notificações da conta.';
  static const String accountActivityEmpty =
      'Sem actividade registada. Envie uma mensagem ou faça upgrade de plano.';
  static const String accountActivityNewMessage = 'Nova mensagem';
  static const String adminActivityTitle = 'Actividade recente';
  static const String adminUserActivityTitle = 'Notificações do utilizador';
  static const String adminFeedbackTitle = 'Feedback beta';
  static const String adminNotConfigured =
      'Defina ADMIN_UIDS no wrangler.toml com o seu Firebase UID.';
  static const String adminRetry = 'Tentar novamente';

  static const String betaBanner = 'Versao Beta — dados podem mudar';
  static const String localBladeConsoleSection = 'Servidor local';
  static const String localBladeConsole = 'Consola Blade (admin)';
  static const String localBladeConsoleHint =
      'Monitorização LAN — actividade, ficheiros e segurança';
  static const String localStorageHint =
      'No servidor local (CasaOS) não há limite de armazenamento nem de '
      'transferência por ficheiro. Os limites do plano aplicam-se apenas na '
      'cloud Cloudflare.';
  static const String betaDiagnosticsTitle = 'Programa Beta';
  static const String betaEnvLabel = 'Ambiente';
  static const String betaApiLabel = 'API';
  static const String betaTestApi = 'Testar ligação à API';
  static const String betaApiOk = 'API a responder correctamente.';
  static const String betaFeedbackTitle = 'Suporte e feedback';
  static const String betaFeedbackHint =
      'Descreva bugs, sugestoes ou dificuldades. Obrigado por testar o KiamiCloud.';
  static const String betaFeedbackPlaceholder = 'A sua mensagem…';
  static const String betaFeedbackSend = 'Enviar';
  static const String betaFeedbackThanks = 'Feedback enviado. Obrigado!';
  static const String betaOpenFeedback = 'Enviar mensagem (beta)';

  // Back-up do dispositivo (Android)
  static const String deviceBackupTooltip = 'Back-up do dispositivo';
  static const String deviceBackupConfirmTitle = 'Iniciar back-up?';
  static const String deviceBackupConfirmBody =
      'O processo pode demorar vários minutos. '
      'Mantenha a app aberta e aguarde até ver a mensagem de sucesso.';
  static const String deviceBackupConfirmStart = 'Continuar';
  static const String deviceBackupScopeTitle = 'O que incluir no back-up?';
  static const String deviceBackupScopeContacts = 'Contactos telefónicos';
  static const String deviceBackupScopeApps = 'Aplicações instaladas';
  static const String deviceBackupScopeBoth = 'Contactos e aplicações';
  static const String deviceBackupScopeConfirm = 'Iniciar back-up';
  static const String deviceBackupProgressTitle = 'Back-up em curso';
  static const String deviceBackupPreparing = 'A preparar…';
  static const String deviceBackupWaitHint =
      'Não feche a app até o processo terminar.';
  static const String deviceBackupSuccessTitle = 'Back-up concluído';
  static const String deviceBackupSuccessBody =
      'Os ficheiros de back-up foram enviados para a sua cloud. '
      'Pode continuar a usar a app normalmente.';
  static const String deviceBackupPermissionDenied =
      'Permissão negada. Active o acesso a contactos nas definições do sistema.';
  static String deviceBackupFailed(String detail) =>
      'Falha no back-up: $detail';

  static const String deviceRestoreTooltip = 'Restaurar back-up';
  static const String deviceBackupMenuBackup = 'Criar back-up';
  static const String deviceBackupMenuRestore = 'Restaurar back-up';
  static const String deviceRestoreNoBackups =
      'Não há ficheiros de back-up na sua cloud. Crie um back-up primeiro.';
  static const String deviceRestorePickTitle = 'Escolher back-up';
  static const String deviceRestoreConfirmTitle = 'Restaurar back-up?';
  static String deviceRestoreConfirmBody({
    required String stamp,
    required bool hasContacts,
    required bool hasApps,
  }) {
    final parts = <String>[];
    if (hasContacts) parts.add('contactos');
    if (hasApps) parts.add('aplicações');
    final what = parts.join(' e ');
    return 'Será restaurado o back-up de $what de $stamp.\n\n'
        'Os contactos serão adicionados ao telefone (podem duplicar entradas existentes). '
        'As apps abrem o instalador do Android — confirme cada instalação no ecrã do sistema.';
  }

  static const String deviceRestoreConfirmStart = 'Restaurar';
  static const String deviceRestorePreparing = 'A preparar restore…';
  static const String deviceRestoreDownloadingContacts =
      'A transferir contactos da cloud…';
  static const String deviceRestoreDownloadingApps =
      'A transferir apps da cloud…';
  static const String deviceRestoreProgressTitle = 'Restore em curso';
  static const String deviceRestoreWaitHint =
      'Mantenha a app aberta. Para apps, confirme cada instalação no sistema.';
  static const String deviceRestoreApkContinueTitle = 'Instalar aplicação';
  static const String deviceRestoreApkContinue = 'Continuar';
  static String deviceRestoreApkFirstBody(int total) =>
      'Será aberto o instalador do Android para a 1.ª de $total aplicações. '
      'Confirme a instalação e depois toque em Continuar.';
  static String deviceRestoreApkContinueBody(int current, int total) =>
      'Quando a instalação anterior terminar, toque em Continuar para a '
      '$current.ª de $total aplicações.';
  static const String deviceRestoreSuccessTitle = 'Restore concluído';
  static String deviceRestoreSuccessBody({
    required int contacts,
    required int apks,
  }) {
    final parts = <String>[];
    if (contacts > 0) {
      parts.add(
        contacts == 1
            ? '1 contacto adicionado'
            : '$contacts contactos adicionados',
      );
    }
    if (apks > 0) {
      parts.add(
        apks == 1
            ? '1 app enviada ao instalador'
            : '$apks apps enviadas ao instalador',
      );
    }
    if (parts.isEmpty) return 'Operação concluída.';
    return '${parts.join('. ')}.';
  }

  static const String deviceRestorePermissionDenied =
      'Permissão negada. Active contactos e instalação de apps nas definições.';
  static String deviceRestoreFailed(String detail) =>
      'Falha no restore: $detail';
  static const String settingsBetaSection = 'Beta e diagnóstico';
}
