import 'package:flutter/material.dart';

/// Caminhos dos assets de branding (apos sync-branding-assets).
abstract final class KiamiAssets {
  static const String package = 'kiamicloud_core';
  static const String _base = 'assets/branding';

  // SVG
  static const String logoLightSvg = '$_base/logo.svg';
  static const String logoDarkSvg = '$_base/logo_dark.svg';
  static const String iconSvg = '$_base/icon.svg';

  // PNG — logos e icone da app (fonte: branding/assets/)
  static const String logoClaroPng = '$_base/logo_claro.png';
  static const String logoDarkPng = '$_base/logo_dark.png';
  static const String appIconPng = '$_base/icone.png';
  static const String iconLightPng = '$_base/icon_claro.png';
  static const String iconDarkPng = '$_base/icon_dark.png';

  /// Splash — ficheiro `splashpage.png` (único).
  static const String splashpage = '$_base/splashpage.png';

  @Deprecated('Use KiamiAssets.splashpage')
  static const String splashPagePng = splashpage;

  /// Documentação legal (cópia estável sem espaços no nome do ficheiro).
  static const String legalDocumentPdf = '$_base/legal_documentation.pdf';

  /// Caminho completo no asset bundle (pacote kiamicloud_core).
  static const String legalDocumentBundlePath =
      'packages/$package/$legalDocumentPdf';

  static String packageAssetPath(String relativePath) =>
      'packages/$package/$relativePath';

  /// Splash (ecrã Flutter ao iniciar) — apenas splashpage.png.
  static const String splashLogoClaroPng = splashpage;
  static const String splashLogoDarkPng = splashpage;

  /// Logos barra horizontal (login e cabecalhos).
  static const String logoBarLightPng = '$_base/Logo_barra_claro.png';
  static const String logoBarDarkPng = '$_base/Logo_barra_dark.png';

  static String logoBarForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? logoBarDarkPng : logoBarLightPng;

  static const List<String> logoBarLightRasterCandidates = [
    logoBarLightPng,
    logoClaroPng,
  ];

  static const List<String> logoBarDarkRasterCandidates = [
    logoBarDarkPng,
    logoDarkPng,
  ];

  static const List<String> logoLightRasterCandidates = [
    logoClaroPng,
  ];

  static const List<String> logoDarkRasterCandidates = [
    logoDarkPng,
  ];

  static const List<String> appIconRasterCandidates = [
    appIconPng,
    iconLightPng,
  ];

  static const List<String> iconRasterCandidates = appIconRasterCandidates;

  /// Icone de upload conforme tema (claro / escuro).
  static const List<String> uploadIconLightCandidates = [
    iconLightPng,
    appIconPng,
  ];

  static const List<String> uploadIconDarkCandidates = [
    iconDarkPng,
    appIconPng,
  ];

  // Categorias do dashboard (PNG em assets/categories/)
  static const String _categories = 'assets/categories';
  static const String categoryImagesPng = '$_categories/img.png';
  static const String categoryImagesDarkPng = '$_categories/img_dark.png';
  static const String categoryVideoPng = '$_categories/video.png';
  static const String categoryVideoDarkPng = '$_categories/video_dark.png';
  static const String categoryAudioPng = '$_categories/audio.png';
  static const String categoryAudioDarkPng = '$_categories/audio_dark.png';
  static const String categoryDocumentsPng = '$_categories/doc.png';
  static const String categoryDocumentsDarkPng = '$_categories/doc_dark.png';
  static const String categoryOthersPng = '$_categories/outro.png';
  static const String categoryOthersDarkPng = '$_categories/outro_dark.png';
  static const String categoryUnknownPng = '$_categories/unknow.png';
  static const String categoryUnknownDarkPng = '$_categories/unknow_dark.png';
}
