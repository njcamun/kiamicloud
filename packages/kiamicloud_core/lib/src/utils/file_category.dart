import 'package:flutter/material.dart';

import '../api/models/kiami_file.dart';
import '../assets/kiami_assets.dart';
import '../constants/kiami_strings.dart';

/// Categorias de ficheiros (pastas virtuais no dashboard).
enum KiamiFileCategory {
  images,
  documents,
  video,
  audio,
  other,
  unknown;

  static const List<KiamiFileCategory> displayOrder = [
    images,
    documents,
    video,
    audio,
    other,
    unknown,
  ];

  String get label => switch (this) {
        KiamiFileCategory.images => KiamiStrings.categoryImages,
        KiamiFileCategory.documents => KiamiStrings.categoryDocuments,
        KiamiFileCategory.video => KiamiStrings.categoryVideo,
        KiamiFileCategory.audio => KiamiStrings.categoryAudio,
        KiamiFileCategory.other => KiamiStrings.categoryOthers,
        KiamiFileCategory.unknown => KiamiStrings.categoryUnknown,
      };

  IconData get icon => switch (this) {
        KiamiFileCategory.images => Icons.photo_library_outlined,
        KiamiFileCategory.documents => Icons.description_outlined,
        KiamiFileCategory.video => Icons.movie_outlined,
        KiamiFileCategory.audio => Icons.audiotrack_outlined,
        KiamiFileCategory.other => Icons.folder_outlined,
        KiamiFileCategory.unknown => Icons.help_outline_rounded,
      };

  Color get accentColor => switch (this) {
        KiamiFileCategory.images => const Color(0xFF00A3E0),
        KiamiFileCategory.documents => const Color(0xFF1565FF),
        KiamiFileCategory.video => const Color(0xFF7C3AED),
        KiamiFileCategory.audio => const Color(0xFF059669),
        KiamiFileCategory.other => const Color(0xFF64748B),
        KiamiFileCategory.unknown => const Color(0xFF94A3B8),
      };

  /// PNG do card (tema claro).
  String get illustrationAssetLight => switch (this) {
        KiamiFileCategory.images => KiamiAssets.categoryImagesPng,
        KiamiFileCategory.documents => KiamiAssets.categoryDocumentsPng,
        KiamiFileCategory.video => KiamiAssets.categoryVideoPng,
        KiamiFileCategory.audio => KiamiAssets.categoryAudioPng,
        KiamiFileCategory.other => KiamiAssets.categoryOthersPng,
        KiamiFileCategory.unknown => KiamiAssets.categoryUnknownPng,
      };

  /// PNG do card (tema escuro; fallback para claro se `_dark` nao existir).
  String? get illustrationAssetDark => switch (this) {
        KiamiFileCategory.images => KiamiAssets.categoryImagesDarkPng,
        KiamiFileCategory.documents => KiamiAssets.categoryDocumentsDarkPng,
        KiamiFileCategory.video => KiamiAssets.categoryVideoDarkPng,
        KiamiFileCategory.audio => KiamiAssets.categoryAudioDarkPng,
        KiamiFileCategory.other => KiamiAssets.categoryOthersDarkPng,
        KiamiFileCategory.unknown => KiamiAssets.categoryUnknownDarkPng,
      };

  String illustrationAssetFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return illustrationAssetDark ?? illustrationAssetLight;
    }
    return illustrationAssetLight;
  }

  /// Parâmetro de rota (`/home/category/:categoryId`).
  String get routeId => name;

  static KiamiFileCategory? fromRouteId(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final c in KiamiFileCategory.values) {
      if (c.name == value) return c;
    }
    return null;
  }
}

const _audioExtensions = {
  'mp3', 'wav', 'aac', 'ogg', 'oga', 'flac', 'm4a', 'wma', 'aiff', 'aif',
  'opus', 'mid', 'midi', 'amr', 'ape', 'wv',
};

