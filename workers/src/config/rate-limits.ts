/** Limites de rate (Fase 11). Ajustar em producao conforme trafego. */
export const RATE_LIMITS = {
  /** Por IP — rotas publicas e health */
  ipGlobalPerMinute: 200,
  /** Por IP — tentativas sem token valido */
  ipAuthFailPerMinute: 30,
  /** Por utilizador autenticado — API geral */
  userApiPerMinute: 120,
  /** Por utilizador — inicios de upload */
  userUploadInitPerHour: 60,
  /** Por IP — webhook de pagamento */
  webhookPerMinute: 40,
} as const;
