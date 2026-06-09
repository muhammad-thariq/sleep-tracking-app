import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_tracking_app/models/disturbance.dart';
import 'package:sleep_tracking_app/services/disturbance_debouncer.dart';

Disturbance _d(DisturbanceType type, DateTime t, double intensity) =>
    Disturbance(
      id: '${type.name}-${t.millisecondsSinceEpoch}',
      type: type,
      timestamp: t,
      description: '',
      intensity: intensity,
    );

void main() {
  final t0 = DateTime(2024, 1, 1, 2, 0, 0);

  test('collapses same-type events in a window, keeping highest intensity', () {
    final deb = DisturbanceDebouncer(window: const Duration(seconds: 30));
    deb.submit(_d(DisturbanceType.environmentalNoise, t0, 1.0));
    deb.submit(_d(DisturbanceType.environmentalNoise,
        t0.add(const Duration(seconds: 10)), 3.0));

    // Not yet due.
    expect(deb.flushDue(t0.add(const Duration(seconds: 5))), isEmpty);

    final out = deb.flushDue(t0.add(const Duration(seconds: 31)));
    expect(out.length, 1);
    expect(out.single.intensity, 3.0);
  });

  test('different types are tracked independently', () {
    final deb = DisturbanceDebouncer(window: const Duration(seconds: 30));
    deb.submit(_d(DisturbanceType.environmentalNoise, t0, 2.0));
    deb.submit(_d(DisturbanceType.restlessMovement, t0, 4.0));

    final out = deb.flushDue(t0.add(const Duration(seconds: 31)));
    expect(out.length, 2);
    expect(
      out.map((d) => d.type).toSet(),
      {DisturbanceType.environmentalNoise, DisturbanceType.restlessMovement},
    );
  });

  test('a new window opens after the previous one elapses', () {
    final deb = DisturbanceDebouncer(window: const Duration(seconds: 30));
    deb.submit(_d(DisturbanceType.environmentalNoise, t0, 1.0));
    expect(deb.flushDue(t0.add(const Duration(seconds: 31))).length, 1);

    deb.submit(_d(DisturbanceType.environmentalNoise,
        t0.add(const Duration(seconds: 40)), 5.0));
    final out = deb.flushDue(t0.add(const Duration(seconds: 71)));
    expect(out.single.intensity, 5.0);
  });

  test('flushAll drains everything still buffered', () {
    final deb = DisturbanceDebouncer();
    deb.submit(_d(DisturbanceType.environmentalNoise, t0, 1.0));
    expect(deb.flushAll().length, 1);
    expect(deb.flushAll(), isEmpty);
  });
}
