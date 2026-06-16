import 'package:flutter/material.dart';

/// Paleta oficial KiamiCloud (espelha branding/design_tokens.json).
abstract final class KiamiColors {
  static const Color deepBlue = Color(0xFF0D1B2A);
  static const Color primaryBlue = Color(0xFF1565FF);
  static const Color cloudBlue = Color(0xFF00C2FF);
  static const Color softWhite = Color(0xFFE6F2FF);
  static const Color lightGray = Color(0xFFF2F4F7);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Dark surfaces
  static const Color darkBackground = deepBlue;
  static const Color darkSurface = Color(0xFF1B2838);
  static const Color darkSurfaceElevated = Color(0xFF243447);
  static const Color darkTextPrimary = softWhite;
  /// Secundário legível em superfícies escuras (contraste ~4.8:1).
  static const Color darkTextSecondary = Color(0xFFB0BECD);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  // Light surfaces
  static const Color lightBackground = lightGray;
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = deepBlue;
  static const Color lightTextSecondary = Color(0xFF64748B);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryBlue, cloudBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
