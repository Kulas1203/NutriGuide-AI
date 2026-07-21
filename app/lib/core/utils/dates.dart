import 'package:intl/intl.dart';

/// Date helpers. Diary data is keyed by the user's local calendar day so a
/// meal logged at 23:59 stays on that day regardless of timezone offset.
abstract final class Dates {
  /// Canonical storage key for a local calendar day, e.g. `2026-07-21`.
  static String dayKey(DateTime local) =>
      DateFormat('yyyy-MM-dd').format(local);

  static DateTime parseDayKey(String key) => DateTime.parse(key);

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Local start of the week (Monday).
  static DateTime startOfWeek(DateTime d) =>
      startOfDay(d).subtract(Duration(days: d.weekday - DateTime.monday));

  /// Day keys for the last [count] days ending with [end] (inclusive),
  /// oldest first.
  static List<String> lastDays(DateTime end, int count) {
    final endDay = startOfDay(end);
    return List.generate(
      count,
      (i) => dayKey(endDay.subtract(Duration(days: count - 1 - i))),
    );
  }

  static String friendly(DateTime d, {DateTime? now}) {
    final today = startOfDay(now ?? DateTime.now());
    final day = startOfDay(d);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(d);
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  static String formatClock(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
