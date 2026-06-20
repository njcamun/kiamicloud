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

/// Hoje / Ontem / data — para notificações (com hora).
String formatNotificationWhen(String iso) {
  try {
    final local = DateTime.parse(iso).toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final time = '$h:$min';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoje, $time';
    if (diff == 1) return 'Ontem, $time';
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year} · $time';
  } catch (_) {
    return iso.length > 16 ? iso.substring(0, 16) : iso;
  }
}
