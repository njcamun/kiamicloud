import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../theme/kiami_spacing.dart';
import '../utils/format_bytes.dart';
import 'kiami_file_thumbnail.dart';

/// Secção horizontal de ficheiros recentes no dashboard.
class KiamiRecentFilesRow extends StatelessWidget {
  const KiamiRecentFilesRow({
    super.key,
    required this.files,
    required this.onFileTap,
    this.maxItems = 12,
  });

  final List<KiamiFile> files;
  final ValueChanged<KiamiFile> onFileTap;
  final int maxItems;

  static List<KiamiFile> pickRecent(List<KiamiFile> all, {int max = 12}) {
    final sorted = [...all]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(max).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: KiamiSpacing.sm),
          child: Text(
            KiamiStrings.dashboardRecent,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: files.length.clamp(0, maxItems),
            separatorBuilder: (_, __) => const SizedBox(width: KiamiSpacing.sm),
            itemBuilder: (context, index) {
              final file = files[index];
              return _RecentFileCard(
                file: file,
                onTap: () => onFileTap(file),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentFileCard extends StatelessWidget {
  const _RecentFileCard({
    required this.file,
    required this.onTap,
  });

  final KiamiFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
        child: Ink(
          width: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
            color: isDark
                ? KiamiColors.darkSurfaceElevated
                : KiamiColors.lightSurface,
            border: Border.all(
              color: isDark
                  ? KiamiColors.cloudBlue.withValues(alpha: 0.1)
                  : KiamiColors.deepBlue.withValues(alpha: 0.05),
            ),
            boxShadow: isDark ? null : KiamiDecorations.cardShadowLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(KiamiDecorations.radiusLg),
                  ),
                  child: KiamiFileThumbnail(
                    file: file,
                    height: 72,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      formatBytes(file.sizeBytes),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: KiamiColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
