import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/kiami_admin.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../../utils/format_bytes.dart';
import '../../../utils/format_compact_number.dart';
import '../../files/providers/files_providers.dart';
import '../providers/admin_providers.dart';

class AdminCloudflareUsageSection extends ConsumerWidget {
  const AdminCloudflareUsageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(adminCloudflareUsageProvider);

    return usageAsync.when(
      data: (usage) => _CloudflareUsageBody(usage: usage),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            KiamiStrings.adminCfUsageTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (e, _) => Card(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                KiamiStrings.adminCfUsageTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(kiamiApiErrorMessage(e)),
              const SizedBox(height: 8),
              Text(
                KiamiStrings.adminCfLoadHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloudflareUsageBody extends StatelessWidget {
  const _CloudflareUsageBody({required this.usage});

  final KiamiCloudflareUsage usage;

  void _showMetricInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(KiamiStrings.closeButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = usage.workers;
    final d1 = usage.d1;
    final r2 = usage.r2;
    final cost = usage.costEstimateUsd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                KiamiStrings.adminCfUsageTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              KiamiStrings.adminCfTapForInfo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CfMetricCard(
                  icon: Icons.cloud_outlined,
                  title: KiamiStrings.adminCfWorkers,
                  lines: [
                    '${KiamiStrings.adminCfWorkersValue}: '
                    '${formatCompactCount(w.requestsEstimateMonth)}',
                    '${KiamiStrings.adminCfWorkersCpu}: '
                    '${formatCompactCount(w.cpuMsEstimateMonth)} ms',
                  ],
                  onTap: () => _showMetricInfo(
                    context,
                    KiamiStrings.adminCfWorkers,
                    '${w.summary}\n\n'
                    'Nesta estimativa: ${formatCompactCount(w.requestsEstimateMonth)} pedidos '
                    'e ${formatCompactCount(w.cpuMsEstimateMonth)} ms de CPU por mês, '
                    'projectados a partir da actividade dos últimos ${usage.periodDays} dias.',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CfMetricCard(
                  icon: Icons.table_chart_outlined,
                  title: KiamiStrings.adminCfD1,
                  lines: [
                    '${KiamiStrings.adminCfD1Storage}: ${formatBytes(d1.storageBytes)}',
                    '${KiamiStrings.adminCfD1Reads}: '
                    '${formatCompactCount(d1.rowsReadEstimateMonth)}',
                    '${KiamiStrings.adminCfD1Writes}: '
                    '${formatCompactCount(d1.rowsWrittenEstimateMonth)}',
                  ],
                  onTap: () => _showMetricInfo(
                    context,
                    KiamiStrings.adminCfD1,
                    '${d1.summary}\n\n'
                    'Armazenamento actual da base: ${formatBytes(d1.storageBytes)}.\n'
                    'Leituras estimadas/mês: ${formatCompactCount(d1.rowsReadEstimateMonth)}.\n'
                    'Escritas estimadas/mês: ${formatCompactCount(d1.rowsWrittenEstimateMonth)}.',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _CfMetricCard(
          icon: Icons.folder_special_outlined,
          title: KiamiStrings.adminCfR2,
          lines: [
            '${KiamiStrings.adminCfR2Storage}: ${formatBytes(r2.storageBytes)}',
            '${KiamiStrings.adminCfR2ClassA}: '
            '${formatCompactCount(r2.classAOpsEstimateMonth)}',
            '${KiamiStrings.adminCfR2ClassB}: '
            '${formatCompactCount(r2.classBOpsEstimateMonth)}',
          ],
          onTap: () => _showMetricInfo(
            context,
            KiamiStrings.adminCfR2,
            '${r2.summary}\n\n'
            'Armazenamento (ficheiros activos): ${formatBytes(r2.storageBytes)}.\n'
            'Operações classe A (upload/escrita): '
            '${formatCompactCount(r2.classAOpsEstimateMonth)}/mês.\n'
            'Operações classe B (download/leitura): '
            '${formatCompactCount(r2.classBOpsEstimateMonth)}/mês.',
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: KiamiColors.primaryBlue.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => _showMetricInfo(
              context,
              KiamiStrings.adminCfCostTitle,
              '${usage.disclaimer}\n\n'
              'Workers: ${cost.workers.toStringAsFixed(2)} USD '
              '(plano base ${cost.basePlan.toStringAsFixed(0)} USD + uso extra).\n'
              'D1: ${cost.d1.toStringAsFixed(2)} USD além do incluído.\n'
              'R2: ${cost.r2.toStringAsFixed(2)} USD além do incluído.\n\n'
              'Tabela de referência: pedidos, CPU, linhas D1, GB R2 — '
              'conforme documentação Cloudflare Developer Platform.',
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          color: KiamiColors.primaryBlue, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        KiamiStrings.adminCfCostTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${cost.total.toStringAsFixed(2)} USD',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: KiamiColors.primaryBlue,
                    ),
                  ),
                  Text(
                    KiamiStrings.adminCfCostTotal,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _CostLine(
                    label: KiamiStrings.adminCfCostWorkers,
                    value: '${cost.workers.toStringAsFixed(2)} USD',
                  ),
                  _CostLine(
                    label: KiamiStrings.adminCfCostD1,
                    value: '${cost.d1.toStringAsFixed(2)} USD',
                  ),
                  _CostLine(
                    label: KiamiStrings.adminCfCostR2,
                    value: '${cost.r2.toStringAsFixed(2)} USD',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    usage.disclaimer,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CfMetricCard extends StatelessWidget {
  const _CfMetricCard({
    required this.icon,
    required this.title,
    required this.lines,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: KiamiColors.primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...lines.map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  const _CostLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
