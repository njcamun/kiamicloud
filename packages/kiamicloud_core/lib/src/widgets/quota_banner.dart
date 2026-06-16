import 'package:flutter/material.dart';

import '../api/models/kiami_quota.dart';
import '../constants/kiami_strings.dart';
import '../utils/format_bytes.dart';
import '../utils/quota_ui.dart';

class QuotaBanner extends StatelessWidget {
  const QuotaBanner({
    super.key,
    required this.quota,
    required this.storageUsedBytes,
    required this.quotaBytes,
    required this.storageAvailableBytes,
    this.onUpgrade,
  });

  final KiamiQuotaInfo quota;
  final int storageUsedBytes;
  final int quotaBytes;
  final int storageAvailableBytes;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (!QuotaUi.showBanner(quota.status)) return const SizedBox.shrink();

    final message = quota.message ??
        switch (quota.status) {
          QuotaStatus.full => KiamiStrings.quotaFull,
          QuotaStatus.critical => KiamiStrings.quotaCritical,
          QuotaStatus.warning => KiamiStrings.quotaWarning,
          QuotaStatus.ok => '',
        };

    final content = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuotaUi.bannerBackground(quota.status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: QuotaUi.bannerForeground(quota.status).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            QuotaUi.bannerIcon(quota.status),
            color: QuotaUi.bannerForeground(quota.status),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QuotaUi.bannerForeground(quota.status),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatBytes(storageUsedBytes)} / ${formatBytes(quotaBytes)} · '
                  '${KiamiStrings.quotaAvailable}: ${formatBytes(storageAvailableBytes)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QuotaUi.bannerForeground(quota.status)
                            .withValues(alpha: 0.88),
                      ),
                ),
                if (onUpgrade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    KiamiStrings.quotaBannerUpgradeHint,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: QuotaUi.bannerForeground(quota.status)
                              .withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onUpgrade != null)
            Icon(
              Icons.chevron_right_rounded,
              color: QuotaUi.bannerForeground(quota.status),
            ),
        ],
      ),
    );

    if (onUpgrade == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
