import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_decorations.dart';
import '../../../theme/kiami_spacing.dart';
import '../../photos/presentation/photo_gallery_actions.dart';
import 'audio_gallery_actions.dart';
import 'file_preview_page.dart';
import 'video_gallery_actions.dart';

/// Galeria de ficheiros — carrossel para imagens/vídeo; ecrã integral para o resto.
class FileGalleryPage extends StatefulWidget {
  const FileGalleryPage({
    super.key,
    required this.files,
    required this.initialIndex,
    required this.loadBytes,
    required this.loadMediaSource,
    this.onDownload,
    this.photoActions,
    this.videoActions,
    this.audioActions,
  });

  final List<KiamiFile> files;
  final int initialIndex;
  final Future<Uint8List> Function(KiamiFile file) loadBytes;
  final Future<MediaSource> Function(KiamiFile file) loadMediaSource;
  final void Function(KiamiFile file)? onDownload;
  final PhotoGalleryActions? photoActions;
  final VideoGalleryActions? videoActions;
  final AudioGalleryActions? audioActions;

  static const double _carouselViewport = 0.78;

  static Future<void> open(
    BuildContext context, {
    required List<KiamiFile> files,
    required int initialIndex,
    required Future<Uint8List> Function(KiamiFile file) loadBytes,
    required Future<MediaSource> Function(KiamiFile file) loadMediaSource,
    void Function(KiamiFile file)? onDownload,
    PhotoGalleryActions? photoActions,
    VideoGalleryActions? videoActions,
    AudioGalleryActions? audioActions,
  }) {
    if (files.isEmpty) return Future.value();
    final index = initialIndex.clamp(0, files.length - 1);
    final page = FileGalleryPage(
      files: files,
      initialIndex: index,
      loadBytes: loadBytes,
      loadMediaSource: loadMediaSource,
      onDownload: onDownload,
      photoActions: photoActions,
      videoActions: videoActions,
      audioActions: audioActions,
    );

    if (photoActions != null ||
        videoActions != null ||
        audioActions != null) {
      return showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => page,
        transitionBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.14, end: 1.0).animate(curved),
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      );
    }

    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FileGalleryPage> createState() => _FileGalleryPageState();
}

