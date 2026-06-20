import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_decorations.dart';
import '../../../theme/kiami_spacing.dart';
import '../../../widgets/kiami_unavailable.dart';
import '../../../utils/docx_preview.dart';
import '../../../utils/file_category.dart';
import '../../../utils/media_preview.dart';
import '../../../utils/pdf_preview.dart';
import '../../../utils/text_preview.dart';

enum FilePreviewKind { image, text, pdf, docx, video, audio }

/// Origem de média para streaming (vídeo/áudio).
typedef MediaSource = ({String url, Map<String, String> headers});

/// Pré-visualização de imagens, texto, PDF, Word, vídeo e áudio.
class FilePreviewPage extends StatelessWidget {
  const FilePreviewPage({
    super.key,
    required this.file,
    required this.kind,
    this.bytes,
    this.mediaSource,
    this.embedded = false,
    this.zoomEnabled = true,
    this.imageBrightness = 1.0,
    this.centeredGalleryZoom = false,
    this.onGalleryZoomChanged,
    this.mediaPopupStyle = false,
    this.mediaActive = true,
  });

  final KiamiFile file;
  final FilePreviewKind kind;

  /// Conteúdo carregado (imagem, texto, PDF, docx).
  final Uint8List? bytes;

  /// URL + headers para streaming (vídeo, áudio).
  final MediaSource? mediaSource;

  /// Sem AppBar — usado dentro da galeria.
  final bool embedded;

  /// Pinch-to-zoom na imagem (galeria: só na foto activa).
  final bool zoomEnabled;

  /// Multiplicador de brilho (1.0 = normal).
  final double imageBrightness;

  /// Zoom centrado com pan horizontal/vertical quando ampliada (galeria).
  final bool centeredGalleryZoom;

  final ValueChanged<bool>? onGalleryZoomChanged;

  final bool mediaPopupStyle;

  final bool mediaActive;

  static bool isMediaKind(FilePreviewKind kind) =>
      kind == FilePreviewKind.video || kind == FilePreviewKind.audio;

  static bool canPreview(KiamiFile file) {
    final cat = fileCategoryForName(file.name);
    if (cat == KiamiFileCategory.images) return true;
    if (canPreviewTextFileName(file.name) &&
        file.sizeBytes <= kTextPreviewMaxBytes) {
      return true;
    }
    if (canPreviewPdfFile(file.name, file.sizeBytes)) return true;
    if (canPreviewDocxFile(file.name, file.sizeBytes)) return true;
    if (canPreviewVideoFileName(file.name)) return true;
    if (canPreviewAudioFileName(file.name)) return true;
    return false;
  }

  static FilePreviewKind kindFor(KiamiFile file) => _kindFor(file);

  /// Carrossel horizontal só para imagens e vídeos.
  static bool isVisualCarouselFile(KiamiFile file) {
    if (!canPreview(file)) return false;
    final k = kindFor(file);
    return k == FilePreviewKind.image || k == FilePreviewKind.video;
  }

  static bool galleryUsesVisualCarousel(List<KiamiFile> files) {
    if (files.isEmpty) return false;
    return files.every(isVisualCarouselFile);
  }

