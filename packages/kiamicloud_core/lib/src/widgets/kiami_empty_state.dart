import 'package:flutter/material.dart';

import '../theme/kiami_colors.dart';
import '../theme/kiami_spacing.dart';
import 'kiami_button.dart';

/// Estado vazio premium reutilizável.
class KiamiEmptyState extends StatelessWidget {
  const KiamiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = iconColor ?? KiamiColors.primaryBlue;
    final iconSize = compact ? 44.0 : 56.0;
    final pad = compact ? KiamiSpacing.lg : KiamiSpacing.xl;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: KiamiSpacing.lg,
        vertical: pad,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 18 : 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? KiamiColors.darkSurfaceElevated
                  : KiamiColors.softWhite,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: iconSize, color: accent),
          ),
          SizedBox(height: compact ? KiamiSpacing.md : KiamiSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: KiamiSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KiamiColors.textSecondary(context),
                    height: 1.45,
                  ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KiamiSpacing.lg),
            KiamiButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: KiamiButtonVariant.primary,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}
