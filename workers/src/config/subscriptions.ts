/** Período de subscrição paga (renovação). */
export const SUBSCRIPTION_PERIOD_DAYS = 30;

/** Dias após `ends_at` em que o upload continua permitido. */
export const GRACE_PERIOD_DAYS = 7;

/** Dias após `ends_at` até estado RESTRICTED (upload bloqueado). */
export const RESTRICTED_AFTER_DAYS = 30;

/** Dias após `ends_at` até estado SUSPENDED (download bloqueado). */
export const SUSPENDED_AFTER_DAYS = 90;

/** Dias de aviso antes da eliminação após `pending_deletion`. */
export const DELETION_NOTICE_DAYS = 15;

/** Lembretes de renovação (dias antes de `ends_at`). */
export const RENEWAL_REMINDER_DAYS = [15, 7, 3, 1, 0] as const;

/** Avisos antes da eliminação (dias antes de `deletion_scheduled_at`). */
export const DELETION_REMINDER_DAYS = [15, 7, 3, 1] as const;

export type SubscriptionStatus =
  | 'active'
  | 'grace_period'
  | 'restricted'
  | 'suspended'
  | 'pending_deletion'
  | 'deleted'
  | 'cancelled'
  | 'expired'
  | 'past_due';
