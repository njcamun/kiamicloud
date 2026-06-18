import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_decorations.dart';
import '../../../theme/kiami_spacing.dart';
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
  });

  final KiamiFile file;
  final FilePreviewKind kind;

  /// Conteúdo carregado (imagem, texto, PDF, docx).
  final Uint8List? bytes;

  /// URL + headers para streaming (vídeo, áudio).
  final MediaSource? mediaSource;

  /// Sem AppBar — usado dentro da galeria.
  final bool embedded;

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
      FilePreviewKind.image => _ImageBody(bytes: bytes!),
      FilePreviewKind.docx => _DocxBody(bytes: bytes!),
      FilePreviewKind.video => _MediaBody(
          source: mediaSource!,
          isAudio: false,
          fileName: file.name,
        ),
      FilePreviewKind.audio => _MediaBody(
          source: mediaSource!,
          isAudio: true,
          fileName: file.name,
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _FilePreviewLoader(
          file: file,
          kind: kind,
          loadBytes: isMedia ? null : loadBytes,
          loadMediaSource: isMedia ? loadMediaSource : null,
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (FilePreviewPage.isMediaKind(widget.kind)) {
        _mediaSource = await widget.loadMediaSource!();
      } else {
        _bytes = await widget.loadBytes!();
      }
    } catch (_) {
      _error = KiamiStrings.previewLoadError;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: _PreviewMessage(
          icon: Icons.error_outline_rounded,
          message: _error!,
        ),
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
  const _ImageBody({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        child: Image.memory(bytes, fit: BoxFit.contain),
      ),
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
      return const _PreviewMessage(
        icon: Icons.description_outlined,
        message: KiamiStrings.previewDocxError,
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
  });

  final MediaSource source;
  final bool isAudio;
  final String fileName;

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
      await controller.play();
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
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _PreviewMessage(
        icon: widget.isAudio
            ? Icons.audiotrack_outlined
            : Icons.movie_outlined,
        message: KiamiStrings.previewMediaError,
      );
    }
    final controller = _controller;
    if (!_ready || controller == null) {
      return widget.isAudio
          ? _AudioLoadingPlaceholder(fileName: widget.fileName)
          : const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            );
    }

    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? KiamiColors.darkBackground
          : KiamiColors.lightGray,
      child: Column(
        children: [
          Expanded(
            child: widget.isAudio
                ? _AudioArtwork(fileName: widget.fileName)
                : Center(
                    child: AspectRatio(
                      aspectRatio: value.aspectRatio > 0
                          ? value.aspectRatio
                          : 16 / 9,
                      child: VideoPlayer(controller),
                    ),
                  ),
          ),
          _MediaControlBar(
            position: position,
            duration: duration,
            isPlaying: value.isPlaying,
            isAudio: widget.isAudio,
            onSeek: duration.inMilliseconds > 0
                ? (v) =>
                    controller.seekTo(Duration(milliseconds: v.round()))
                : null,
            onPlayPause: () {
              value.isPlaying ? controller.pause() : controller.play();
            },
            onRewind: () {
              final next = position - const Duration(seconds: 10);
              controller.seekTo(
                next < Duration.zero ? Duration.zero : next,
              );
            },
            onForward: () {
              final next = position + const Duration(seconds: 10);
              controller.seekTo(
                next > duration ? duration : next,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AudioLoadingPlaceholder extends StatelessWidget {
  const _AudioLoadingPlaceholder({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: KiamiSpacing.md),
          Text(
            fileName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _AudioArtwork extends StatelessWidget {
  const _AudioArtwork({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KiamiDecorations.radiusXl),
              gradient: KiamiColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: KiamiColors.primaryBlue.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 88,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: KiamiSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KiamiSpacing.xl),
            child: Text(
              fileName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: KiamiSpacing.sm),
          Text(
            KiamiStrings.categoryAudio,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KiamiColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _MediaControlBar extends StatelessWidget {
  const _MediaControlBar({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isAudio,
    required this.onPlayPause,
    required this.onRewind,
    required this.onForward,
    this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isAudio;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final ValueChanged<double>? onSeek;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: isDark
              ? KiamiColors.darkSurfaceElevated
              : KiamiColors.lightSurface,
          borderRadius: BorderRadius.circular(KiamiDecorations.radiusCard),
          boxShadow: KiamiDecorations.cardShadowLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: duration.inMilliseconds > 0
                    ? position.inMilliseconds
                        .clamp(0, duration.inMilliseconds)
                        .toDouble()
                    : 0,
                max: duration.inMilliseconds > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1,
                onChanged: onSeek,
              ),
            ),
            Row(
              children: [
                Text(
                  _fmt(position),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '-10s',
                  onPressed: onRewind,
                  icon: const Icon(Icons.replay_10_rounded),
                ),
                FilledButton(
                  onPressed: onPlayPause,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 32,
                  ),
                ),
                IconButton(
                  tooltip: '+10s',
                  onPressed: onForward,
                  icon: const Icon(Icons.forward_10_rounded),
                ),
                const Spacer(),
                Text(
                  _fmt(duration),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
