String guessMimeType(String fileName) {
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  return switch (ext) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'txt' => 'text/plain',
    'json' => 'application/json',
    'zip' => 'application/zip',
    'mp4' => 'video/mp4',
    'mp3' => 'audio/mpeg',
    _ => 'application/octet-stream',
  };
}