class _FileGalleryPageState extends State<FileGalleryPage> {
  late PageController _pageController;
  late int _index;
  late final bool _visualCarousel;
  late final bool _photoPopup;
  late final bool _videoPopup;
  late final bool _audioPopup;
  bool _photoZoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.files.length - 1);
    _visualCarousel = FilePreviewPage.galleryUsesVisualCarousel(widget.files);
    _photoPopup = _visualCarousel && widget.photoActions != null;
    _videoPopup = _visualCarousel && widget.videoActions != null;
    _audioPopup = widget.audioActions != null;
    _pageController = PageController(
      initialPage: _index,
      viewportFraction: _visualCarousel &&
              !_photoPopup &&
              !_videoPopup &&
              !_audioPopup
          ? FileGalleryPage._carouselViewport
          : 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  KiamiFile get _current => widget.files[_index];

  void _onPhotoZoomChanged(bool zoomed) {
    if (_photoZoomed != zoomed) {
      setState(() => _photoZoomed = zoomed);
    }
  }

  void _goTo(int next) {
    if (next < 0 || next >= widget.files.length) return;
    _pageController.animateToPage(
      next,
      duration: Duration(milliseconds: _visualCarousel ? 280 : 220),
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_index - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_index + 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_photoPopup) {
      return _buildPhotoPopupScaffold(context);
    }
    if (_videoPopup) {
      return _buildVideoPopupScaffold(context);
    }
    if (_audioPopup) {
      return _buildAudioPopupScaffold(context);
    }
    if (_visualCarousel) {
      return _buildVisualCarouselScaffold(context);
    }
    return _buildClassicScaffold(context);
  }

  Widget _buildClassicScaffold(BuildContext context) {
    final file = _current;
    final canPreview = FilePreviewPage.canPreview(file);
    final scheme = Theme.of(context).colorScheme;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                KiamiStrings.galleryPosition(_index + 1, widget.files.length),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: KiamiStrings.galleryPrevious,
              onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: KiamiStrings.galleryNext,
              onPressed: _index < widget.files.length - 1
                  ? () => _goTo(_index + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            if (widget.onDownload != null)
              IconButton(
                tooltip: KiamiStrings.downloadButton,
                onPressed: () => widget.onDownload!(file),
                icon: const Icon(Icons.download_outlined),
              ),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.files.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, pageIndex) {
            return _GalleryFilePage(
              key: ValueKey(widget.files[pageIndex].id),
              file: widget.files[pageIndex],
              loadBytes: widget.loadBytes,
              loadMediaSource: widget.loadMediaSource,
              onDownload: widget.onDownload,
            );
          },
        ),
        bottomNavigationBar: widget.files.length > 1
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed:
                            _index > 0 ? () => _goTo(_index - 1) : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text(KiamiStrings.galleryPrevious),
                      ),
                      const Spacer(),
                      if (!canPreview && widget.onDownload != null)
                        TextButton.icon(
                          onPressed: () => widget.onDownload!(file),
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text(KiamiStrings.downloadButton),
                        ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _index < widget.files.length - 1
                            ? () => _goTo(_index + 1)
                            : null,
                        icon:
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(KiamiStrings.galleryNext),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPhotoPopupScaffold(BuildContext context) {
    final file = _current;
    final topPad = MediaQuery.paddingOf(context).top;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _photoZoomed
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: widget.files.length,
                    onPageChanged: (i) => setState(() {
                      _index = i;
                      _photoZoomed = false;
                    }),
                    itemBuilder: (context, pageIndex) {
                      return _FullscreenPhotoPage(
                        key: ValueKey(widget.files[pageIndex].id),
                        file: widget.files[pageIndex],
                        loadBytes: widget.loadBytes,
                        onZoomChanged: _onPhotoZoomChanged,
                      );
                    },
                  ),
                ),
                _PhotoGalleryActionBar(
                  file: file,
                  actions: widget.photoActions!,
                  onStateChanged: () => setState(() {}),
                ),
              ],
            ),
            Positioned(
              top: topPad + 6,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            if (widget.files.length > 1)
              Positioned(
                top: topPad + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        KiamiStrings.galleryPosition(
                          _index + 1,
                          widget.files.length,
                        ),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPopupScaffold(BuildContext context) {
    final file = _current;
    final topPad = MediaQuery.paddingOf(context).top;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    minimum: const EdgeInsets.only(top: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.files.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, pageIndex) {
                          return _FullscreenVideoPage(
                            key: ValueKey(widget.files[pageIndex].id),
                            file: widget.files[pageIndex],
                            loadMediaSource: widget.loadMediaSource,
                            isActive: pageIndex == _index,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _MediaDownloadDeleteBar(
                  file: file,
                  onDownload: () =>
                      widget.videoActions!.onDownload(file),
                  onDelete: () => widget.videoActions!.onDelete(file),
                ),
              ],
            ),
            Positioned(
              top: topPad + 6,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            if (widget.files.length > 1)
              Positioned(
                top: topPad + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        KiamiStrings.galleryPosition(
                          _index + 1,
                          widget.files.length,
                        ),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPopupScaffold(BuildContext context) {
    final file = _current;
    final topPad = MediaQuery.paddingOf(context).top;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    minimum: const EdgeInsets.only(top: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.files.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, pageIndex) {
                          return _FullscreenAudioPage(
                            key: ValueKey(widget.files[pageIndex].id),
                            file: widget.files[pageIndex],
                            loadMediaSource: widget.loadMediaSource,
                            isActive: pageIndex == _index,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _MediaDownloadDeleteBar(
                  file: file,
                  onDownload: () =>
                      widget.audioActions!.onDownload(file),
                  onDelete: () => widget.audioActions!.onDelete(file),
                ),
              ],
            ),
            Positioned(
              top: topPad + 6,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            if (widget.files.length > 1)
              Positioned(
                top: topPad + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        KiamiStrings.galleryPosition(
                          _index + 1,
                          widget.files.length,
                        ),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselArea({
    required double maxPhotoWidth,
    required double maxPhotoHeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KiamiSpacing.md),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _index = i),
        clipBehavior: Clip.none,
        itemBuilder: (context, pageIndex) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final page = _pageController.hasClients
                  ? (_pageController.page ?? _index.toDouble())
                  : _index.toDouble();
              final delta = (page - pageIndex).abs();
              final scale =
                  (1 - delta * 0.2).clamp(0.72, 1.0).toDouble();
              final opacity =
                  (1 - delta * 0.32).clamp(0.42, 1.0).toDouble();
              final lift = (1 - math.min(delta, 1.0)) * 4.0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KiamiSpacing.sm,
                ),
                child: Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  ),
                ),
              );
            },
            child: _VisualCarouselCard(
              key: ValueKey(widget.files[pageIndex].id),
              file: widget.files[pageIndex],
              isActive: pageIndex == _index,
              loadBytes: widget.loadBytes,
              loadMediaSource: widget.loadMediaSource,
              maxPhotoWidth: maxPhotoWidth,
              maxPhotoHeight: maxPhotoHeight,
              zoomEnabled: pageIndex == _index,
              onTap: pageIndex == _index ? null : () => _goTo(pageIndex),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisualCarouselScaffold(BuildContext context) {
    final file = _current;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? KiamiColors.darkBackground : KiamiColors.lightGray;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                KiamiStrings.galleryPosition(_index + 1, widget.files.length),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          actions: [
            if (widget.onDownload != null)
              IconButton(
                tooltip: KiamiStrings.downloadButton,
                onPressed: () => widget.onDownload!(file),
                icon: const Icon(Icons.download_outlined),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _buildCarouselArea(
                maxPhotoWidth: MediaQuery.sizeOf(context).width,
                maxPhotoHeight: MediaQuery.sizeOf(context).height,
              ),
            ),
            if (widget.photoActions != null)
              _PhotoGalleryActionBar(
                file: file,
                actions: widget.photoActions!,
                onStateChanged: () => setState(() {}),
              )
            else if (widget.files.length > 1)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  KiamiSpacing.md,
                  0,
                  KiamiSpacing.md,
                  KiamiSpacing.md + MediaQuery.paddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      label: const Text(KiamiStrings.galleryPrevious),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: _index < widget.files.length - 1
                          ? () => _goTo(_index + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      label: const Text(KiamiStrings.galleryNext),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: KiamiSpacing.md + MediaQuery.paddingOf(context).bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Foto em ecrã inteiro — duplo toque para zoom, pan horizontal.
class _FullscreenPhotoPage extends StatefulWidget {
  const _FullscreenPhotoPage({
    super.key,
    required this.file,
    required this.loadBytes,
    this.onZoomChanged,
  });

  final KiamiFile file;
  final Future<Uint8List> Function(KiamiFile file) loadBytes;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<_FullscreenPhotoPage> createState() => _FullscreenPhotoPageState();
}

class _FullscreenPhotoPageState extends State<_FullscreenPhotoPage>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;
  String? _error;
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_started) return;
    _started = true;
    try {
      _bytes = await widget.loadBytes(widget.file);
    } catch (_) {
      _error = KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (_bytes == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      );
    }

    return SizedBox.expand(
      child: FilePreviewPage(
        file: widget.file,
        kind: FilePreviewKind.image,
        bytes: _bytes,
        embedded: true,
        zoomEnabled: true,
        centeredGalleryZoom: true,
        onGalleryZoomChanged: widget.onZoomChanged,
      ),
    );
  }
}

/// Vídeo em ecrã inteiro (pop-up), sem zoom.
class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({
    super.key,
    required this.file,
    required this.loadMediaSource,
    required this.isActive,
  });

  final KiamiFile file;
  final Future<MediaSource> Function(KiamiFile file) loadMediaSource;
  final bool isActive;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage>
    with AutomaticKeepAliveClientMixin {
  MediaSource? _mediaSource;
  String? _error;
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_started) return;
    _started = true;
    try {
      _mediaSource = await widget.loadMediaSource(widget.file);
    } catch (_) {
      _error = KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (_mediaSource == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      );
    }

    return SizedBox.expand(
      child: FilePreviewPage(
        file: widget.file,
        kind: FilePreviewKind.video,
        mediaSource: _mediaSource,
        embedded: true,
        mediaPopupStyle: true,
        mediaActive: widget.isActive,
      ),
    );
  }
}

/// Áudio em cartão minimalista (pop-up).
class _FullscreenAudioPage extends StatefulWidget {
  const _FullscreenAudioPage({
    super.key,
    required this.file,
    required this.loadMediaSource,
    required this.isActive,
  });

  final KiamiFile file;
  final Future<MediaSource> Function(KiamiFile file) loadMediaSource;
  final bool isActive;

  @override
  State<_FullscreenAudioPage> createState() => _FullscreenAudioPageState();
}

class _FullscreenAudioPageState extends State<_FullscreenAudioPage>
    with AutomaticKeepAliveClientMixin {
  MediaSource? _mediaSource;
  String? _error;
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_started) return;
    _started = true;
    try {
      _mediaSource = await widget.loadMediaSource(widget.file);
    } catch (_) {
      _error = KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (_mediaSource == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      );
    }

    return SizedBox.expand(
      child: FilePreviewPage(
        file: widget.file,
        kind: FilePreviewKind.audio,
        mediaSource: _mediaSource,
        embedded: true,
        mediaPopupStyle: true,
        mediaActive: widget.isActive,
      ),
    );
  }
}