  static FilePreviewKind _kindFor(KiamiFile file) {
    if (canPreviewPdfFile(file.name, file.sizeBytes)) {
      return FilePreviewKind.pdf;
    }
    if (canPreviewDocxFileName(file.name)) return FilePreviewKind.docx;
    if (canPreviewTextFileName(file.name)) return FilePreviewKind.text;
    if (canPreviewVideoFileName(file.name)) return FilePreviewKind.video;
    if (canPreviewAudioFileName(file.name)) return FilePreviewKind.audio;
    return FilePreviewKind.image;
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (kind) {
      FilePreviewKind.text => _TextBody(bytes: bytes!),
      FilePreviewKind.pdf => _PdfBody(bytes: bytes!),
      FilePreviewKind.image => _ImageBody(
          bytes: bytes!,
          zoomEnabled: zoomEnabled,
          brightness: imageBrightness,
          centeredGalleryZoom: centeredGalleryZoom,
          onGalleryZoomChanged: onGalleryZoomChanged,
        ),
      FilePreviewKind.docx => _DocxBody(bytes: bytes!),
      FilePreviewKind.video => _MediaBody(
          source: mediaSource!,
          isAudio: false,
          fileName: file.name,
          popupStyle: mediaPopupStyle,
          isActive: mediaActive,
        ),
      FilePreviewKind.audio => _MediaBody(
          source: mediaSource!,
          isAudio: true,
          fileName: file.name,
          popupStyle: mediaPopupStyle,
          isActive: mediaActive,
        ),
    };

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: body,
    );
  }

  static Future<void> openIfSupported(
    BuildContext context, {
    required KiamiFile file,
    required Future<Uint8List> Function() loadBytes,
    Future<MediaSource> Function()? loadMediaSource,
  }) async {
    if (!canPreview(file)) return;
    if (canPreviewTextFileName(file.name) &&
        file.sizeBytes > kTextPreviewMaxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.previewTextTooLarge)),
      );
      return;
    }
    if (canPreviewPdfFileName(file.name) &&
        file.sizeBytes > kPdfPreviewMaxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.previewPdfTooLarge)),
      );
      return;
    }
    if (canPreviewDocxFileName(file.name) &&
        file.sizeBytes > kDocxPreviewMaxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.previewDocxTooLarge)),
      );
      return;
    }

    final kind = _kindFor(file);
    final isMedia = isMediaKind(kind);
    if (isMedia && loadMediaSource == null) return;

    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => _FilePreviewLoader(
        file: file,
        kind: kind,
        loadBytes: isMedia ? null : loadBytes,
        loadMediaSource: isMedia ? loadMediaSource : null,
      ),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }
}

/// Carrega o conteúdo e abre a pré-visualização sem diálogo de loading.
class _FilePreviewLoader extends StatefulWidget {
  const _FilePreviewLoader({
    required this.file,
    required this.kind,
    required this.loadBytes,
    required this.loadMediaSource,
  });

  final KiamiFile file;
  final FilePreviewKind kind;
  final Future<Uint8List> Function()? loadBytes;
  final Future<MediaSource> Function()? loadMediaSource;

  @override
  State<_FilePreviewLoader> createState() => _FilePreviewLoaderState();
}

class _FilePreviewLoaderState extends State<_FilePreviewLoader> {
  Uint8List? _bytes;
  MediaSource? _mediaSource;
  String? _error;
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _connectionError = false;
      _bytes = null;
      _mediaSource = null;
    });
    try {
      if (FilePreviewPage.isMediaKind(widget.kind)) {
        _mediaSource = await widget.loadMediaSource!();
      } else {
        _bytes = await widget.loadBytes!();
      }
    } catch (e) {
      _connectionError = kiamiPreviewConnectionIssue(e);
      _error = _connectionError
          ? KiamiStrings.noConnectTitle
          : KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return KiamiPreviewIssueOverlay(
        connectionError: _connectionError,
        onDismiss: () => Navigator.of(context).pop(),
      );
    }

    final isMedia = FilePreviewPage.isMediaKind(widget.kind);
    if (isMedia && _mediaSource == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: widget.kind == FilePreviewKind.audio
            ? const SizedBox.shrink()
            : const ColoredBox(color: Colors.black),
      );
    }

    if (!isMedia && _bytes == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const SizedBox.shrink(),
      );
    }

    return FilePreviewPage(
      file: widget.file,
      kind: widget.kind,
      bytes: _bytes,
      mediaSource: _mediaSource,
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.bytes,
    this.zoomEnabled = true,
    this.brightness = 1.0,
    this.centeredGalleryZoom = false,
    this.onGalleryZoomChanged,
  });

  final Uint8List bytes;
  final bool zoomEnabled;
  final double brightness;
  final bool centeredGalleryZoom;
  final ValueChanged<bool>? onGalleryZoomChanged;

  static List<double> _brightnessMatrix(double value) {
    return [
      value, 0, 0, 0, 0,
      0, value, 0, 0, 0,
      0, 0, value, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.memory(bytes, fit: BoxFit.contain);
    if (brightness != 1.0) {
      image = ColorFiltered(
        colorFilter: ColorFilter.matrix(_brightnessMatrix(brightness)),
        child: image,
      );
    }
    if (!zoomEnabled) {
      return Center(child: image);
    }
    if (centeredGalleryZoom) {
      return _GalleryDoubleTapPhotoViewer(
        bytes: bytes,
        brightness: brightness,
        onZoomChanged: onGalleryZoomChanged,
      );
    }
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        panEnabled: true,
        scaleEnabled: true,
        clipBehavior: Clip.none,
        child: image,
      ),
    );
  }
}

