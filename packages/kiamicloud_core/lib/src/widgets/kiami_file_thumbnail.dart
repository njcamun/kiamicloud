import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/kiami_file.dart';
import '../features/files/providers/file_thumbnail_provider.dart';
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
              return Image.network(
                thumb.url,
                headers: thumb.headers,
                height: h > 0 ? h : height,
                width: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 320,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _iconBox(icon, iconColor, radius),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _iconBox(icon, iconColor, radius);
                },
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