/// Cartão dimensionado à proporção da imagem ou vídeo.
class _VisualCarouselCard extends StatefulWidget {
  const _VisualCarouselCard({
    super.key,
    required this.file,
    required this.isActive,
    required this.loadBytes,
    required this.loadMediaSource,
    this.maxPhotoWidth,
    this.maxPhotoHeight,
    this.zoomEnabled = true,
    this.onTap,
  });

  final KiamiFile file;
  final bool isActive;
  final Future<Uint8List> Function(KiamiFile file) loadBytes;
  final Future<MediaSource> Function(KiamiFile file) loadMediaSource;
  final double? maxPhotoWidth;
  final double? maxPhotoHeight;
  final bool zoomEnabled;
  final VoidCallback? onTap;

  @override
  State<_VisualCarouselCard> createState() => _VisualCarouselCardState();
}

class _VisualCarouselCardState extends State<_VisualCarouselCard>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;
  MediaSource? _mediaSource;
  double? _aspectRatio;
  String? _error;
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<double?> _probeImageAspect(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      if (w <= 0 || h <= 0) return null;
      return w / h;
    } catch (_) {
      return null;
    }
  }

  Future<double?> _probeVideoAspect(MediaSource source) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(source.url),
        httpHeaders: source.headers,
      );
      await controller.initialize();
      final ar = controller.value.aspectRatio;
      return ar > 0 ? ar : 16 / 9;
    } catch (_) {
      return 16 / 9;
    } finally {
      await controller?.dispose();
    }
  }

  Future<void> _load() async {
    if (_started) return;
    _started = true;

    final kind = FilePreviewPage.kindFor(widget.file);
    try {
      if (kind == FilePreviewKind.video) {
        _mediaSource = await widget.loadMediaSource(widget.file);
        _aspectRatio = await _probeVideoAspect(_mediaSource!);
      } else {
        _bytes = await widget.loadBytes(widget.file);
        _aspectRatio = await _probeImageAspect(_bytes!) ?? 1.0;
      }
    } catch (_) {
      _error = KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = widget.maxPhotoWidth ?? constraints.maxWidth;
        final maxH = widget.maxPhotoHeight ?? constraints.maxHeight;
        final kind = FilePreviewPage.kindFor(widget.file);
        final ar = _aspectRatio ?? (16 / 9);
        final controlExtra =
            kind == FilePreviewKind.video ? 88.0 : 0.0;

        double cardW = maxW;
        double mediaH = cardW / ar;
        double cardH = mediaH + controlExtra;
        if (cardH > maxH) {
          cardH = maxH;
          mediaH = math.max(maxH - controlExtra, maxH * 0.5);
          cardW = mediaH * ar;
          cardH = mediaH + controlExtra;
        }

        return Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(KiamiDecorations.radiusXl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(KiamiDecorations.radiusXl),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.35 : 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final kind = FilePreviewPage.kindFor(widget.file);

    if (kind == FilePreviewKind.video && _mediaSource == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (kind == FilePreviewKind.image && _bytes == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_bytes == null && _mediaSource == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return FilePreviewPage(
      file: widget.file,
      kind: kind,
      bytes: _bytes,
      mediaSource: _mediaSource,
      embedded: true,
      zoomEnabled: widget.zoomEnabled,
    );
  }
}

class _GalleryFilePage extends StatefulWidget {
  const _GalleryFilePage({
    super.key,
    required this.file,
    required this.loadBytes,
    required this.loadMediaSource,
    this.onDownload,
  });

  final KiamiFile file;
  final Future<Uint8List> Function(KiamiFile file) loadBytes;
  final Future<MediaSource> Function(KiamiFile file) loadMediaSource;
  final void Function(KiamiFile file)? onDownload;

  @override
  State<_GalleryFilePage> createState() => _GalleryFilePageState();
}

class _GalleryFilePageState extends State<_GalleryFilePage>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;
  MediaSource? _mediaSource;
  String? _error;
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_started) return;
    _started = true;

    if (!FilePreviewPage.canPreview(widget.file)) return;

    final kind = FilePreviewPage.kindFor(widget.file);
    try {
      if (FilePreviewPage.isMediaKind(kind)) {
        _mediaSource = await widget.loadMediaSource(widget.file);
      } else {
        _bytes = await widget.loadBytes(widget.file);
      }
    } catch (_) {
      _error = KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!FilePreviewPage.canPreview(widget.file)) {
      return _UnsupportedPreview(
        file: widget.file,
        onDownload: widget.onDownload == null
            ? null
            : () => widget.onDownload!(widget.file),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final kind = FilePreviewPage.kindFor(widget.file);
    final isMedia = FilePreviewPage.isMediaKind(kind);

    if (isMedia && _mediaSource == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (!isMedia && _bytes == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return FilePreviewPage(
      file: widget.file,
      kind: kind,
      bytes: _bytes,
      mediaSource: _mediaSource,
      embedded: true,
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({
    required this.file,
    this.onDownload,
  });

  final KiamiFile file;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              file.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              KiamiStrings.galleryNoPreview,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (onDownload != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined),
                label: const Text(KiamiStrings.downloadButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoGalleryActionBar extends StatelessWidget {
  const _PhotoGalleryActionBar({
    required this.file,
    required this.actions,
    required this.onStateChanged,
  });

  final KiamiFile file;
  final PhotoGalleryActions actions;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    final isFavorite = actions.isFavorite(file.id);
    final bottom = MediaQuery.paddingOf(context).bottom;

    Future<void> run(Future<void> Function() task) async {
      await task();
      onStateChanged();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PhotoActionButton(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: KiamiStrings.photoGalleryFavorite,
                iconColor: isFavorite ? const Color(0xFFE53935) : null,
                onPressed: () => run(() => actions.onToggleFavorite(file)),
              ),
              _PhotoActionButton(
                icon: Icons.photo_album_outlined,
                label: KiamiStrings.photoGalleryAddTo,
                onPressed: () => run(() => actions.onAddToAlbum(file)),
              ),
              _PhotoActionButton(
                icon: Icons.delete_outline_rounded,
                label: KiamiStrings.photoGalleryDelete,
                onPressed: () async {
                  await actions.onDelete(file);
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaDownloadDeleteBar extends StatelessWidget {
  const _MediaDownloadDeleteBar({
    required this.file,
    required this.onDownload,
    required this.onDelete,
  });

  final KiamiFile file;
  final VoidCallback onDownload;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PhotoActionButton(
                icon: Icons.download_outlined,
                label: KiamiStrings.downloadButton,
                onPressed: onDownload,
              ),
              _PhotoActionButton(
                icon: Icons.delete_outline_rounded,
                label: KiamiStrings.photoGalleryDelete,
                onPressed: () async {
                  await onDelete();
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
