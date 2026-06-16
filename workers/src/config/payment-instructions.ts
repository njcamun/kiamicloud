/** Instruções de pagamento manual (MB Way / transferência). */
export const PAYMENT_INSTRUCTIONS = {
  holderName: 'KiamiCloud',
  iban: '0000 0000 0000 0000 0000 0',
  mbWay: '900 000 000',
  note:
    'Inclua sempre a referência KIA-… na descrição da transferência ou no comprovativo.',
  reviewSlaHours: 6,
} as const;

export type PaymentInstructionsDto = typeof PAYMENT_INSTRUCTIONS;
