import 'package:flutter/material.dart';

import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../theme/kiami_spacing.dart';
import '../utils/file_category.dart';
import 'category_illustration.dart';

/// Banner compacto no topo das listas por categoria.
class KiamiCategoryBanner extends StatelessWidget {
  const KiamiCategoryBanner({
    super.key,
    required this.category,
    required this.fileCount,
  });

  final KiamiFileCategory category;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
        boxShadow: KiamiDecorations.cardShadowLight,
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 112,
            width: double.infinity,
            child: CategoryIllustration(
              category: category,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    KiamiColors.deepBlue.withValues(alpha: 0.72),
                    KiamiColors.deepBlue.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: KiamiSpacing.md,
            right: KiamiSpacing.md,
            bottom: KiamiSpacing.md,
            child: Row(
              children: [
                Icon(category.icon, color: Colors.white, size: 28),
                const SizedBox(width: KiamiSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        KiamiStrings.categoryFileCount(fileCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
