import '../models/alarm_config.dart';

/// Pure next-fire-time math for alarms — no plugins, fully unit-testable
/// (including across day/week boundaries).
///
/// [activeDays] is indexed Sun..Sat (0..6). For smart alarms the fire time is
/// the *start* of the wake window (`time - windowMinutes`); for standard alarms
/// it's exactly `time`.
class AlarmScheduling {
  const AlarmScheduling._();

  /// Fire minutes-since-midnight for the alarm (may be negative if a smart
  /// window pushes it before midnight — handled by Duration math below).
  static int fireMinutes(AlarmConfig a) =>
      a.type == AlarmType.smart ? a.time - (a.windowMinutes ?? 0) : a.time;

  /// All fire times strictly after [from] within the next [days] days.
  static List<DateTime> occurrences(
    AlarmConfig a,
    DateTime from, {
    int days = 7,
  }) {
    final result = <DateTime>[];
    final today = DateTime(from.year, from.month, from.day);
    for (var d = 0; d <= days; d++) {
      final day = today.add(Duration(days: d));
      final weekdayIndex = day.weekday % 7; // Mon=1..Sun=7 → Sun=0..Sat=6
      if (!a.activeDays[weekdayIndex]) continue;
      final fire = DateTime(day.year, day.month, day.day)
          .add(Duration(minutes: fireMinutes(a)));
      if (fire.isAfter(from)) result.add(fire);
    }
    result.sort();
    // Trim to those within the requested horizon.
    final horizon = from.add(Duration(days: days));
    return result.where((t) => !t.isAfter(horizon)).toList();
  }

  /// The single next fire time after [from], or null if no active days.
  static DateTime? nextFireTime(AlarmConfig a, DateTime from) {
    if (!a.activeDays.contains(true)) return null;
    // Look 8 days ahead so a same-weekday-only alarm that already passed today
    // still resolves to next week.
    final all = occurrences(a, from, days: 8);
    return all.isEmpty ? null : all.first;
  }
}
