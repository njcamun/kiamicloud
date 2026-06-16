import 'package:flutter/material.dart';

import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';

enum KiamiButtonVariant { primary, secondary, ghost }

/// Botao reutilizavel — primario com gradiente e glow subtil.
class KiamiButton extends StatelessWidget {
  const KiamiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KiamiButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final KiamiButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    final labelRow = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == KiamiButtonVariant.primary
                  ? Colors.white
                  : KiamiColors.primaryBlue,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    Widget button = switch (variant) {
      KiamiButtonVariant.primary => _PrimaryGradientButton(
          onPressed: enabled ? onPressed : null,
          child: labelRow,
          glow: enabled,
        ),
      KiamiButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          child: labelRow,
        ),
      KiamiButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(foregroundColor: KiamiColors.primaryBlue),
          child: labelRow,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.onPressed,
    required this.child,
    required this.glow,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: glow ? KiamiColors.brandGradient : null,
        color: glow ? null : KiamiColors.primaryBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        boxShadow: glow ? KiamiDecorations.primaryGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
