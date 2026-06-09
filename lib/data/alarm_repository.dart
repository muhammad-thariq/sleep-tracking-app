import 'package:hive/hive.dart';

import '../models/alarm_config.dart';
import 'local_store.dart';

/// Thin wrapper over the Hive alarms box. Keys are alarm ids.
class AlarmRepository {
  Box<AlarmConfig> get _box => LocalStore.alarmsBox;

  List<AlarmConfig> getAll() {
    final all = _box.values.toList()..sort((a, b) => a.time.compareTo(b.time));
    return all;
  }

  AlarmConfig? getById(String id) => _box.get(id);

  Future<void> upsert(AlarmConfig alarm) => _box.put(alarm.id, alarm);

  Future<void> delete(String id) => _box.delete(id);

  Future<AlarmConfig?> toggle(String id) async {
    final existing = _box.get(id);
    if (existing == null) return null;
    final updated = existing.copyWith(enabled: !existing.enabled);
    await _box.put(id, updated);
    return updated;
  }
}
