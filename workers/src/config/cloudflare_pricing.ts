/** Preços indicativos Cloudflare Developer Platform (Workers Paid + D1 + R2). */
export const CF_PRICING = {
  workersBaseUsd: 5,
  workersIncludedRequests: 10_000_000,
  workersPerMillionRequestsUsd: 0.3,
  workersIncludedCpuMs: 30_000_000,
  workersPerMillionCpuMsUsd: 0.02,
  d1IncludedStorageGb: 5,
  d1PerGbMonthUsd: 0.75,
  d1IncludedRowsRead: 25_000_000_000,
  d1PerMillionRowsReadUsd: 0.001,
  d1IncludedRowsWritten: 50_000_000,
  d1PerMillionRowsWrittenUsd: 1.0,
  r2IncludedStorageGb: 10,
  r2PerGbMonthUsd: 0.015,
  r2IncludedClassA: 1_000_000,
  r2PerMillionClassAUsd: 4.5,
  r2IncludedClassB: 10_000_000,
  r2PerMillionClassBUsd: 0.36,
} as const;

export type CloudflareCostBreakdown = {
  workersUsd: number;
  d1Usd: number;
  r2Usd: number;
  basePlanUsd: number;
  totalUsd: number;
};

export function estimateCloudflareCosts(input: {
  requestsMonth: number;
  cpuMsMonth: number;
  d1StorageBytes: number;
  d1RowsReadMonth: number;
  d1RowsWrittenMonth: number;
  r2StorageBytes: number;
  r2ClassAMonth: number;
  r2ClassBMonth: number;
}): CloudflareCostBreakdown {
  const extraRequests = Math.max(
    0,
    input.requestsMonth - CF_PRICING.workersIncludedRequests,
  );
  const extraCpu = Math.max(
    0,
    input.cpuMsMonth - CF_PRICING.workersIncludedCpuMs,
  );
  const workersVariable =
    (extraRequests / 1_000_000) * CF_PRICING.workersPerMillionRequestsUsd +
    (extraCpu / 1_000_000) * CF_PRICING.workersPerMillionCpuMsUsd;

  const d1Gb = input.d1StorageBytes / (1024 * 1024 * 1024);
  const d1StorageExtra = Math.max(0, d1Gb - CF_PRICING.d1IncludedStorageGb);
  const d1ReadExtra = Math.max(
    0,
    input.d1RowsReadMonth - CF_PRICING.d1IncludedRowsRead,
  );
  const d1WriteExtra = Math.max(
    0,
    input.d1RowsWrittenMonth - CF_PRICING.d1IncludedRowsWritten,
  );
  const d1Usd =
    d1StorageExtra * CF_PRICING.d1PerGbMonthUsd +
    (d1ReadExtra / 1_000_000) * CF_PRICING.d1PerMillionRowsReadUsd +
    (d1WriteExtra / 1_000_000) * CF_PRICING.d1PerMillionRowsWrittenUsd;

  const r2Gb = input.r2StorageBytes / (1024 * 1024 * 1024);
  const r2StorageExtra = Math.max(0, r2Gb - CF_PRICING.r2IncludedStorageGb);
  const r2AExtra = Math.max(0, input.r2ClassAMonth - CF_PRICING.r2IncludedClassA);
  const r2BExtra = Math.max(0, input.r2ClassBMonth - CF_PRICING.r2IncludedClassB);
  const r2Usd =
    r2StorageExtra * CF_PRICING.r2PerGbMonthUsd +
    (r2AExtra / 1_000_000) * CF_PRICING.r2PerMillionClassAUsd +
    (r2BExtra / 1_000_000) * CF_PRICING.r2PerMillionClassBUsd;

  const basePlanUsd = CF_PRICING.workersBaseUsd;
  const totalUsd = basePlanUsd + workersVariable + d1Usd + r2Usd;

  return {
    workersUsd: Math.round((basePlanUsd + workersVariable) * 100) / 100,
    d1Usd: Math.round(d1Usd * 100) / 100,
    r2Usd: Math.round(r2Usd * 100) / 100,
    basePlanUsd,
    totalUsd: Math.round(totalUsd * 100) / 100,
  };
}
