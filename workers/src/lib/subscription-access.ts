import { NO_CHECKOUT_PLAN_CODES } from '../config/plans';
import {
  GRACE_PERIOD_DAYS,
  RESTRICTED_AFTER_DAYS,
  SUSPENDED_AFTER_DAYS,
  type SubscriptionStatus,
} from '../config/subscriptions';
import { isLocalUnlimitedMode } from './local_unlimited';

export type SubscriptionAccessDto = {
  canUpload: boolean;
  canDownload: boolean;
  canShare: boolean;
  status: SubscriptionStatus;
  effectiveStatus: SubscriptionStatus;
  blockReason: string | null;
  storageOverQuota: boolean;
};

export type SubscriptionRowLite = {
  status: string;
  ends_at: string | null;
  grace_period_ends_at: string | null;
  deletion_scheduled_at: string | null;
};

function daysSince(iso: string, nowMs: number): number {
  const t = new Date(iso).getTime();
  if (!Number.isFinite(t)) return 0;
  return Math.floor((nowMs - t) / 86_400_000);
}

/** Calcula estado efectivo com base em datas (mesmo entre execuções do cron). */
export function computeEffectiveStatus(
  row: SubscriptionRowLite | null,
  planCode: string,
  nowMs = Date.now(),
): SubscriptionStatus {
  if (!row) {
    return NO_CHECKOUT_PLAN_CODES.has(planCode) ? 'active' : 'expired';
  }

  const terminal = new Set(['cancelled', 'deleted']);
  if (terminal.has(row.status)) {
    return row.status as SubscriptionStatus;
  }

  if (!row.ends_at) {
    return row.status === 'active' || row.status === 'grace_period'
      ? 'active'
      : (row.status as SubscriptionStatus);
  }

  const endsMs = new Date(row.ends_at).getTime();
  if (Number.isFinite(endsMs) && endsMs > nowMs) {
    return 'active';
  }

  const past = daysSince(row.ends_at, nowMs);
  if (past <= GRACE_PERIOD_DAYS) return 'grace_period';
  if (past <= RESTRICTED_AFTER_DAYS) return 'restricted';
  if (past <= SUSPENDED_AFTER_DAYS) return 'suspended';
  return 'pending_deletion';
}

export function accessFromEffectiveStatus(
  effectiveStatus: SubscriptionStatus,
  storageOverQuota: boolean,
): SubscriptionAccessDto {
  if (storageOverQuota) {
    return {
      canUpload: false,
      canDownload: true,
      canShare: true,
      status: effectiveStatus,
      effectiveStatus,
      blockReason: 'storage_over_quota',
      storageOverQuota: true,
    };
  }

  switch (effectiveStatus) {
    case 'active':
    case 'grace_period':
      return {
        canUpload: true,
        canDownload: true,
        canShare: true,
        status: effectiveStatus,
        effectiveStatus,
        blockReason: null,
        storageOverQuota: false,
      };
    case 'restricted':
      return {
        canUpload: false,
        canDownload: true,
        canShare: true,
        status: effectiveStatus,
        effectiveStatus,
        blockReason: 'subscription_restricted',
        storageOverQuota: false,
      };
    case 'suspended':
    case 'pending_deletion':
      return {
        canUpload: false,
        canDownload: false,
        canShare: false,
        status: effectiveStatus,
        effectiveStatus,
        blockReason: 'subscription_suspended',
        storageOverQuota: false,
      };
    case 'deleted':
      return {
        canUpload: false,
        canDownload: false,
        canShare: false,
        status: 'deleted',
        effectiveStatus: 'deleted',
        blockReason: 'subscription_deleted',
        storageOverQuota: false,
      };
    default:
      return {
        canUpload: false,
        canDownload: false,
        canShare: false,
        status: effectiveStatus,
        effectiveStatus,
        blockReason: 'subscription_inactive',
        storageOverQuota: false,
      };
  }
}

export function resolveAccess(
  input: {
    planCode: string;
    storageUsedBytes: number;
    quotaBytes: number;
    subscription: SubscriptionRowLite | null;
    environment?: string;
  },
): SubscriptionAccessDto {
  if (isLocalUnlimitedMode(input.environment)) {
    return {
      canUpload: true,
      canDownload: true,
      canShare: true,
      status: 'active',
      effectiveStatus: 'active',
      blockReason: null,
      storageOverQuota: false,
    };
  }

  const storageOverQuota =
    input.quotaBytes > 0 && input.storageUsedBytes > input.quotaBytes;
  const effective = computeEffectiveStatus(
    input.subscription,
    input.planCode,
  );
  return accessFromEffectiveStatus(effective, storageOverQuota);
}

export function subscriptionBlockMessage(blockReason: string | null): string {
  switch (blockReason) {
    case 'storage_over_quota':
      return 'O espaço utilizado excede o limite do plano actual. Remova ficheiros ou actualize a subscrição.';
    case 'subscription_restricted':
      return 'Subscrição em atraso: novos uploads bloqueados. Renove o plano para continuar.';
    case 'subscription_suspended':
      return 'Conta suspensa por falta de pagamento. Renove para recuperar acesso.';
    case 'subscription_deleted':
      return 'Conta eliminada.';
    default:
      return 'Operação não permitida no estado actual da subscrição.';
  }
}
