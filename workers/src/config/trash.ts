/** Dias na lixeira antes do purge automático (cron). */
export const TRASH_RETENTION_DAYS = 30;

/** Ficheiros expirados processados por execução do cron (evita timeout). */
export const TRASH_PURGE_BATCH_SIZE = 50;

/** Máximo de lotes por execução (até 500 ficheiros/dia). */
export const TRASH_PURGE_MAX_BATCHES = 10;
