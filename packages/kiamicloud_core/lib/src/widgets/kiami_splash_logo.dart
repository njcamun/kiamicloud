import 'package:flutter/material.dart';

import '../assets/kiami_assets.dart';

/// Arte completa da splash (`splashpage.png`).
class KiamiSplashLogo extends StatelessWidget {
  const KiamiSplashLogo({super.key, this.maxHeight = 120, this.maxWidth = 320});

  final double maxHeight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: Image.asset(
          KiamiAssets.splashpage,
          package: KiamiAssets.package,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          semanticLabel: 'KiamiCloud',
        ),
      ),
    );
  }
}
