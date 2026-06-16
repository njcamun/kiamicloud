import 'file_category.dart';

/// Formatos de vídeo/áudio com reprodução fiável no player nativo
/// (ExoPlayer/AVPlayer). Streaming directo — sem limite de tamanho.
const _previewVideoExtensions = {
  'mp4', 'mov', 'm4v', 'webm', '3gp', 'mkv',
};

const _previewAudioExtensions = {
  'mp3', 'm4a', 'aac', 'wav', 'ogg', 'oga', 'flac', 'opus', 'amr',
};

bool canPreviewVideoFileName(String fileName) =>
    _previewVideoExtensions.contains(fileExtensionOf(fileName));

bool canPreviewAudioFileName(String fileName) =>
    _previewAudioExtensions.contains(fileExtensionOf(fileName));
