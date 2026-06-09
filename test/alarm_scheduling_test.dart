import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_tracking_app/models/alarm_config.dart';
import 'package:sleep_tracking_app/services/alarm_scheduling.dart';

// activeDays indexed Sun..Sat (0..6).
List<bool> _days({Set<int> on = const {}}) =>
    List.generate(7, (i) => on.contains(i));

void main() {
  // 2024-01-01 is a Monday.
  final monday = DateTime(2024, 1, 1);

  group('AlarmScheduling.nextFireTime', () {
    test('standard alarm later today', () {
      final a = AlarmConfig(
        id: 'a',
        type: AlarmType.standard,
        time: 6 * 60, // 06:00
        label: 'x',
        windowMinutes: null,
        activeDays: _days(on: {1, 2, 3, 4, 5}),
        enabled: true,
      );
      final next = AlarmScheduling.nextFireTime(
          a, monday.add(const Duration(hours: 5))); // Mon 05:00
      expect(next, DateTime(2024, 1, 1, 6, 0));
    });

    test('standard alarm wraps to next week across day boundary', () {
      final a = AlarmConfig(
        id: 'a',
        type: AlarmType.standard,
        time: 6 * 60,
        label: 'x',
        windowMinutes: null,
        activeDays: _days(on: {1}), // Monday only
        enabled: true,
      );
      // Already past 06:00 this Monday → next is the following Monday.
      final next = AlarmScheduling.nextFireTime(
          a, monday.add(const Duration(hours: 7)));
      expect(next, DateTime(2024, 1, 8, 6, 0));
    });

    test('smart alarm fires at the start of the wake window', () {
      final a = AlarmConfig(
        id: 'a',
        type: AlarmType.smart,
        time: 6 * 60 + 30, // 06:30
        label: 'x',
        windowMinutes: 30,
        activeDays: _days(on: {1, 2, 3, 4, 5, 6, 0}),
        enabled: true,
      );
      final next = AlarmScheduling.nextFireTime(
          a, monday.add(const Duration(hours: 5)));
      expect(next, DateTime(2024, 1, 1, 6, 0)); // 06:30 - 30m
    });

    test('smart window can push the fire time to the previous day', () {
      final a = AlarmConfig(
        id: 'a',
        type: AlarmType.smart,
        time: 15, // 00:15
        label: 'x',
        windowMinutes: 30, // window starts 23:45 the night before
        activeDays: _days(on: {0, 1, 2, 3, 4, 5, 6}),
        enabled: true,
      );
      final next = AlarmScheduling.nextFireTime(
          a, monday.add(const Duration(hours: 12))); // Mon 12:00
      expect(next, DateTime(2024, 1, 1, 23, 45));
    });

    test('returns null when no days are active', () {
      final a = AlarmConfig(
        id: 'a',
        type: AlarmType.standard,
        time: 6 * 60,
        label: 'x',
        windowMinutes: null,
        activeDays: _days(),
        enabled: true,
      );
      expect(AlarmScheduling.nextFireTime(a, monday), isNull);
    });
  });
}
