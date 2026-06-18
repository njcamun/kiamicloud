import 'package:flutter/material.dart';

import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../theme/kiami_spacing.dart';
import 'kiami_card.dart';

/// Placeholder animado para carregamento premium.
class KiamiSkeletonBox extends StatefulWidget {
  const KiamiSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<KiamiSkeletonBox> createState() => _KiamiSkeletonBoxState();
}

class _KiamiSkeletonBoxState extends State<KiamiSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? KiamiColors.darkSurfaceElevated
        : KiamiColors.lightGray;
    final highlight = isDark
        ? KiamiColors.cloudBlue.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(KiamiDecorations.radiusMd),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton do cartão de armazenamento.
class KiamiStorageCardSkeleton extends StatelessWidget {
  const KiamiStorageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return KiamiCard(
      padding: const EdgeInsets.all(KiamiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KiamiSkeletonBox(
                width: 28,
                height: 28,
                borderRadius: BorderRadius.circular(KiamiDecorations.radiusSm),
              ),
              const SizedBox(width: KiamiSpacing.sm),
              const Expanded(
                child: KiamiSkeletonBox(
                  width: double.infinity,
                  height: 18,
                ),
              ),
              const SizedBox(width: KiamiSpacing.sm),
              KiamiSkeletonBox(
                width: 64,
                height: 24,
                borderRadius: BorderRadius.circular(KiamiDecorations.radiusFull),
              ),
            ],
          ),
          const SizedBox(height: KiamiSpacing.md),
          const KiamiSkeletonBox(
            width: double.infinity,
            height: 10,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          const SizedBox(height: KiamiSpacing.sm),
          const KiamiSkeletonBox(width: 140, height: 14),
        ],
      ),
    );
  }
}

/// Grelha skeleton para listagens.
class KiamiFileGridSkeleton extends StatelessWidget {
  const KiamiFileGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  final int itemCount;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: KiamiSpacing.md,
        crossAxisSpacing: KiamiSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: KiamiSkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.all(
                  Radius.circular(KiamiDecorations.radiusLg),
                ),
              ),
            ),
            const SizedBox(height: KiamiSpacing.sm),
            const KiamiSkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 4),
            const KiamiSkeletonBox(width: 72, height: 12),
          ],
        );
      },
    );
  }
}
