/// A span of phone activity, derived from app-usage data.
class ActiveInterval {
  final DateTime start;
  final DateTime end;
  const ActiveInterval(this.start, this.end);
}

/// The inferred sleep window (a long idle stretch overnight).
class SleepWindow {
  final DateTime start;
  final DateTime end;
  const SleepWindow(this.start, this.end);

  Duration get duration => end.difference(start);
}

/// Pure idle-window detection — no plugins, no clock, fully unit-testable.
///
/// Given phone-activity intervals over the last [lookback], finds the longest
/// contiguous *inactive* window that (a) lasts at least [minSleep] and (b) whose
/// midpoint falls within the overnight band 22:00–09:00 local time.
///
/// LIMITATIONS (see also AutoTrackingService):
///  - App-usage data can't tell "asleep" from "phone idle on the nightstand
///    while watching TV".
///  - Daytime naps are filtered out by the overnight midpoint rule.
class IdleWindowDetector {
  const IdleWindowDetector({
    this.minSleep = const Duration(hours: 4),
    this.lookback = const Duration(hours: 24),
    this.nightStartHour = 22,
    this.nightEndHour = 9,
  });

  final Duration minSleep;
  final Duration lookback;
  final int nightStartHour; // inclusive
  final int nightEndHour; // exclusive

  SleepWindow? detect({
    required List<ActiveInterval> activity,
    required DateTime now,
  }) {
    final lowerBound = now.subtract(lookback);

    // Clamp activity to the look-back window and drop empties.
    final clamped = <ActiveInterval>[];
    for (final a in activity) {
      final s = a.start.isBefore(lowerBound) ? lowerBound : a.start;
      final e = a.end.isAfter(now) ? now : a.end;
      if (e.isAfter(s)) clamped.add(ActiveInterval(s, e));
    }
    clamped.sort((a, b) => a.start.compareTo(b.start));

    // Merge overlapping / touching intervals.
    final merged = <ActiveInterval>[];
    for (final a in clamped) {
      if (merged.isEmpty || a.start.isAfter(merged.last.end)) {
        merged.add(a);
      } else if (a.end.isAfter(merged.last.end)) {
        merged[merged.length - 1] = ActiveInterval(merged.last.start, a.end);
      }
    }

    // Scan the gaps between activity (plus the leading/trailing gaps).
    SleepWindow? best;
    void consider(DateTime start, DateTime end) {
      if (!end.isAfter(start)) return;
      if (end.difference(start) < minSleep) return;
      final mid = start.add(Duration(
          milliseconds: end.difference(start).inMilliseconds ~/ 2));
      if (!_isOvernight(mid.hour)) return;
      if (best == null || end.difference(start) > best!.duration) {
        best = SleepWindow(start, end);
      }
    }

    var cursor = lowerBound;
    for (final m in merged) {
      consider(cursor, m.start);
      if (m.end.isAfter(cursor)) cursor = m.end;
    }
    consider(cursor, now);

    return best;
  }

  bool _isOvernight(int hour) => hour >= nightStartHour || hour < nightEndHour;
}
