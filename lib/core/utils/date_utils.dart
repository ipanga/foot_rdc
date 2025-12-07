String _two(int n) => n.toString().padLeft(2, '0');

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a GMT DateTime for display in the device local timezone.
///
/// - If the date is the same day as the device local date, returns "HH:mm".
/// - If older, returns "dd-MMM-yy" (e.g. 05-Sep-25).
String formatArticleDate(DateTime gmtDate) {
  // Ensure we interpret the input as UTC/GMT.
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
  final now = DateTime.now();

  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;

  if (sameDay) {
    return '${_two(local.hour)}:${_two(local.minute)}';
  } else {
    final dd = _two(local.day);
    final mmm = _months[local.month - 1];
    final yy = _two(local.year % 100);
    return '$dd-$mmm-$yy';
  }
}
