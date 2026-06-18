import 'package:flutter/material.dart';

import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../theme/kiami_spacing.dart';

/// Campo de pesquisa arredondado premium.
class KiamiSearchBar extends StatelessWidget {
  const KiamiSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return Material(
          color: Colors.transparent,
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hintText ?? KiamiStrings.dashboardSearchHint,
              filled: true,
              fillColor: isDark
                  ? KiamiColors.darkSurfaceElevated
                  : KiamiColors.lightSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KiamiSpacing.md,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: KiamiColors.textSecondary(context),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                        onClear?.call();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KiamiDecorations.radiusCard),
                borderSide: BorderSide(
                  color: isDark
                      ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
                      : KiamiColors.deepBlue.withValues(alpha: 0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KiamiDecorations.radiusCard),
                borderSide: BorderSide(
                  color: isDark
                      ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
                      : KiamiColors.deepBlue.withValues(alpha: 0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KiamiDecorations.radiusCard),
                borderSide: const BorderSide(
                  color: KiamiColors.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