const _videoExtensions = {
  'mp4', 'wmv', 'avi', 'mov', 'mkv', 'webm', 'm4v', 'flv', 'mpg', 'mpeg',
  '3gp', '3g2', 'ts', 'm2ts', 'vob', 'ogv',
};

const _documentExtensions = {
  'pdf', 'doc', 'docx', 'dot', 'dotx', 'xls', 'xlsx', 'xlsm', 'ppt', 'pptx',
  'txt', 'rtf', 'odt', 'ods', 'odp', 'md', 'csv', 'tsv', 'pages', 'numbers',
  'key', 'tex', 'epub', 'mobi', 'log', 'rst', 'adoc',
};

const _imageExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'tif', 'svg', 'ico',
  'heic', 'heif', 'raw', 'cr2', 'nef', 'arw', 'dng', 'psd', 'avif', 'jfif',
};

/// Arquivos compactados, codigo e formatos comuns (recomendados em «Outros»).
const _otherExtensions = {
  'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'z', 'cab',
  'json', 'xml', 'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf',
  'html', 'htm', 'css', 'scss', 'less',
  'js', 'mjs', 'cjs', 'ts', 'tsx', 'jsx', 'vue', 'dart', 'py', 'java', 'kt',
  'swift', 'go', 'rs', 'cpp', 'cc', 'c', 'h', 'hpp', 'cs', 'php', 'rb', 'sh',
  'sql', 'wasm', 'map', 'lock',
};

/// Executaveis e tipos nao recomendados para armazenamento na cloud.
const _notRecommendedExtensions = {
  'exe', 'msi', 'msp', 'bat', 'cmd', 'com', 'scr', 'pif', 'vbs', 'vbe',
  'ps1', 'psm1', 'reg', 'inf', 'dll', 'sys', 'drv', 'ocx', 'cpl',
  'apk', 'aab', 'ipa', 'deb', 'rpm', 'dmg', 'pkg', 'app', 'appx',
  'iso', 'img', 'bin', 'toast', 'action',
};

/// Extensao sem ponto (minusculas), ou vazio se nao houver.
String fileExtensionOf(String filename) {
  final trimmed = filename.trim();
  final dot = trimmed.lastIndexOf('.');
  if (dot <= 0 || dot >= trimmed.length - 1) return '';
  return trimmed.substring(dot + 1).toLowerCase();
}

/// Classifica um ficheiro pela extensao do nome.
KiamiFileCategory fileCategoryForName(String filename) {
  final ext = fileExtensionOf(filename);

  if (ext.isEmpty) return KiamiFileCategory.unknown;
  if (_notRecommendedExtensions.contains(ext)) {
    return KiamiFileCategory.unknown;
  }
  if (_imageExtensions.contains(ext)) return KiamiFileCategory.images;
  if (_documentExtensions.contains(ext)) return KiamiFileCategory.documents;
  if (_videoExtensions.contains(ext)) return KiamiFileCategory.video;
  if (_audioExtensions.contains(ext)) return KiamiFileCategory.audio;
  if (_otherExtensions.contains(ext)) return KiamiFileCategory.other;

  return KiamiFileCategory.unknown;
}

/// Agrupa ficheiros por categoria; ordena por nome dentro de cada pasta.
Map<KiamiFileCategory, List<KiamiFile>> groupFilesByCategory(
  List<KiamiFile> files,
) {
  final grouped = {
    for (final c in KiamiFileCategory.displayOrder) c: <KiamiFile>[],
  };

  for (final file in files) {
    grouped[fileCategoryForName(file.name)]!.add(file);
  }

  for (final list in grouped.values) {
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  return grouped;
}

/// Categorias com pelo menos um ficheiro, na ordem de apresentacao.
List<MapEntry<KiamiFileCategory, List<KiamiFile>>> nonEmptyFileCategories(
  Map<KiamiFileCategory, List<KiamiFile>> grouped,
) {
  return KiamiFileCategory.displayOrder
      .map((c) => MapEntry(c, grouped[c]!))
      .where((e) => e.value.isNotEmpty)
      .toList();
}
