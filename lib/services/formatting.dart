import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/pill_badge.dart';

/// Display formatting helpers (intl-backed). Pure UI concern, kept out of the
/// models so persistence stays format-agnostic.
class Fmt {
  Fmt._();

  /// "11:30 PM"
  static String clock(DateTime t) => DateFormat('h:mm a').format(t);

  /// 24h "06:30" from minutes-since-midnight.
  static String hm24FromMinutes(int minutesSinceMidnight) {
    final h = (minutesSinceMidnight ~/ 60) % 24;
    final m = minutesSinceMidnight % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String hm24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Elapsed timer "03:14:02".
  static String elapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  /// "7h 24m" from total minutes.
  static String durationHm(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  /// "Mon, Oct 24" — used as the analysis date header when not "Last Night".
  static String dayLabel(DateTime d) => DateFormat('EEE, MMM d').format(d);

  /// "Oct 24 – Oct 25" spanning a night.
  static String nightRange(DateTime start, DateTime? end) {
    final f = DateFormat('MMM d');
    final e = end ?? start.add(const Duration(hours: 8));
    return '${f.format(start)} – ${f.format(e)}';
  }

  /// Human label from a 0..100 quality score.
  static String recoveryLabel(int score) {
    if (score >= 85) return 'Excellent Recovery';
    if (score >= 70) return 'Good Recovery';
    if (score >= 50) return 'Fair Recovery';
    return 'Needs Rest';
  }

  static PillVariant recoveryVariant(int score) =>
      score >= 70 ? PillVariant.success : PillVariant.info;
}