/// Galeria: duplo toque para zoom, pan horizontal e vertical quando ampliada.
class _GalleryDoubleTapPhotoViewer extends StatefulWidget {
  const _GalleryDoubleTapPhotoViewer({
    required this.bytes,
    this.brightness = 1.0,
    this.onZoomChanged,
  });

  final Uint8List bytes;
  final double brightness;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<_GalleryDoubleTapPhotoViewer> createState() =>
      _GalleryDoubleTapPhotoViewerState();
}

class _GalleryDoubleTapPhotoViewerState extends State<_GalleryDoubleTapPhotoViewer>
    with SingleTickerProviderStateMixin {
  static const _zoomScale = 2.5;

  Size? _imageSize;
  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  late AnimationController _animController;
  Animation<double>? _scaleAnim;
  Animation<double>? _offsetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_scaleAnim != null) {
          setState(() {
            _scale = _scaleAnim!.value;
            _offsetX = _offsetAnim?.value ?? 0;
          });
        }
      });
    _decodeImageSize();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _decodeImageSize() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      if (mounted) setState(() => _imageSize = size);
    } catch (_) {}
  }

  Size _displaySize(Size viewport) {
    final image = _imageSize;
    if (image == null || image.width <= 0 || image.height <= 0) {
      return viewport;
    }
    final imageAspect = image.width / image.height;
    final viewportAspect = viewport.width / viewport.height;
    if (imageAspect > viewportAspect) {
      final w = viewport.width;
      return Size(w, w / imageAspect);
    }
    final h = viewport.height;
    return Size(h * imageAspect, h);
  }

  double _maxHorizontalOffset(Size viewport, Size display, [double? scale]) {
    final s = scale ?? _scale;
    if (s <= 1.0) return 0;
    final excess = display.width * s - viewport.width;
    return math.max(0, excess / 2);
  }

  double _maxVerticalOffset(Size viewport, Size display, [double? scale]) {
    final s = scale ?? _scale;
    if (s <= 1.0) return 0;
    final excess = display.height * s - viewport.height;
    return math.max(0, excess / 2);
  }

  void _notifyZoom(bool zoomed) => widget.onZoomChanged?.call(zoomed);

  void _toggleZoom(Size viewport, Size display) {
    final targetScale = _scale > 1.0 ? 1.0 : _zoomScale;
    final maxX = _maxHorizontalOffset(viewport, display, targetScale);
    final maxY = _maxVerticalOffset(viewport, display, targetScale);
    final targetOffsetX =
        targetScale > 1.0 ? _offsetX.clamp(-maxX, maxX) : 0.0;
    final targetOffsetY =
        targetScale > 1.0 ? _offsetY.clamp(-maxY, maxY) : 0.0;

    _scaleAnim = Tween<double>(begin: _scale, end: targetScale).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _offsetAnim = Tween<double>(begin: _offsetX, end: targetOffsetX).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0).whenComplete(() {
      _scale = targetScale;
      _offsetX = targetOffsetX;
      _offsetY = targetOffsetY;
      if (targetScale <= 1.0) {
        _offsetX = 0;
        _offsetY = 0;
      }
      _notifyZoom(targetScale > 1.0);
    });
  }

  Widget _buildImage(Size displaySize) {
    Widget image = Image.memory(
      widget.bytes,
      width: displaySize.width,
      height: displaySize.height,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (widget.brightness != 1.0) {
      image = ColorFiltered(
        colorFilter: ColorFilter.matrix(_ImageBody._brightnessMatrix(
          widget.brightness,
        )),
        child: image,
      );
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final display = _displaySize(viewport);
        final maxOffsetX = _maxHorizontalOffset(viewport, display);
        final maxOffsetY = _maxVerticalOffset(viewport, display);
        final zoomed = _scale > 1.01;

        return GestureDetector(
          onDoubleTap: () => _toggleZoom(viewport, display),
          onPanUpdate: zoomed
              ? (details) {
                  setState(() {
                    _offsetX = (_offsetX + details.delta.dx)
                        .clamp(-maxOffsetX, maxOffsetX);
                    _offsetY = (_offsetY + details.delta.dy)
                        .clamp(-maxOffsetY, maxOffsetY);
                  });
                }
              : null,
          onPanEnd: zoomed
              ? (_) {
                  setState(() {
                    _offsetX = _offsetX.clamp(-maxOffsetX, maxOffsetX);
                    _offsetY = _offsetY.clamp(-maxOffsetY, maxOffsetY);
                  });
                }
              : null,
          child: ClipRect(
            child: Center(
              child: Transform.translate(
                offset: Offset(_offsetX, _offsetY),
                child: Transform.scale(
                  scale: _scale,
                  alignment: Alignment.center,
                  child: _buildImage(display),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final text = utf8.decode(bytes, allowMalformed: true);
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
        ),
      ),
    );
  }
}

class _DocxBody extends StatelessWidget {
  const _DocxBody({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final text = extractDocxText(bytes);
    if (text == null) {
      return const SizedBox.expand(
        child: KiamiPreviewIssueOverlay(
          connectionError: false,
          barrierDismissible: false,
        ),
      );
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ),
    );
  }
}

class _PdfBody extends StatefulWidget {
  const _PdfBody({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfBody> createState() => _PdfBodyState();
}

class _PdfBodyState extends State<_PdfBody> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
      onDocumentError: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.previewPdfError)),
        );
      },
    );
  }
}

