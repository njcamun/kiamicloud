import 'package:flutter/material.dart';

import 'kiami_colors.dart';

/// Sombras, gradientes e decoracao da identidade KiamiCloud.
abstract final class KiamiDecorations {
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 28, vertical: 24);

  static const LinearGradient brandGradient = KiamiColors.brandGradient;

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      KiamiColors.deepBlue,
      Color(0xFF0F2844),
      Color(0xFF1248B8),
      KiamiColors.primaryBlue,
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  /// Fundo da autenticacao alinhado ao tema da app.
  static LinearGradient authBackgroundFor(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          KiamiColors.deepBlue,
          Color(0xFF152536),
          Color(0xFF1B2838),
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF8FAFC),
        KiamiColors.lightGray,
        Color(0xFFE8F0FF),
      ],
      stops: [0.0, 0.45, 1.0],
    );
  }

  /// Painel lateral (layout largo) — navy em ambos os temas.
  static const LinearGradient authBrandPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      KiamiColors.deepBlue,
      Color(0xFF0F2844),
      Color(0xFF1248B8),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAFC),
      KiamiColors.lightGray,
      Color(0xFFE8F0FF),
    ],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      KiamiColors.deepBlue,
      Color(0xFF101F30),
    ],
  );

  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: KiamiColors.deepBlue.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: KiamiColors.primaryBlue.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: KiamiColors.primaryBlue.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: KiamiColors.cloudBlue.withValues(alpha: 0.15),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];

  static BoxDecoration cardLight({double radius = radiusLg}) => BoxDecoration(
        color: KiamiColors.lightSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: KiamiColors.softWhite.withValues(alpha: 0.9),
        ),
        boxShadow: cardShadowLight,
      );

  static BoxDecoration cardDark({double radius = radiusLg}) => BoxDecoration(
        color: KiamiColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: KiamiColors.cloudBlue.withValues(alpha: 0.08),
        ),
        boxShadow: cardShadowDark,
      );

  static BoxDecoration uploadZoneLight({bool highlighted = false}) =>
      BoxDecoration(
        color: highlighted
            ? KiamiColors.primaryBlue.withValues(alpha: 0.06)
            : KiamiColors.lightSurface,
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(
          color: highlighted
              ? KiamiColors.primaryBlue
              : KiamiColors.cloudBlue.withValues(alpha: 0.35),
          width: highlighted ? 2 : 1.5,
        ),
        boxShadow: highlighted ? primaryGlow : cardShadowLight,
      );

  /// Card de upload — vidro branco (glass).
  static BoxDecoration uploadGlass({
    required bool isDark,
    bool highlighted = false,
    double radius = radiusLg,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: highlighted ? 0.88 : 0.72),
        border: Border.all(
          color: Colors.white.withValues(alpha: highlighted ? 1 : 0.92),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: KiamiColors.deepBlue.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          if (highlighted)
            BoxShadow(
              color: KiamiColors.primaryBlue.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: -2,
            ),
        ],
      );

  static BoxDecoration topBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark
          ? KiamiColors.darkSurface.withValues(alpha: 0.95)
          : KiamiColors.lightSurface.withValues(alpha: 0.92),
      border: Border(
        bottom: BorderSide(
          color: isDark
              ? KiamiColors.cloudBlue.withValues(alpha: 0.1)
              : KiamiColors.deepBlue.withValues(alpha: 0.06),
        ),
      ),
    );
  }

}

