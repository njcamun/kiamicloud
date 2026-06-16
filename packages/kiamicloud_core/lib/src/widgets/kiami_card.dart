import 'package:flutter/material.dart';

import '../theme/kiami_decorations.dart';

/// Card minimalista com sombra suave (identidade KiamiCloud).
class KiamiCard extends StatelessWidget {
  const KiamiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.margin,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = radius ?? KiamiDecorations.radiusLg;

    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: isDark
          ? KiamiDecorations.cardDark(radius: r)
          : KiamiDecorations.cardLight(radius: r),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: content,
        ),
      );
    }

    return content;
  }
}
