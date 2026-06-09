import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm_config.dart';
import 'repositories.dart';

const _uuid = Uuid();

/// List of configured alarms. Seeds the two Phase 1 defaults on first run so
/// the UI looks identical to the mock until the user edits anything.
class AlarmsNotifier extends Notifier<List<AlarmConfig>> {
  @override
  List<AlarmConfig> build() {
    final repo = ref.read(alarmRepositoryProvider);
    if (repo.getAll().isEmpty) {
      for (final a in _defaults()) {
        repo.upsert(a);
      }
    }
    return repo.getAll();
  }

  Future<void> upsert(AlarmConfig alarm) async {
    await ref.read(alarmRepositoryProvider).upsert(alarm);
    state = ref.read(alarmRepositoryProvider).getAll();
  }

  Future<void> delete(String id) async {
    await ref.read(alarmRepositoryProvider).delete(id);
    state = ref.read(alarmRepositoryProvider).getAll();
  }

  Future<void> toggle(String id) async {
    await ref.read(alarmRepositoryProvider).toggle(id);
    state = ref.read(alarmRepositoryProvider).getAll();
  }

  static String newId() => _uuid.v4();

  static List<AlarmConfig> _defaults() => [
        AlarmConfig(
          id: _uuid.v4(),
          type: AlarmType.smart,
          time: 6 * 60 + 30, // 06:30
          label: 'Smart Wake',
          windowMinutes: 30,
          // Sun  Mon   Tue   Wed   Thu   Fri   Sat
          activeDays: const [false, true, true, true, true, true, false],
          enabled: true,
        ),
        AlarmConfig(
          id: _uuid.v4(),
          type: AlarmType.standard,
          time: 8 * 60, // 08:00
          label: 'Weekend Sleep-in',
          windowMinutes: null,
          activeDays: const [false, false, false, false, false, false, false],
          enabled: false,
        ),
      ];
}

final alarmsProvider =
    NotifierProvider<AlarmsNotifier, List<AlarmConfig>>(AlarmsNotifier.new);
