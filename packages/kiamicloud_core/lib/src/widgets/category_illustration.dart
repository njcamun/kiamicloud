import 'package:flutter/material.dart';

import '../assets/kiami_assets.dart';
import '../utils/file_category.dart';

/// Ilustracao do card por categoria (PNG; variante escuro quando existir).
class CategoryIllustration extends StatelessWidget {
  const CategoryIllustration({
    super.key,
    required this.category,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
  });

  final KiamiFileCategory category;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primary = category.illustrationAssetFor(brightness);
    final fallback = category.illustrationAssetLight;

    return Image.asset(
      primary,
      package: KiamiAssets.package,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) {
        if (primary == fallback) {
          return _Fallback(category: category);
        }
        return Image.asset(
          fallback,
          package: KiamiAssets.package,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          errorBuilder: (_, __, ___) => _Fallback(category: category),
        );
      },
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.category});

  final KiamiFileCategory category;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: category.accentColor.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          category.icon,
          size: 48,
          color: category.accentColor,
        ),
      ),
    );
  }
}
