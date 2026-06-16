import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../assets/kiami_assets.dart';
import '../constants/kiami_constants.dart';
import '../constants/kiami_strings.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';

/// Upload — card rectangular tipo vidro com icone e texto.
class KiamiUploadZone extends StatefulWidget {
  const KiamiUploadZone({
    super.key,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
    this.progressCurrent = 0,
    this.progressTotal = 0,
    this.cardWidth,
    this.maxPerFileLabel = KiamiConstants.maxUploadLabel,
  });

  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;
  final int progressCurrent;
  final int progressTotal;

  /// Largura fixa do card (ex.: alinhada ao card de armazenamento no desktop).
  final double? cardWidth;
  final String maxPerFileLabel;

  static const double cardWidthFraction = 0.88;
  static const double minCardHeight = 76;
  static const double maxCardHeight = 132;

  @override
  State<KiamiUploadZone> createState() => _KiamiUploadZoneState();
}

class _KiamiUploadZoneState extends State<KiamiUploadZone> {
  int _assetCandidateIndex = 0;
  Brightness? _lastBrightness;
  bool _pressed = false;

  List<String> _candidates(Brightness brightness) {
    return brightness == Brightness.dark
        ? KiamiAssets.uploadIconDarkCandidates
        : KiamiAssets.uploadIconLightCandidates;
  }

  double _widthFraction(double screenWidth) {
    if (screenWidth < 340) return 0.94;
    if (screenWidth < 400) return 0.92;
    return KiamiUploadZone.cardWidthFraction;
  }

  double _resolveCardWidth(double screenWidth, double maxWidth) {
    final target = widget.cardWidth ?? screenWidth * _widthFraction(screenWidth);
    if (maxWidth.isFinite && maxWidth > 0) {
      return math.min(target, maxWidth);
    }
    return target;
  }

  double _resolveCardHeight(double cardWidth, double screenHeight) {
    final byWidth = cardWidth * 0.28;
    final byScreen = screenHeight * 0.11;
    final h = math.min(byWidth, math.max(byScreen, KiamiUploadZone.minCardHeight));
    return h.clamp(KiamiUploadZone.minCardHeight, KiamiUploadZone.maxCardHeight);
  }

  /// Escala conteudo para caber na altura/largura internas do card.
  double _contentScale(double innerW, double innerH) {
    const refW = 260.0;
    const refH = 52.0;
    final wScale = (innerW / refW).clamp(0.82, 1.35);
    final hScale = (innerH / refH).clamp(0.78, 1.35);
    return math.min(wScale, hScale);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.2);

    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _assetCandidateIndex = 0;
    }

    final candidates = _candidates(brightness);
    final asset =
        candidates[_assetCandidateIndex.clamp(0, candidates.length - 1)];

    final titleColor = KiamiColors.deepBlue;
    final subtitleColor = KiamiColors.lightTextSecondary;

    return LayoutBuilder(
      builder: (context, outer) {
        final cardWidth = _resolveCardWidth(
          screenSize.width,
          outer.maxWidth,
        );
        final cardHeight = _resolveCardHeight(cardWidth, screenSize.height) *
            textScale.clamp(1.0, 1.15);

        return AnimatedOpacity(
          opacity: widget.enabled ? 1 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Align(
            alignment: widget.cardWidth != null
                ? Alignment.centerLeft
                : Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onTap,
                onHighlightChanged: widget.isLoading
                    ? null
                    : (v) => setState(() => _pressed = v),
                borderRadius:
                    BorderRadius.circular(KiamiDecorations.radiusLg),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(KiamiDecorations.radiusLg),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: cardWidth,
                      height: cardHeight,
                      decoration: KiamiDecorations.uploadGlass(
                        isDark: isDark,
                        highlighted: _pressed && widget.enabled,
                      ),
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final scale = _contentScale(
                            inner.maxWidth,
                            inner.maxHeight,
                          );
                          final hPad = (10 * scale).clamp(8.0, 14.0);
                          final titleSize = (12 * scale).clamp(10.0, 16.0);
                          final subtitleSize =
                              (10 * scale).clamp(9.0, 13.0);

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: hPad,
                              vertical: hPad * 0.7,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: (inner.maxWidth * 0.36)
                                          .clamp(48.0, 120.0),
                                      child: Image.asset(
                                        asset,
                                        package: KiamiAssets.package,
                                        fit: BoxFit.contain,
                                        height: (inner.maxHeight * 0.72)
                                            .clamp(32.0, 72.0),
                                        errorBuilder: (_, __, ___) {
                                          if (_assetCandidateIndex <
                                              candidates.length - 1) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(
                                                    () => _assetCandidateIndex++);
                                              }
                                            });
                                          }
                                          return Icon(
                                            Icons.cloud_upload_outlined,
                                            size: (inner.maxHeight * 0.5)
                                                .clamp(28.0, 40.0),
                                            color: KiamiColors.primaryBlue
                                                .withValues(alpha: 0.8),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8 * scale),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: inner.maxWidth * 0.58,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (!widget.isLoading) ...[
                                                Text(
                                                  KiamiStrings
                                                      .uploadDropTitle,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: titleSize,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.1,
                                                    color: titleColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: (2 * scale)
                                                        .clamp(2.0, 4.0)),
                                                Text(
                                                  KiamiStrings
                                                      .uploadDropSubtitle(
                                                    widget.maxPerFileLabel,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: subtitleSize,
                                                    height: 1.1,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                              ] else
                                                Text(
                                                  widget.progressTotal > 1
                                                      ? KiamiStrings
                                                          .uploadInProgressCount(
                                                          widget
                                                              .progressCurrent,
                                                          widget
                                                              .progressTotal,
                                                        )
                                                      : KiamiStrings
                                                          .uploadInProgress,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: titleSize,
                                                    fontWeight: FontWeight.w500,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.isLoading)
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(
                                          KiamiDecorations.radiusLg,
                                        ),
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: (24 * scale).clamp(20, 32),
                                          height: (24 * scale).clamp(20, 32),
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
