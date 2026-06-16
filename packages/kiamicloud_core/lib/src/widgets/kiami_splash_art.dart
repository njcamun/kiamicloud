import 'package:flutter/material.dart';

import '../assets/kiami_assets.dart';
import '../theme/kiami_colors.dart';

/// Arte da splash — apenas `splashpage.png`.
class KiamiSplashArt extends StatelessWidget {
  const KiamiSplashArt({super.key});

  static const Color _edgeColor = KiamiColors.deepBlue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _edgeColor,
      child: Image.asset(
        KiamiAssets.splashpage,
        package: KiamiAssets.package,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        semanticLabel: 'KiamiCloud',
        gaplessPlayback: true,
      ),
    );
  }
}
