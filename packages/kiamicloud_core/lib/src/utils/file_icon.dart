import 'package:flutter/material.dart';

import '../theme/kiami_colors.dart';

IconData fileIconForName(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => Icons.image_outlined,
    'mp4' || 'mov' || 'avi' => Icons.movie_outlined,
    'mp3' || 'wav' => Icons.audio_file_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'txt' || 'md' => Icons.description_outlined,
    'doc' || 'docx' => Icons.article_outlined,
    'xls' || 'xlsx' => Icons.table_chart_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

Color fileIconColorForName(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => Colors.red.shade700,
    'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => KiamiColors.cloudBlue,
    'mp4' || 'mov' => Colors.purple.shade700,
    'zip' || 'rar' => Colors.orange.shade800,
    _ => KiamiColors.primaryBlue,
  };
}
