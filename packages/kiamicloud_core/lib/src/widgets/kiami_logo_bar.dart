import 'package:flutter/material.dart';

import '../assets/kiami_assets.dart';
import 'kiami_logo.dart';

/// Logo horizontal — [Logo_barra_claro.png] / [Logo_barra_dark.png].
class KiamiLogoBar extends StatelessWidget {
  const KiamiLogoBar({
    super.key,
    this.height = 224,
    this.maxWidth = 1360,
    this.onDarkBackground,
  });

  final double height;
  final double maxWidth;

  /// `true` = barra para fundo escuro; `false` = barra para fundo claro; `null` = tema da app.
  final bool? onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final useDark = onDarkBackground ??
        (Theme.of(context).brightness == Brightness.dark);
    final candidates = useDark
        ? KiamiAssets.logoBarDarkRasterCandidates
        : KiamiAssets.logoBarLightRasterCandidates;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: height * 0.65,
          maxHeight: height,
        ),
        child: _LogoBarImage(
          key: ValueKey(useDark),
          candidates: candidates,
          primaryAsset: KiamiAssets.logoBarForBrightness(
            useDark ? Brightness.dark : Brightness.light,
          ),
          height: height,
        ),
      ),
    );
  }
}

class _LogoBarImage extends StatefulWidget {
  const _LogoBarImage({
    super.key,
    required this.candidates,
    required this.primaryAsset,
    required this.height,
  });

  final List<String> candidates;
  final String primaryAsset;
  final double height;

  @override
  State<_LogoBarImage> createState() => _LogoBarImageState();
}

class _LogoBarImageState extends State<_LogoBarImage> {
  late int _candidateIndex;

  @override
  void initState() {
    super.initState();
    _candidateIndex = _indexForPrimary();
  }

  @override
  void didUpdateWidget(_LogoBarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryAsset != widget.primaryAsset ||
        oldWidget.candidates != widget.candidates) {
      _candidateIndex = _indexForPrimary();
    }
  }

  int _indexForPrimary() {
    final i = widget.candidates.indexOf(widget.primaryAsset);
    return i >= 0 ? i : 0;
  }

  String get _currentAsset => widget.candidates[
      _candidateIndex.clamp(0, widget.candidates.length - 1)];

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _currentAsset,
      package: KiamiAssets.package,
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'KiamiCloud',
      errorBuilder: (context, error, stackTrace) {
        if (_candidateIndex < widget.candidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _candidateIndex++);
          });
          return SizedBox(height: widget.height);
        }
        return KiamiLogo(
          height: widget.height,
          horizontalBar: true,
          variant: KiamiLogoVariant.auto,
        );
      },
    );
  }
}
