/// Limite para pré-visualização de texto (evita carregar ficheiros enormes).
const int kTextPreviewMaxBytes = 512 * 1024;

const _textExtensions = {
  'txt',
  'md',
  'markdown',
  'log',
  'csv',
  'tsv',
  'json',
  'xml',
  'yaml',
  'yml',
  'ini',
  'cfg',
  'conf',
  'rtf',
  'adoc',
  'rst',
};

bool canPreviewTextFileName(String fileName) {
  if (!fileName.contains('.')) return false;
  final ext = fileName.split('.').last.toLowerCase();
  return _textExtensions.contains(ext);
}
