import 'package:flutter/material.dart';

import '../constants/kiami_constants.dart';
import '../theme/kiami_decorations.dart';

/// Topbar compacta para area principal do dashboard.
class KiamiPageHeader extends StatelessWidget implements PreferredSizeWidget {  const KiamiPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.largeTitle = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  /// Titulo maior (ex.: nome do utilizador no dashboard).
  final bool largeTitle;

  @override
  Size get preferredSize => Size.fromHeight(
        subtitle != null ? (largeTitle ? 64 : 56) : (largeTitle ? 52 : 44),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide =
        MediaQuery.sizeOf(context).width >= KiamiConstants.breakpointTablet;

    return Material(
      color: scheme.surface.withValues(alpha: 0.95),
      child: Container(
        decoration: KiamiDecorations.topBar(context),
        padding: EdgeInsets.fromLTRB(
          isWide ? 28 : 20,
          isWide ? 10 : 6,
          12,
          isWide ? 10 : 8,
        ),        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) leading!,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (largeTitle
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.titleLarge)
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          letterSpacing: largeTitle ? -0.3 : 0,
                          color: scheme.onSurface,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            height: 1.2,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (actions != null)
              ...actions!.map(
                (action) => IconTheme.merge(
                  data: const IconThemeData(size: 22),
                  child: action,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
