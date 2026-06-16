import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kiami_colors.dart';
import 'kiami_decorations.dart';
import 'kiami_typography.dart';

/// Temas light/dark da KiamiCloud (light prioritario).
abstract final class KiamiTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final onSurface = isDark
        ? KiamiColors.darkTextPrimary
        : KiamiColors.lightTextPrimary;
    final onSurfaceVariant = isDark
        ? KiamiColors.darkTextSecondary
        : KiamiColors.lightTextSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: KiamiColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: KiamiColors.cloudBlue,
      onSecondary: isDark ? KiamiColors.softWhite : KiamiColors.deepBlue,
      error: KiamiColors.error,
      onError: Colors.white,
      surface: isDark ? KiamiColors.darkSurface : KiamiColors.lightSurface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: isDark
          ? KiamiColors.cloudBlue.withValues(alpha: 0.2)
          : KiamiColors.deepBlue.withValues(alpha: 0.12),
    );

    final iconTheme = IconThemeData(
      color: isDark
          ? KiamiColors.darkTextSecondary
          : KiamiColors.lightTextSecondary,
      size: 22,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? KiamiColors.darkBackground
          : KiamiColors.lightBackground,
      textTheme: KiamiTypography.textTheme(brightness),
      iconTheme: iconTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: isDark
            ? KiamiColors.darkSurface
            : KiamiColors.lightSurface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: KiamiTypography.textTheme(brightness).titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark
            ? KiamiColors.darkSurfaceElevated
            : KiamiColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? KiamiColors.darkSurfaceElevated
            : Colors.white,
        hintStyle: TextStyle(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(color: onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: onSurfaceVariant),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
                : KiamiColors.deepBlue.withValues(alpha: 0.08),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
                : KiamiColors.deepBlue.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          borderSide: const BorderSide(color: KiamiColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          borderSide: const BorderSide(color: KiamiColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KiamiColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KiamiColors.primaryBlue,
          backgroundColor: isDark ? Colors.transparent : Colors.white,
          side: BorderSide(
            color: KiamiColors.primaryBlue.withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KiamiColors.primaryBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark
            ? KiamiColors.darkSurface
            : KiamiColors.lightSurface,
        indicatorColor: KiamiColors.primaryBlue.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shadowColor: KiamiColors.deepBlue.withValues(alpha: 0.08),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? KiamiColors.primaryBlue
                : (isDark
                    ? KiamiColors.darkTextSecondary
                    : KiamiColors.lightTextSecondary),
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: KiamiColors.deepBlue,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? KiamiColors.cloudBlue.withValues(alpha: 0.08)
            : KiamiColors.deepBlue.withValues(alpha: 0.06),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark
            ? KiamiColors.cloudBlue.withValues(alpha: 0.85)
            : KiamiColors.primaryBlue,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark
            ? KiamiColors.darkSurfaceElevated
            : KiamiColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? KiamiColors.darkSurfaceElevated
            : KiamiColors.deepBlue,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: KiamiColors.primaryBlue,
        linearTrackColor: isDark
            ? KiamiColors.cloudBlue.withValues(alpha: 0.12)
            : KiamiColors.lightGray,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: KiamiColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
        ),
      ),
    );
  }
}
