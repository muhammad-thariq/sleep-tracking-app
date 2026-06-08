import 'package:flutter/material.dart';

/// Static mock data for Phase 1 (UI only). Phase 2 replaces these with real
/// sensor / persistence-backed sources.

class MockUser {
  final String name;
  final String avatarUrl;
  final int joinedYear;

  const MockUser({
    required this.name,
    required this.avatarUrl,
    required this.joinedYear,
  });
}

const mockUser = MockUser(
  name: 'Alex Carter',
  avatarUrl: 'https://i.pravatar.cc/150?img=12',
  joinedYear: 2023,
);

class MockLatestSession {
  final int durationHours;
  final int durationMinutes;
  final String fellAsleep;
  final String wokeUp;
  final int score;
  final String recoveryLabel;

  const MockLatestSession({
    required this.durationHours,
    required this.durationMinutes,
    required this.fellAsleep,
    required this.wokeUp,
    required this.score,
    required this.recoveryLabel,
  });
}

const mockLatestSession = MockLatestSession(
  durationHours: 7,
  durationMinutes: 23,
  fellAsleep: '11:30 PM',
  wokeUp: '6:53 AM',
  score: 85,
  recoveryLabel: 'Excellent Recovery',
);

class MockSleepStages {
  final String totalDuration;
  final int awakePercent;
  final int lightPercent;
  final int remPercent;
  final int deepPercent;
  final String startTime;
  final String midTime;
  final String endTime;
  final String statusLabel;

  const MockSleepStages({
    required this.totalDuration,
    required this.awakePercent,
    required this.lightPercent,
    required this.remPercent,
    required this.deepPercent,
    required this.startTime,
    required this.midTime,
    required this.endTime,
    required this.statusLabel,
  });
}

const mockSleepStages = MockSleepStages(
  totalDuration: '7h 24m',
  awakePercent: 5,
  lightPercent: 50,
  remPercent: 20,
  deepPercent: 25,
  startTime: '11 PM',
  midTime: '2 AM',
  endTime: '7 AM',
  statusLabel: 'Optimal',
);

enum DisturbanceType { noise, movement }

class MockDisturbance {
  final DisturbanceType type;
  final String title;
  final String time;
  final String description;

  const MockDisturbance({
    required this.type,
    required this.title,
    required this.time,
    required this.description,
  });

  IconData get icon =>
      type == DisturbanceType.noise ? Icons.volume_up_rounded : Icons.directions_walk_rounded;
}

const mockDisturbances = <MockDisturbance>[
  MockDisturbance(
    type: DisturbanceType.noise,
    title: 'Loud Noise Detected',
    time: '2:14 AM',
    description: 'A sudden sound disturbance briefly interrupted deep sleep.',
  ),
  MockDisturbance(
    type: DisturbanceType.movement,
    title: 'Restless Movement',
    time: '4:02 AM',
    description: 'Several minutes of tossing and turning were recorded.',
  ),
];

enum AlarmType { smart, standard }

class MockAlarm {
  final AlarmType type;
  final String time;
  final String label;
  final String? window;
  final List<bool> days; // S M T W T F S
  final bool enabled;

  const MockAlarm({
    required this.type,
    required this.time,
    required this.label,
    this.window,
    required this.days,
    required this.enabled,
  });
}

const mockAlarms = <MockAlarm>[
  MockAlarm(
    type: AlarmType.smart,
    time: '06:30',
    label: 'Smart Wake',
    window: 'Window: 06:00 – 06:30',
    // S  M     T     W     T     F     S
    days: [false, true, true, true, true, true, false],
    enabled: true,
  ),
  MockAlarm(
    type: AlarmType.standard,
    time: '08:00',
    label: 'Weekend Sleep-in',
    days: [false, false, false, false, false, false, false],
    enabled: false,
  ),
];
