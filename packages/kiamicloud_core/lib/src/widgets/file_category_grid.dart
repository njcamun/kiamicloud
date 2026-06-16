import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../theme/kiami_colors.dart';
import 'category_illustration.dart';
import '../theme/kiami_decorations.dart';
import '../utils/file_category.dart';
import '../utils/kiami_layout.dart';
import '../utils/kiami_platform.dart';

/// Grelha com um card por categoria (imagens oficiais PNG + contagem).
class FileCategoryGrid extends StatelessWidget {
  const FileCategoryGrid({
    super.key,
    required this.grouped,
    required this.onCategoryTap,
  });

  final Map<KiamiFileCategory, List<KiamiFile>> grouped;
  final ValueChanged<KiamiFileCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = kiamiContentWidth(context, constraints);
        final nativeDesktop = kiamiIsNativeDesktop();
        final crossAxisCount =
            kiamiCategoryGridCrossAxisCount(width, nativeDesktop: nativeDesktop);
        final aspectRatio = _aspectRatio(width, nativeDesktop, crossAxisCount);
        final spacing = nativeDesktop ? 18.0 : 14.0;
        final cacheWidth = (width / crossAxisCount *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(200, 720);

        final grid = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: KiamiFileCategory.displayOrder.length,
      itemBuilder: (context, index) {
        final category = KiamiFileCategory.displayOrder[index];
        final count = grouped[category]?.length ?? 0;

        return _FileCategoryCard(
          category: category,
          count: count,
          cacheWidth: cacheWidth,
          onTap: () => onCategoryTap(category),
        );
      },
    );

    final maxW = kiamiContentMaxWidth(context);
    if (maxW == null) return grid;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: grid,
      ),
    );
      },
    );
  }

  double _aspectRatio(double width, bool nativeDesktop, int columns) {
    if (nativeDesktop && columns == 3) {
      return width >= 1400 ? 1.18 : 1.08;
    }
    if (width >= 900) return 0.92;
    if (width < 360) return 0.82;
    if (width < 400) return 0.85;
    return 0.88;
  }
}

class _FileCategoryCard extends StatelessWidget {
  const _FileCategoryCard({
    required this.category,
    required this.count,
    required this.cacheWidth,
    required this.onTap,
  });

  final KiamiFileCategory category;
  final int count;
  final int cacheWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0;
    final radius = kiamiIsNativeDesktop()
        ? KiamiDecorations.radiusXl
        : KiamiDecorations.radiusLg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isEmpty ? 0.72 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: KiamiColors.deepBlue.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: KiamiColors.deepBlue.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CategoryIllustration(
                  category: category,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _CountBadge(count: count),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          KiamiColors.deepBlue.withValues(alpha: 0.82),
                          KiamiColors.deepBlue.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                      child: Text(
                        category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: kiamiIsNativeDesktop() ? 15 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: KiamiColors.deepBlue.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: KiamiColors.primaryBlue,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          height: 1,
        ),
      ),
    );
  }
}
