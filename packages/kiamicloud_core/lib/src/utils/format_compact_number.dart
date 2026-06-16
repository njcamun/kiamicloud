String formatCompactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return k >= 100 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
  }
  if (n < 1000000000) {
    final m = n / 1000000;
    return m >= 100 ? '${m.round()}M' : '${m.toStringAsFixed(1)}M';
  }
  final b = n / 1000000000;
  return '${b.toStringAsFixed(1)}B';
}
