import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_tracking_app/services/scoring.dart';

void main() {
  group('Scoring.qualityScore', () {
    test('ideal 8h sleep, no disturbances, low awake', () {
      // 100 - (5*2) - 0 - 0 = 90
      expect(
        Scoring.qualityScore(
            awakePercent: 5, disturbanceCount: 0, durationMinutes: 480),
        90,
      );
    });

    test('perfect inputs cap behaviour', () {
      // 100 - 0 - 0 - 0 = 100
      expect(
        Scoring.qualityScore(
            awakePercent: 0, disturbanceCount: 0, durationMinutes: 480),
        100,
      );
    });

    test('1h short of 8h costs 4 points', () {
      // 100 - 0 - 0 - (1*4) = 96
      expect(
        Scoring.qualityScore(
            awakePercent: 0, disturbanceCount: 0, durationMinutes: 420),
        96,
      );
    });

    test('disturbances subtract 3 each', () {
      // 100 - 0 - (3*3) - 0 = 91
      expect(
        Scoring.qualityScore(
            awakePercent: 0, disturbanceCount: 3, durationMinutes: 480),
        91,
      );
    });

    test('clamps to 0 for a terrible night', () {
      // 100 - 100 - 30 - 16 < 0 → 0
      expect(
        Scoring.qualityScore(
            awakePercent: 50, disturbanceCount: 10, durationMinutes: 240),
        0,
      );
    });
  });
}
