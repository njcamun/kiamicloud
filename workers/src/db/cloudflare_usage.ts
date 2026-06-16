import { estimateCloudflareCosts } from '../config/cloudflare_pricing';

export type CloudflareUsageDto = {
  periodDays: number;
  workers: {
    requestsEstimateMonth: number;
    cpuMsEstimateMonth: number;
    summary: string;
  };
  d1: {
    storageBytes: number;
    rowsReadEstimateMonth: number;
    rowsWrittenEstimateMonth: number;
    summary: string;
  };
  r2: {
    storageBytes: number;
    classAOpsEstimateMonth: number;
    classBOpsEstimateMonth: number;
    summary: string;
  };
  costEstimateUsd: {
    workers: number;
    d1: number;
    r2: number;
    basePlan: number;
    total: number;
  };
  disclaimer: string;
};

/** D1 não expõe pragma_page_count/dbstat — estimativa a partir das tabelas. */
async function estimateD1StorageBytes(db: D1Database): Promise<number> {
  const row = await db
    .prepare(
      `SELECT
         (SELECT COUNT(*) FROM users) * 640 +
         (SELECT COUNT(*) FROM files) * 960 +
         (SELECT COUNT(*) FROM file_actions) * 220 +
         (SELECT COUNT(*) FROM beta_feedback) * 512 +
         (SELECT COUNT(*) FROM payment_checkouts) * 400 +
         (SELECT COUNT(*) FROM plans) * 120 +
         65536 AS d1_storage_bytes`,
    )
    .first<{ d1_storage_bytes: number }>();
  return Math.max(0, row?.d1_storage_bytes ?? 0);
}

export async function getCloudflareUsageEstimate(
  db: D1Database,
): Promise<CloudflareUsageDto> {
  const periodDays = 30;

  const activity = await db
    .prepare(
      `SELECT
         (SELECT COUNT(*) FROM file_actions
          WHERE created_at >= datetime('now', '-30 days')) AS actions_30d,
         (SELECT COUNT(*) FROM file_actions
          WHERE action = 'upload' AND created_at >= datetime('now', '-30 days')) AS uploads_30d,
         (SELECT COUNT(*) FROM file_actions
          WHERE action = 'download' AND created_at >= datetime('now', '-30 days')) AS downloads_30d,
         (SELECT COUNT(*) FROM users) AS users_count,
         (SELECT COUNT(*) FROM files
          WHERE status = 'active' AND deleted_at IS NULL) AS active_files,
         (SELECT COALESCE(SUM(size_bytes), 0) FROM files
          WHERE status = 'active' AND deleted_at IS NULL) AS r2_storage_bytes`,
    )
    .first<{
      actions_30d: number;
      uploads_30d: number;
      downloads_30d: number;
      users_count: number;
      active_files: number;
      r2_storage_bytes: number;
    }>();

  const actions30d = activity?.actions_30d ?? 0;
  const uploads30d = activity?.uploads_30d ?? 0;
  const downloads30d = activity?.downloads_30d ?? 0;
  const usersCount = activity?.users_count ?? 0;
  const activeFiles = activity?.active_files ?? 0;
  const r2StorageBytes = activity?.r2_storage_bytes ?? 0;
  const d1StorageBytes = await estimateD1StorageBytes(db);

  // Heurística mensal a partir da actividade observada (não é a fatura oficial CF).
  const requestsEstimateMonth = Math.round(
    actions30d * 12 + usersCount * 400 + activeFiles * 25 + 5000,
  );
  const cpuMsEstimateMonth = Math.round(requestsEstimateMonth * 12);
  const rowsReadEstimateMonth = Math.round(requestsEstimateMonth * 18);
  const rowsWrittenEstimateMonth = Math.round(
    uploads30d * 8 + actions30d * 3 + usersCount * 2,
  );
  const classAOpsEstimateMonth = Math.round(uploads30d * 2 + actions30d * 0.2);
  const classBOpsEstimateMonth = Math.round(downloads30d * 1.2 + activeFiles * 2);

  const costs = estimateCloudflareCosts({
    requestsMonth: requestsEstimateMonth,
    cpuMsMonth: cpuMsEstimateMonth,
    d1StorageBytes,
    d1RowsReadMonth: rowsReadEstimateMonth,
    d1RowsWrittenMonth: rowsWrittenEstimateMonth,
    r2StorageBytes,
    r2ClassAMonth: classAOpsEstimateMonth,
    r2ClassBMonth: classBOpsEstimateMonth,
  });

  return {
    periodDays,
    workers: {
      requestsEstimateMonth,
      cpuMsEstimateMonth,
      summary:
        'Pedidos HTTP ao Worker e tempo de CPU por invocação. Subrequests internos não contam como pedido extra.',
    },
    d1: {
      storageBytes: d1StorageBytes,
      rowsReadEstimateMonth,
      rowsWrittenEstimateMonth,
      summary:
        'Base de metadados D1: linhas lidas/escritas por consulta e armazenamento total da base.',
    },
    r2: {
      storageBytes: r2StorageBytes,
      classAOpsEstimateMonth,
      classBOpsEstimateMonth,
      summary:
        'Ficheiros na cloud: armazenamento (GB-mês), operações de escrita (classe A) e leitura (classe B). Egress gratuito.',
    },
    costEstimateUsd: {
      workers: costs.workersUsd,
      d1: costs.d1Usd,
      r2: costs.r2Usd,
      basePlan: costs.basePlanUsd,
      total: costs.totalUsd,
    },
    disclaimer:
      'Estimativa com base na actividade KiamiCloud (últimos 30 dias) e tabela pública Cloudflare. A fatura real pode diferir — consulte o dashboard Cloudflare.',
  };
}
