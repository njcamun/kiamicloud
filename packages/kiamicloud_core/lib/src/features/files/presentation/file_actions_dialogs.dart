import 'package:flutter/material.dart';

import '../../../constants/kiami_strings.dart';

Future<String?> showRenameFileDialog(
  BuildContext context, {
  required String currentName,
}) {
  final controller = TextEditingController(text: currentName);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(KiamiStrings.fileRenameTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: KiamiStrings.fileRename,
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text(KiamiStrings.fileRename),
        ),
      ],
    ),
  );
}

Future<bool> showDeleteFileDialog(BuildContext context) {
  return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(KiamiStrings.fileDeleteTitle),
          content: const Text(KiamiStrings.fileDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(KiamiStrings.cancelButton),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(KiamiStrings.fileDelete),
            ),
          ],
        ),
      ).then((v) => v ?? false);
}
