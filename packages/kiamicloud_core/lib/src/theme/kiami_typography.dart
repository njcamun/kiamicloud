import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import 'kiami_colors.dart';



/// Tipografia Poppins conforme identidade visual.

abstract final class KiamiTypography {

  static TextTheme textTheme(Brightness brightness) {

    final base = GoogleFonts.poppinsTextTheme();

    final primary = brightness == Brightness.dark

        ? KiamiColors.darkTextPrimary

        : KiamiColors.lightTextPrimary;

    final secondary = brightness == Brightness.dark

        ? KiamiColors.darkTextSecondary

        : KiamiColors.lightTextSecondary;



    TextStyle? p(TextStyle? s) => s?.copyWith(color: primary);

    TextStyle? s(TextStyle? s) => s?.copyWith(color: secondary);



    return base.copyWith(

      displayLarge: p(base.displayLarge),

      displayMedium: p(base.displayMedium),

      displaySmall: p(base.displaySmall),

      headlineLarge: p(base.headlineLarge),

      headlineMedium: p(base.headlineMedium),

      headlineSmall: p(base.headlineSmall),

      titleLarge: p(base.titleLarge),

      titleMedium: p(base.titleMedium),

      titleSmall: p(base.titleSmall),

      bodyLarge: p(base.bodyLarge),

      bodyMedium: s(base.bodyMedium),

      bodySmall: s(base.bodySmall),

      labelLarge: p(base.labelLarge),

      labelMedium: p(base.labelMedium),

      labelSmall: s(base.labelSmall),

    );

  }

}

