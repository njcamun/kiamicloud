String formatFileDate(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fileDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(fileDay).inDays;

    if (diff == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hoje, $h:$m';
    }
    if (diff == 1) return 'Ontem';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  } catch (_) {
    return iso;
  }
}
