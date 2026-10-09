/// Deterministic ISO-8601 calendar week representation and calculation.
///
/// Follows standard ISO-8601 rules:
/// - Weeks start on Monday (weekday 1) and end on Sunday (weekday 7).
/// - Week 1 of any calendar year is the week containing the first Thursday of that year.
/// - Stable format key: `YYYY-Www` (e.g., `2026-W41`).
class IsoWeek {
  /// The ISO-8601 week year (may differ from calendar year for days near Jan 1 / Dec 31).
  final int year;

  /// The 1-based ISO-8601 week number (1 to 53).
  final int weekNumber;

  /// Monday 00:00:00 of the week.
  final DateTime startOfWeek;

  /// Sunday 23:59:59 (normalized to date day) of the week.
  final DateTime endOfWeek;

  /// Stable key string, e.g. `2026-W41`.
  final String weekKey;

  /// Human-readable label, e.g. `Week 41`.
  final String label;

  /// Formatted date range label, e.g. `Oct 5 – Oct 11, 2026`.
  final String dateRangeLabel;

  const IsoWeek({
    required this.year,
    required this.weekNumber,
    required this.startOfWeek,
    required this.endOfWeek,
    required this.weekKey,
    required this.label,
    required this.dateRangeLabel,
  });

  /// Derives the ISO-8601 week for any given [date].
  factory IsoWeek.fromDateTime(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    // Thursday of the current week determines the ISO week year.
    final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
    final isoYear = thursday.year;

    // First Thursday of the ISO year (Jan 4 is always in week 1).
    final jan4 = DateTime(isoYear, 1, 4);
    final firstThursdayOfWeek1 = jan4.add(Duration(days: 4 - jan4.weekday));

    // Week number calculation: 1 + (days between Thursdays ~/ 7).
    final diffDays = thursday.difference(firstThursdayOfWeek1).inDays;
    final weekNumber = (diffDays ~/ 7) + 1;

    // Monday (start) and Sunday (end) of the current week.
    final monday = normalized.subtract(Duration(days: normalized.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final weekKey = '$isoYear-W${weekNumber.toString().padLeft(2, '0')}';
    final label = 'Week $weekNumber';
    final dateRangeLabel = _formatDateRange(monday, sunday);

    return IsoWeek(
      year: isoYear,
      weekNumber: weekNumber,
      startOfWeek: monday,
      endOfWeek: sunday,
      weekKey: weekKey,
      label: label,
      dateRangeLabel: dateRangeLabel,
    );
  }

  /// Returns the 7 canonical date strings (`YYYY-MM-DD`) strictly belonging to this week (Monday to Sunday).
  List<String> get dayDateKeys {
    return List.generate(7, (i) {
      final d = startOfWeek.add(Duration(days: i));
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    });
  }

  /// Checks whether a given [DateTime] falls strictly within this ISO week.
  bool containsDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
  }

  static String _formatDateRange(DateTime start, DateTime end) {
    const months = [
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
    final startMonth = months[start.month - 1];
    final endMonth = months[end.month - 1];

    if (start.year == end.year) {
      if (start.month == end.month) {
        return '$startMonth ${start.day} – ${end.day}, ${start.year}';
      }
      return '$startMonth ${start.day} – $endMonth ${end.day}, ${start.year}';
    }
    return '$startMonth ${start.day}, ${start.year} – $endMonth ${end.day}, ${end.year}';
  }
}
