import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Envolve a zona de upload para aceitar arrastar ficheiros (web e desktop).
class UploadDropTarget extends StatefulWidget {
  const UploadDropTarget({
    super.key,
    required this.enabled,
    required this.onFilesDropped,
    required this.child,
  });

  final bool enabled;
  final ValueChanged<List<PlatformFile>> onFilesDropped;
  final Widget child;

  static bool get isSupported {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux =>
        true,
      _ => false,
    };
  }

  @override
  State<UploadDropTarget> createState() => _UploadDropTargetState();
}

class _UploadDropTargetState extends State<UploadDropTarget> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    if (!UploadDropTarget.isSupported) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (_) {
        if (widget.enabled) setState(() => _dragging = true);
      },
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        setState(() => _dragging = false);
        if (!widget.enabled) return;
        final files = <PlatformFile>[];
        for (final x in details.files) {
          if (kIsWeb) {
            final bytes = await x.readAsBytes();
            if (bytes.isEmpty) continue;
            files.add(
              PlatformFile(
                name: x.name,
                size: bytes.length,
                bytes: Uint8List.fromList(bytes),
              ),
            );
          } else {
            final length = await x.length();
            files.add(
              PlatformFile(
                name: x.name,
                size: length,
                path: x.path,
              ),
            );
          }
        }
        if (files.isNotEmpty) widget.onFilesDropped(files);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: _dragging
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
