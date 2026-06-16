/// Limite para pré-visualização de PDF (evita OOM em ficheiros muito grandes).
const int kPdfPreviewMaxBytes = 10 * 1024 * 1024;

bool canPreviewPdfFileName(String fileName) {
  if (!fileName.contains('.')) return false;
  return fileName.split('.').last.toLowerCase() == 'pdf';
}

bool canPreviewPdfFile(String fileName, int sizeBytes) {
  return canPreviewPdfFileName(fileName) && sizeBytes <= kPdfPreviewMaxBytes;
}
