import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import 'file_preview_page.dart';

/// Galeria fluida — deslize ou setas para o ficheiro anterior/seguinte.
class FileGalleryPage extends StatefulWidget {
  const FileGalleryPage({
    super.key,
    required this.files,
    required this.initialIndex,
    required this.loadBytes,
    required this.loadMediaSource,
    this.onDownload,
  });

  final List<KiamiFile> files;
  final int initialIndex;
  final Future<Uint8List> Function(KiamiFile file) loadBytes;
  final Future<MediaSource> Function(KiamiFile file) loadMediaSource;
  final void Function(KiamiFile file)? onDownload;

  static Future<void> open(
    BuildContext context, {
    required List<KiamiFile> files,
    required int initialIndex,
    required Future<Uint8List> Function(KiamiFile file) loadBytes,
    required Future<MediaSource> Function(KiamiFile file) loadMediaSource,
    void Function(KiamiFile file)? onDownload,
  }) {
    if (files.isEmpty) return Future.value();
    final index = initialIndex.clamp(0, files.length - 1);
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => FileGalleryPage(
          files: files,
          initialIndex: index,
          loadBytes: loadBytes,
          loadMediaSource: loadMediaSource,
          onDownload: onDownload,
        ),
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
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.files.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  KiamiFile get _current => widget.files[_index];

  void _goTo(int next) {
    if (next < 0 || next >= widget.files.length) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
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
              onPressed:
                  _index < widget.files.length - 1 ? () => _goTo(_index + 1) : null,
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
            final pageFile = widget.files[pageIndex];
            return _GalleryFilePage(
              key: ValueKey(pageFile.id),
              file: pageFile,
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
                        onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
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
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
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