/// Player simples de vídeo/áudio com streaming (play/pause + barra de posição).
class _MediaBody extends StatefulWidget {
  const _MediaBody({
    required this.source,
    required this.isAudio,
    required this.fileName,
    this.popupStyle = false,
    this.isActive = true,
  });

  final MediaSource source;
  final bool isAudio;
  final String fileName;
  final bool popupStyle;
  final bool isActive;

  @override
  State<_MediaBody> createState() => _MediaBodyState();
}

class _MediaBodyState extends State<_MediaBody> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _controller?.removeListener(_onTick);
    await _controller?.dispose();
    _controller = null;
    if (!mounted) return;
    setState(() {
      _failed = false;
      _ready = false;
    });
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.source.url),
        httpHeaders: widget.source.headers,
      );
      _controller = controller;
      controller.addListener(_onTick);
      await controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.isActive) {
        await controller.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    if (!mounted) return;
    final c = _controller;
    if (c != null && c.value.hasError && !_failed) {
      setState(() => _failed = true);
      return;
    }
    // Actualiza posição/estado de reprodução.
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _MediaBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox.expand(
        child: KiamiPreviewIssueOverlay(
          connectionError: false,
          barrierDismissible: false,
        ),
      );
    }
    final controller = _controller;
    if (!_ready || controller == null) {
      return widget.isAudio
          ? _AudioLoadingPlaceholder(
              fileName: widget.fileName,
              popupStyle: widget.popupStyle,
            )
          : ColoredBox(
              color: widget.popupStyle ? Colors.transparent : Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            );
    }

    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: widget.popupStyle
          ? Colors.transparent
          : (isDark ? KiamiColors.darkBackground : KiamiColors.lightGray),
      child: widget.isAudio
          ? _AudioPlayerSurface(
              fileName: widget.fileName,
              popupStyle: widget.popupStyle,
              position: position,
              duration: duration,
              isPlaying: value.isPlaying,
              onSeek: duration.inMilliseconds > 0
                  ? (v) =>
                      controller.seekTo(Duration(milliseconds: v.round()))
                  : null,
              onPlayPause: () {
                value.isPlaying ? controller.pause() : controller.play();
              },
            )
          : Column(
              children: [
                Expanded(
                  child: _VideoPlayerSurface(
                    controller: controller,
                    aspectRatio: value.aspectRatio > 0
                        ? value.aspectRatio
                        : 16 / 9,
                    popupStyle: widget.popupStyle,
                    position: position,
                    duration: duration,
                    isPlaying: value.isPlaying,
                    onSeek: duration.inMilliseconds > 0
                        ? (v) => controller.seekTo(
                              Duration(milliseconds: v.round()),
                            )
                        : null,
                    onPlayPause: () {
                      value.isPlaying ? controller.pause() : controller.play();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Superfície de áudio — artwork centrado com controlos minimalistas.
class _AudioPlayerSurface extends StatelessWidget {
  const _AudioPlayerSurface({
    required this.fileName,
    required this.popupStyle,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    this.onSeek,
  });

  final String fileName;
  final bool popupStyle;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final artworkSize = popupStyle ? 168.0 : 220.0;
    final controls = _ModernVideoControls(
      position: position,
      duration: duration,
      isPlaying: isPlaying,
      onPlayPause: onPlayPause,
      onSeek: onSeek,
      overlay: popupStyle,
    );

    final artwork = Container(
      width: artworkSize,
      height: artworkSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          popupStyle ? KiamiDecorations.radiusLg : KiamiDecorations.radiusXl,
        ),
        gradient: KiamiColors.brandGradient,
        boxShadow: popupStyle
            ? null
            : [
                BoxShadow(
                  color: KiamiColors.primaryBlue.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: artworkSize * 0.4,
        color: Colors.white,
      ),
    );

    final title = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: popupStyle ? KiamiSpacing.lg : KiamiSpacing.xl,
      ),
      child: Text(
        fileName,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: (popupStyle
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(
          fontWeight: FontWeight.w600,
          color: popupStyle ? Colors.white : null,
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPlayPause,
          child: artwork,
        ),
        SizedBox(height: popupStyle ? KiamiSpacing.md : KiamiSpacing.lg),
        title,
        if (!popupStyle) ...[
          const SizedBox(height: KiamiSpacing.sm),
          Text(
            KiamiStrings.categoryAudio,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KiamiColors.textSecondary(context),
                ),
          ),
        ],
        SizedBox(height: popupStyle ? KiamiSpacing.lg : KiamiSpacing.xl),
        SizedBox(
          width: popupStyle ? 300 : 320,
          child: controls,
        ),
      ],
    );

    if (popupStyle) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(KiamiDecorations.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: content,
            ),
          ),
        ),
      );
    }

    return Center(child: content);
  }
}

