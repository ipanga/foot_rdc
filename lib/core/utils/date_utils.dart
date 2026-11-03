String _two(int n) => n.toString().padLeft(2, '0');

const List<String> _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// An article's publication date, in French and in the device's time zone:
/// - today: "14:05";
/// - yesterday: "Hier";
/// - this year: "2 nov.";
/// - earlier: "2 nov. 2025".
String formatArticleDate(DateTime gmtDate, {DateTime? now}) {
  // The API gives GMT without a zone marker: read it as UTC.
  final utc = gmtDate.isUtc
      ? gmtDate
      : DateTime.utc(
          gmtDate.year,
          gmtDate.month,
          gmtDate.day,
          gmtDate.hour,
          gmtDate.minute,
          gmtDate.second,
          gmtDate.millisecond,
          gmtDate.microsecond,
        );
  final local = utc.toLocal();
  final today = now ?? DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final days = todayDay.difference(day).inDays;

  if (days == 0) return '${_two(local.hour)}:${_two(local.minute)}';
  if (days == 1) return 'Hier';
  final short = '${local.day} ${_months[local.month - 1]}';
  return local.year == today.year ? short : '$short ${local.year}';
}
