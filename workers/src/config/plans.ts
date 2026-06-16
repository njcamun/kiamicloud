/** Limites e planos — espelho de docs/PLANOS.md */
const MB = 1024 * 1024;
const GB = 1024 * 1024 * 1024;

/** Desconto cobrado a partir do Plus (preço = tabela × 0,85). */
export const PLAN_PRICE_DISCOUNT = 0.15;

/** Tecto global (plano Plus e superiores: 150 MB/ficheiro). */
export const MAX_FILE_SIZE_BYTES = 150 * MB;

export const DEFAULT_PLAN_CODE = 'basico' as const;

/** Planos sem checkout (gratuito). */
export const NO_CHECKOUT_PLAN_CODES = new Set<string>(['basico']);

export type PlanCode =
  | 'basico'
  | 'basico_plus'
  | 'plus'
  | 'start'
  | 'premium'
  | 'pro'
  | 'ultra';

export type PlanDefinition = {
  code: PlanCode;
  name: string;
  quotaBytes: number;
  /** Preço cobrado (Kz/mês). Plus+ = tabela −15%. */
  priceKzMonth: number;
  maxFileSizeBytes: number;
  /** Preço de tabela antes do desconto (só Plus+). */
  listPriceKzMonth: number;
};

/** Preços de tabela (escada ×2 desde Básico+). */
const LIST_PRICE_KZ: Record<PlanCode, number> = {
  basico: 0,
  basico_plus: 1500,
  plus: 3000,
  start: 6000,
  premium: 12000,
  pro: 24000,
  ultra: 48000,
};

function chargedFromList(listKz: number, code: PlanCode): number {
  if (listKz <= 0) return 0;
  if (code === 'basico' || code === 'basico_plus') return listKz;
  return Math.round(listKz * (1 - PLAN_PRICE_DISCOUNT));
}

function buildPlan(
  code: PlanCode,
  name: string,
  quotaBytes: number,
  maxFileSizeBytes: number,
): PlanDefinition {
  const listPriceKzMonth = LIST_PRICE_KZ[code];
  return {
    code,
    name,
    quotaBytes,
    priceKzMonth: chargedFromList(listPriceKzMonth, code),
    maxFileSizeBytes,
    listPriceKzMonth,
  };
}

/** Referencia estatica (fonte de verdade: tabela D1 `plans`). */
export const PLANS: readonly PlanDefinition[] = [
  buildPlan('basico', 'Básico', 20 * GB, 15 * MB),
  buildPlan('basico_plus', 'Básico+', 20 * GB, 75 * MB),
  buildPlan('plus', 'Plus', 40 * GB, 150 * MB),
  buildPlan('start', 'Start', 80 * GB, 150 * MB),
  buildPlan('premium', 'Premium', 160 * GB, 150 * MB),
  buildPlan('pro', 'Pro', 320 * GB, 150 * MB),
  buildPlan('ultra', 'Ultra', 500 * GB, 150 * MB),
] as const;

export function getPlanByCode(code: string): PlanDefinition | undefined {
  return PLANS.find((p) => p.code === code);
}

export function getMaxFileSizeForPlan(planCode: string): number {
  return getPlanByCode(planCode)?.maxFileSizeBytes ?? 15 * MB;
}

/** Preço de tabela a partir do preço cobrado (inverso do desconto 15%). */
export function listPriceKzFromCharged(chargedKz: number): number {
  if (chargedKz <= 0) return 0;
  return Math.round(chargedKz / (1 - PLAN_PRICE_DISCOUNT));
}

export function formatMaxFileSizeLabel(bytes: number): string {
  if (bytes >= MB && bytes % MB === 0) {
    return `${bytes / MB} MB`;
  }
  return `${bytes} bytes`;
}

export function formatMaxFileSizeMessage(maxBytes: number): string {
  return `Ficheiro excede o limite do teu plano (${formatMaxFileSizeLabel(maxBytes)}).`;
}
