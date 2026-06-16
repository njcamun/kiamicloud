import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets/kiami_assets.dart';
import '../theme/kiami_colors.dart';

/// Logo KiamiCloud — PNG se existir no bundle; senao SVG (sem 404 na Web).
class KiamiLogo extends StatefulWidget {
  const KiamiLogo({
    super.key,
    this.height = 40,
    this.variant = KiamiLogoVariant.auto,
    this.showIconOnly = false,
    this.horizontalBar = false,
  });

  final double height;
  final KiamiLogoVariant variant;
  final bool showIconOnly;

  /// Barra horizontal ([Logo_barra_claro.png] / [Logo_barra_dark.png]).
  final bool horizontalBar;

  @override
  State<KiamiLogo> createState() => _KiamiLogoState();
}

class _KiamiLogoState extends State<KiamiLogo> {
  Future<String?>? _rasterPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rasterPath = _resolveRasterPath();
  }

  @override
  void didUpdateWidget(KiamiLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalBar != widget.horizontalBar ||
        oldWidget.variant != widget.variant ||
        oldWidget.showIconOnly != widget.showIconOnly) {
      _rasterPath = _resolveRasterPath();
    }
  }

  Future<String?> _resolveRasterPath() async {
    final candidates = widget.showIconOnly
        ? KiamiAssets.iconRasterCandidates
        : _logoRasterCandidates();

    for (final path in candidates) {
      if (await _assetExists(path)) return path;
    }
    return null;
  }

  List<String> _logoRasterCandidates() {
    final brightness = Theme.of(context).brightness;
    final useDark = switch (widget.variant) {
      KiamiLogoVariant.light => false,
      KiamiLogoVariant.dark => true,
      KiamiLogoVariant.auto => brightness == Brightness.dark,
    };

    if (widget.horizontalBar) {
      return useDark
          ? KiamiAssets.logoBarDarkRasterCandidates
          : KiamiAssets.logoBarLightRasterCandidates;
    }

    return useDark
        ? KiamiAssets.logoDarkRasterCandidates
        : KiamiAssets.logoLightRasterCandidates;
  }

  String _svgPath() {
    if (widget.showIconOnly) return KiamiAssets.iconSvg;
    final brightness = Theme.of(context).brightness;
    final useDark = switch (widget.variant) {
      KiamiLogoVariant.light => false,
      KiamiLogoVariant.dark => true,
      KiamiLogoVariant.auto => brightness == Brightness.dark,
    };
    return useDark ? KiamiAssets.logoDarkSvg : KiamiAssets.logoLightSvg;
  }

  static Future<bool> _assetExists(String path) async {
    final keys = <String>[
      'packages/${KiamiAssets.package}/$path',
      path,
    ];
    for (final key in keys) {
      try {
        await rootBundle.load(key);
        return true;
      } catch (_) {
        continue;
      }
    }

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      return assets.contains('packages/${KiamiAssets.package}/$path') ||
          assets.contains(path);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svgPath = _svgPath();
    const label = 'KiamiCloud';

    return FutureBuilder<String?>(
      future: _rasterPath,
      builder: (context, snapshot) {
        final raster = snapshot.data;
        if (raster != null) {
          final image = Image.asset(
            raster,
            package: KiamiAssets.package,
            height: widget.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel: label,
            errorBuilder: (_, __, ___) => _svg(svgPath, label),
          );
          if (widget.horizontalBar) {
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: image,
              ),
            );
          }
          return image;
        }
        return _svg(svgPath, label);
      },
    );
  }

  Widget _svg(String path, String label) {
    return SvgPicture.asset(
      path,
      package: KiamiAssets.package,
      height: widget.height,
      semanticsLabel: label,
      placeholderBuilder: (_) => _FallbackMark(height: widget.height),
    );
  }
}

enum KiamiLogoVariant { auto, light, dark }

class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: height,
          height: height,
          decoration: BoxDecoration(
            gradient: KiamiColors.brandGradient,
            borderRadius: BorderRadius.circular(height * 0.25),
          ),
          child: Icon(Icons.cloud, color: Colors.white, size: height * 0.55),
        ),
        const SizedBox(width: 8),
        Text(
          'KiamiCloud',
          style: TextStyle(
            fontSize: height * 0.45,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
