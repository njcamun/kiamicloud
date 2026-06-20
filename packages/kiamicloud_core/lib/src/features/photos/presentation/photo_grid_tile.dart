import 'package:flutter/material.dart';

import '../../../api/models/kiami_file.dart';
import '../../../theme/kiami_colors.dart';
import '../../../widgets/kiami_file_thumbnail.dart';

/// Tile de foto com favorito em baixo e suporte a selecção (long press).
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    super.key,
    required this.file,
    required this.isFavorite,
    required this.onOpen,
    required this.onToggleFavorite,
    this.selected = false,
    this.selectionMode = false,
    this.onLongPress,
    this.onSelectToggle,
  });

  final KiamiFile file;
  final bool isFavorite;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: selectionMode ? onSelectToggle : onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: KiamiFileThumbnail(
                        file: file,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (selectionMode)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: selected
                                ? KiamiColors.primaryBlue.withValues(alpha: 0.22)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                          child: selected
                              ? Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: KiamiColors.primaryBlue,
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleFavorite,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: isFavorite
                    ? const Color(0xFFE53935)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
