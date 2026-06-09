import '../models/sleep_stage_breakdown.dart';

/// Pure scoring + stage-estimation helpers, kept free of Flutter/Hive so they
/// can be unit-tested in isolation (see test/scoring_test.dart).
class Scoring {
  Scoring._();

  static const idealSleepMinutes = 8 * 60;

  /// qualityScore = 100
  ///   - awakePercent * 2
  ///   - disturbanceCount * 3
  ///   - sleepDurationDeviationFrom8h(hours) * 4
  /// clamped to 0..100.
  static int qualityScore({
    required double awakePercent,
    required int disturbanceCount,
    required int durationMinutes,
  }) {
    final deviationHours = (durationMinutes - idealSleepMinutes).abs() / 60.0;
    final raw = 100 -
        (awakePercent * 2) -
        (disturbanceCount * 3) -
        (deviationHours * 4);
    return raw.clamp(0, 100).round();
  }

  /// Manual-tracking stage stub. STUB: a plausible 5/50/20/25 baseline nudged
  /// by disturbance count (more disturbances → more time awake / light, less
  /// deep). Real stage detection is out of scope for Phase 2.
  static SleepStageBreakdown manualStageStub(int disturbanceCount) {
    final nudge = (disturbanceCount * 1.5).clamp(0, 15).toDouble();
    final awake = (5 + nudge * 0.4).clamp(0, 100).toDouble();
    final deep = (25 - nudge * 0.4).clamp(0, 100).toDouble();
    final light = (50 + nudge * 0.2).clamp(0, 100).toDouble();
    final rem = (100 - awake - deep - light).clamp(0, 100).toDouble();
    return SleepStageBreakdown(
      awakePercent: awake,
      lightPercent: light,
      remPercent: rem,
      deepPercent: deep,
    );
  }

  /// Auto-tracking stage stub. STUB: a flat 5/55/20/20 — even less reliable
  /// than the manual stub since no sensors ran. Surfaced in the UI via an
  /// "auto-detected" pill.
  static SleepStageBreakdown autoStageStub() {
    return const SleepStageBreakdown(
      awakePercent: 5,
      lightPercent: 55,
      remPercent: 20,
      deepPercent: 20,
    );
  }
}
