import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_tracking_app/services/idle_window_detector.dart';

void main() {
  const detector = IdleWindowDetector();

  test('detects an overnight idle window', () {
    final now = DateTime(2024, 1, 2, 8, 0);
    final activity = [
      ActiveInterval(DateTime(2024, 1, 1, 20, 0), DateTime(2024, 1, 1, 23, 0)),
      ActiveInterval(DateTime(2024, 1, 2, 7, 0), DateTime(2024, 1, 2, 8, 0)),
    ];

    final window = detector.detect(activity: activity, now: now);
    expect(window, isNotNull);
    expect(window!.start, DateTime(2024, 1, 1, 23, 0));
    expect(window.end, DateTime(2024, 1, 2, 7, 0));
    expect(window.duration, const Duration(hours: 8));
  });

  test('ignores a long daytime gap (midpoint not overnight)', () {
    final now = DateTime(2024, 1, 2, 8, 0);
    // Active overnight; the only big gap is midday.
    final activity = [
      ActiveInterval(DateTime(2024, 1, 1, 9, 0), DateTime(2024, 1, 1, 12, 0)),
      ActiveInterval(DateTime(2024, 1, 1, 17, 0), DateTime(2024, 1, 2, 8, 0)),
    ];
    expect(detector.detect(activity: activity, now: now), isNull);
  });

  test('ignores an overnight gap shorter than minSleep', () {
    final now = DateTime(2024, 1, 2, 8, 0);
    final activity = [
      ActiveInterval(DateTime(2024, 1, 2, 1, 0), DateTime(2024, 1, 2, 2, 0)),
      ActiveInterval(DateTime(2024, 1, 2, 5, 0), DateTime(2024, 1, 2, 8, 0)),
    ];
    // Gap 02:00–05:00 is only 3h (< 4h default).
    expect(detector.detect(activity: activity, now: now), isNull);
  });

  test('picks the longest qualifying window', () {
    final now = DateTime(2024, 1, 2, 10, 0);
    final activity = [
      // 23:00–05:00 gap (6h), then a short break, then 06:00–07:00 gap (1h).
      ActiveInterval(DateTime(2024, 1, 1, 22, 0), DateTime(2024, 1, 1, 23, 0)),
      ActiveInterval(DateTime(2024, 1, 2, 5, 0), DateTime(2024, 1, 2, 5, 30)),
      ActiveInterval(DateTime(2024, 1, 2, 9, 0), DateTime(2024, 1, 2, 10, 0)),
    ];
    final window = detector.detect(activity: activity, now: now);
    expect(window!.start, DateTime(2024, 1, 1, 23, 0));
    expect(window.end, DateTime(2024, 1, 2, 5, 0));
  });
}
