import 'package:flutter/material.dart';

import '../constants/kiami_constants.dart';
import 'kiami_platform.dart';

/// Largura com sidebar fixa (tablet / desktop / janela grande).
bool kiamiIsWideLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= KiamiConstants.breakpointTablet;
}

/// Mostra botão «voltar» no header quando não há sidebar (mobile / web estreito).
bool kiamiShowsShellBackButton(BuildContext context) {
  return !kiamiIsWideLayout(context);
}

/// Largura útil para grelhas (prefere constraints do pai, ex. área após sidebar).
double kiamiContentWidth(BuildContext context, [BoxConstraints? constraints]) {
  final maxW = constraints?.maxWidth;
  if (maxW != null && maxW.isFinite && maxW > 0) {
    return maxW;
  }
  return MediaQuery.sizeOf(context).width;
}

/// Colunas da grelha de categorias no dashboard.
int kiamiCategoryGridCrossAxisCount(double width, {required bool nativeDesktop}) {
  if (nativeDesktop && width >= KiamiConstants.breakpointTablet) {
    return 3;
  }
  if (width >= 1200) return 4;
  if (width >= 900) return 3;
  return 2;
}

/// Colunas da grelha de ficheiros numa categoria.
int kiamiFileGridCrossAxisCount(double width) {
  if (width >= 1200) return 4;
  if (width >= 800) return 3;
  return 2;
}

/// Padding horizontal do conteúdo principal (adapta a largura do telemóvel).
double kiamiContentHorizontalPadding(BuildContext context) {
  if (kiamiIsWideLayout(context)) return 32;
  final w = MediaQuery.sizeOf(context).width;
  if (w < 340) return 12;
  if (w < 380) return 14;
  if (w < 420) return 16;
  return 20;
}

/// Altura do logo barra no topo (mobile / local).
double kiamiLogoBarHeaderHeight(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.25);
  final base = w < 340 ? 38.0 : w < 400 ? 42.0 : 46.0;
  return (base * textScale).clamp(34, 52);
}

/// Padding horizontal de ListView em Definições / Planos (mobile, web, desktop).
const double kiamiSettingsListHorizontalPadding = 20;

/// Largura máxima do conteúdo centrado (evita cards esticados em monitores largos).
double? kiamiContentMaxWidth(BuildContext context) {
  if (!kiamiIsWideLayout(context)) return null;
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1600) return 1280;
  if (w >= 1280) return 1120;
  return null;
}

/// Largura máxima da zona quota + armazenamento + upload (desktop nativo, mais larga).
double? kiamiDashboardPrimaryMaxWidth(BuildContext context) {
  if (!kiamiIsNativeDesktop() || !kiamiIsWideLayout(context)) {
    return kiamiContentMaxWidth(context);
  }
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1600) return 1360;
  if (w >= 1280) return 1200;
  return w - 340;
}

/// Margem inferior com safe area (home indicator / gestos).
double kiamiBottomInset(BuildContext context, [double extra = 20]) {
  return MediaQuery.viewPaddingOf(context).bottom + extra;
}

/// Padding para [ListView], [CustomScrollView], etc.
EdgeInsets kiamiScrollPadding(
  BuildContext context, {
  double left = 0,
  double top = 0,
  double right = 0,
  double bottomExtra = 20,
}) {
  return EdgeInsets.fromLTRB(
    left,
    top,
    right,
    kiamiBottomInset(context, bottomExtra),
  );
}

/// Espaço final em slivers para conteúdo não ficar cortado em baixo.
class KiamiScrollBottomSpacer extends StatelessWidget {
  const KiamiScrollBottomSpacer({super.key, this.extra = 20});

  final double extra;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: kiamiBottomInset(context, extra)),
    );
  }
}