Size _fitVideoInBounds({
  required double maxWidth,
  required double maxHeight,
  required double aspectRatio,
}) {
  if (maxWidth <= 0 || maxHeight <= 0 || aspectRatio <= 0) {
    return Size.zero;
  }
  var w = maxWidth;
  var h = w / aspectRatio;
  if (h > maxHeight) {
    h = maxHeight;
    w = h * aspectRatio;
  }
  return Size(w, h);
}

/// Superfície de vídeo com controlos minimalistas integrados.
class _VideoPlayerSurface extends StatelessWidget {
  const _VideoPlayerSurface({
    required this.controller,
    required this.aspectRatio,
    required this.popupStyle,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    this.onSeek,
  });

  final VideoPlayerController controller;
  final double aspectRatio;
  final bool popupStyle;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _fitVideoInBounds(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          aspectRatio: aspectRatio,
        );

        final radius = popupStyle
            ? BorderRadius.circular(KiamiDecorations.radiusLg)
            : BorderRadius.circular(KiamiDecorations.radiusMd);

        final controls = _ModernVideoControls(
          position: position,
          duration: duration,
          isPlaying: isPlaying,
          onPlayPause: onPlayPause,
          onSeek: onSeek,
          overlay: popupStyle,
        );

        if (popupStyle) {
          return Center(
            child: ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(controller),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: onPlayPause,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: controls,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width,
                child: controls,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Controlos de vídeo — barra fina, tipografia leve, botão circular.
class _ModernVideoControls extends StatelessWidget {
  const _ModernVideoControls({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.overlay,
    this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final bool overlay;
  final ValueChanged<double>? onSeek;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds.clamp(0, duration.inMilliseconds) /
            duration.inMilliseconds
        : 0.0;

    final timeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          color: overlay
              ? Colors.white.withValues(alpha: 0.88)
              : KiamiColors.textSecondary(context),
          letterSpacing: 0.2,
        );

    Widget panel = Padding(
      padding: EdgeInsets.fromLTRB(
        overlay ? 14 : 4,
        overlay ? 18 : 10,
        overlay ? 14 : 4,
        overlay ? 12 : 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SlimMediaProgress(
            value: progress,
            onChanged: onSeek == null
                ? null
                : (v) => onSeek!(v * duration.inMilliseconds),
            overlay: overlay,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_fmt(position), style: timeStyle),
              Expanded(
                child: Center(
                  child: _ModernPlayButton(
                    isPlaying: isPlaying,
                    onPressed: onPlayPause,
                    overlay: overlay,
                  ),
                ),
              ),
              Text(_fmt(duration), style: timeStyle),
            ],
          ),
        ],
      ),
    );

    if (overlay) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.78),
            ],
          ),
        ),
        child: panel,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? KiamiColors.darkSurface.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
        border: Border.all(
          color: isDark
              ? KiamiColors.cloudBlue.withValues(alpha: 0.1)
              : KiamiColors.softWhite.withValues(alpha: 0.9),
        ),
      ),
      child: panel,
    );
  }
}

