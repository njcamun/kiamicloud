import 'package:flutter/material.dart';

import '../api/models/kiami_profile.dart';
import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../theme/kiami_spacing.dart';
import '../utils/format_bytes.dart';
import '../utils/kiami_api_limits.dart';
import '../utils/quota_ui.dart';
import 'kiami_card.dart';
import 'storage_help_dialog.dart';

/// Cartão de armazenamento premium (quota + plano).
class KiamiStorageCard extends StatelessWidget {
  const KiamiStorageCard({
    super.key,
    required this.profile,
    this.expanded = false,
    this.onHelpTap,
  });

  final KiamiProfile profile;
  final bool expanded;
  final VoidCallback? onHelpTap;

  @override
  Widget build(BuildContext context) {
    final used = profile.storageUsedBytes;
    final unlimited = !KiamiApiLimits.enforced;
    final quotaBytes = profile.plan.quotaBytes;
    final ratio = unlimited
        ? 0.0
        : (quotaBytes > 0 ? (used / quotaBytes).clamp(0.0, 1.0) : 0.0);
    final percent = profile.quota.usagePercent.toStringAsFixed(1);
    final barColor = QuotaUi.barColor(profile.quota.status);
    final planLabel = profile.plan.name;
    final narrow = MediaQuery.sizeOf(context).width < 400;

    return KiamiCard(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? KiamiSpacing.lg : (narrow ? 14 : KiamiSpacing.md),
        vertical: expanded ? 22 : (narrow ? KiamiSpacing.md : 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: barColor,
                  size: expanded ? 22 : 20,
                ),
              ),
              const SizedBox(width: KiamiSpacing.sm),
              Expanded(
                child: Text(
                  KiamiStrings.storageUsed,
                  style: (expanded
                          ? Theme.of(context).textTheme.headlineSmall
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      KiamiColors.primaryBlue.withValues(alpha: 0.14),
                      KiamiColors.cloudBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(KiamiDecorations.radiusFull),
                ),
                child: Text(
                  planLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KiamiColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (onHelpTap != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: KiamiStrings.storageHelpTooltip,
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  onPressed: onHelpTap,
                ),
              ],
            ],
          ),
          const SizedBox(height: KiamiSpacing.md),
          if (!unlimited)
            ClipRRect(
              borderRadius: BorderRadius.circular(KiamiDecorations.radiusFull),
              child: ratio == 0
                  ? LinearProgressIndicator(
                      value: 0,
                      minHeight: expanded ? 12 : 10,
                      backgroundColor: _barTrack(context),
                      color: barColor,
                    )
                  : TweenAnimationBuilder<double>(
                      key: ValueKey('${profile.plan.code}-$quotaBytes-$used'),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: ratio),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: expanded ? 12 : 10,
                          backgroundColor: _barTrack(context),
                          color: barColor,
                        );
                      },
                    ),
            ),
          if (!unlimited) const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                unlimited
                    ? '${formatBytes(used)} · ${KiamiStrings.noTransferLimit}'
                    : '${formatBytes(used)} / ${formatBytes(quotaBytes)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (!unlimited)
                Text(
                  '$percent% ${KiamiStrings.storagePercent}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KiamiColors.textSecondary(context),
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _barTrack(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
        : KiamiColors.lightGray;
  }
}

void showKiamiStorageHelp(BuildContext context) => showStorageHelpDialog(context);
