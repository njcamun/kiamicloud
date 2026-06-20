import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/kiami_file.dart';
import '../features/files/providers/file_thumbnail_provider.dart';
import '../features/files/providers/files_providers.dart';
import '../theme/kiami_decorations.dart';
import '../utils/file_icon.dart';

/// Miniatura na grelha (URL presigned ou dev directo). Fallback para icone.
class KiamiFileThumbnail extends ConsumerWidget {
  const KiamiFileThumbnail({
    super.key,
    required this.file,
    this.height = 52,
    this.borderRadius,
  });

  final KiamiFile file;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius =
        borderRadius ?? BorderRadius.circular(KiamiDecorations.radiusMd);
    final icon = fileIconForName(file.name);
    final iconColor = fileIconColorForName(file.name);

    if (!file.hasThumbnail) {
      return _iconBox(icon, iconColor, radius);
    }

    final thumbAsync = ref.watch(fileThumbnailUrlProvider(file.id));

    return thumbAsync.when(
      data: (thumb) {
        if (thumb == null || thumb.isExpired) {
          return _iconBox(icon, iconColor, radius);
        }
        return ClipRRect(
          borderRadius: radius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = height == double.infinity
                  ? constraints.maxHeight
                  : height;
              return _ThumbImage(
                url: thumb.url,
                headers: thumb.headers,
                useAuthenticatedFetch: thumb.usesAuthenticatedFetch,
                height: h > 0 ? h : height,
                fallback: _iconBox(icon, iconColor, radius),
              );
            },
          ),
        );
      },
      loading: () => _iconBox(icon, iconColor, radius),
      error: (_, __) => _iconBox(icon, iconColor, radius),
    );
  }

  Widget _iconBox(IconData icon, Color iconColor, BorderRadius radius) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: radius,
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}

class _ThumbImage extends ConsumerStatefulWidget {
  const _ThumbImage({
    required this.url,
    required this.headers,
    required this.useAuthenticatedFetch,
    required this.height,
    required this.fallback,
  });

  final String url;
  final Map<String, String> headers;
  final bool useAuthenticatedFetch;
  final double height;
  final Widget fallback;

  @override
  ConsumerState<_ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends ConsumerState<_ThumbImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.useAuthenticatedFetch) {
      _loadAuthenticated();
    }
  }

  @override
  void didUpdateWidget(covariant _ThumbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useAuthenticatedFetch &&
        (oldWidget.url != widget.url ||
            oldWidget.headers != widget.headers)) {
      _bytes = null;
      _failed = false;
      _loadAuthenticated();
    }
  }

  Future<void> _loadAuthenticated() async {
    try {
      final bytes = await ref.read(kiamiApiClientProvider).fetchAuthenticatedBytes(
            widget.url,
            headers: widget.headers,
          );
      if (!mounted) return;
      setState(() => _bytes = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;

    if (widget.useAuthenticatedFetch) {
      final bytes = _bytes;
      if (bytes == null) return widget.fallback;
      return Image.memory(
        bytes,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => widget.fallback,
      );
    }

    return Image.network(
      widget.url,
      headers: widget.headers,
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 320,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => widget.fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return widget.fallback;
      },
    );
  }
}