class _SlimMediaProgress extends StatelessWidget {
  const _SlimMediaProgress({
    required this.value,
    required this.overlay,
    this.onChanged,
  });

  final double value;
  final bool overlay;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final active = overlay ? Colors.white : KiamiColors.primaryBlue;
    final inactive = overlay
        ? Colors.white.withValues(alpha: 0.28)
        : KiamiColors.primaryBlue.withValues(alpha: 0.18);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.5,
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: active,
        inactiveTrackColor: inactive,
        thumbColor: active,
        overlayColor: Colors.transparent,
      ),
      child: Slider(
        value: value.clamp(0.0, 1.0),
        onChanged: onChanged,
      ),
    );
  }
}

class _ModernPlayButton extends StatelessWidget {
  const _ModernPlayButton({
    required this.isPlaying,
    required this.onPressed,
    required this.overlay,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: overlay
          ? Colors.white.withValues(alpha: 0.16)
          : KiamiColors.primaryBlue,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _AudioLoadingPlaceholder extends StatelessWidget {
  const _AudioLoadingPlaceholder({
    required this.fileName,
    this.popupStyle = false,
  });

  final String fileName;
  final bool popupStyle;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: popupStyle ? 32 : 36,
          height: popupStyle ? 32 : 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: popupStyle ? Colors.white70 : null,
          ),
        ),
        SizedBox(height: popupStyle ? KiamiSpacing.sm : KiamiSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: popupStyle ? KiamiSpacing.lg : 0,
          ),
          child: Text(
            fileName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: popupStyle ? Colors.white : null,
                ),
          ),
        ),
      ],
    );

    if (popupStyle) {
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: body,
          ),
        ),
      );
    }

    return Center(child: body);
  }
}
