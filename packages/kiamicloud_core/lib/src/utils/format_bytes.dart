import '../constants/kiami_strings.dart';

/// Limite de transferência por ficheiro — 0 ou negativo = sem limite.
String formatTransferLimit(int bytes) =>
    bytes <= 0 ? KiamiStrings.noTransferLimit : formatBytes(bytes);

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  final gb = bytes / (1024 * 1024 * 1024);
  final rounded = gb.roundToDouble();
  if ((gb - rounded).abs() < 0.05) {
    return '${rounded.toInt()} GB';
  }
  return '${gb.toStringAsFixed(1)} GB';
}
