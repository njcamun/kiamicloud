import '../../../api/models/kiami_file.dart';
import '../../../constants/kiami_strings.dart';

/// Grupo de ficheiros num mesmo dia (data local).
class PhotoDayGroup {
  const PhotoDayGroup({
    required this.day,
    required this.label,
    required this.files,
  });

  final DateTime day;
  final String label;
  final List<KiamiFile> files;
}

DateTime fileLocalDate(KiamiFile file) {
  try {
    return DateTime.parse(file.createdAt).toLocal();
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

const _ptMonths = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

String formatPhotoDayLabel(DateTime day, {DateTime? now}) {
  final reference = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(day);
  if (target == reference) return KiamiStrings.photosToday;
  if (target == reference.subtract(const Duration(days: 1))) {
    return KiamiStrings.photosYesterday;
  }
  return '${target.day} ${_ptMonths[target.month - 1]} ${target.year}';
}

/// Agrupa ficheiros por dia de criação (ordem descendente por dia).
List<PhotoDayGroup> groupFilesByDay(List<KiamiFile> files) {
  if (files.isEmpty) return [];

  final byDay = <DateTime, List<KiamiFile>>{};
  for (final file in files) {
    final day = _dateOnly(fileLocalDate(file));
    byDay.putIfAbsent(day, () => []).add(file);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  return days
      .map(
        (day) => PhotoDayGroup(
          day: day,
          label: formatPhotoDayLabel(day),
          files: byDay[day]!,
        ),
      )
      .toList();
}
