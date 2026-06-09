import 'dart:io' show Platform;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../models/alarm_config.dart';
import 'alarm_scheduling.dart';
import 'notification_service.dart';

/// Background-isolate entry point fired by AndroidAlarmManager. Runs without the
/// app's providers, so it re-inits the notification plugin and posts a
/// full-screen alarm notification; tapping it routes to `/alarm-ringing`.
///
/// SIMPLIFICATION: the spec's "smart" behavior (probe live sleep stage at the
/// window start, fire on light sleep else recheck every 5 min) needs sleep data
/// inside this isolate, which isn't available in Phase 2. Smart alarms instead
/// fire at the window start. Documented as a known limitation.
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  final alarmId = params['alarmId'] as String? ?? '';
  final label = params['label'] as String?;
  await NotificationService.instance.init();
  await NotificationService.instance.showAlarm(alarmId: alarmId, label: label);
}

class AlarmService {
  AlarmService(this._ref);

  final Ref _ref; // ignore: unused_field — reserved for future provider reads
  final AudioPlayer _player = AudioPlayer();

  static const _scheduledIdsKey = 'scheduled_alarm_ids';
  static const _snoozeMinutes = 10;

  bool get _isAndroid => Platform.isAndroid;

  Future<void> init() async {
    if (!_isAndroid) return;
    await AndroidAlarmManager.initialize();
  }

  /// Cancel everything previously scheduled, then schedule the next 7 days of
  /// fire times for each enabled alarm. Called on launch and on any change to
  /// the alarms list (also covers reboot re-scheduling).
  Future<void> rescheduleAll(List<AlarmConfig> alarms) async {
    if (!_isAndroid) return;

    for (final id in _readScheduledIds()) {
      await AndroidAlarmManager.cancel(id);
    }

    final newIds = <int>[];
    final now = DateTime.now();
    for (final alarm in alarms.where((a) => a.enabled)) {
      final fireTimes = AlarmScheduling.occurrences(alarm, now, days: 7);
      for (var i = 0; i < fireTimes.length; i++) {
        final id = _alarmId(alarm.id, i);
        final ok = await AndroidAlarmManager.oneShotAt(
          fireTimes[i],
          id,
          alarmCallback,
          exact: true,
          wakeup: true,
          alarmClock: true,
          rescheduleOnReboot: true,
          params: {'alarmId': alarm.id, 'label': alarm.label},
        );
        if (ok) newIds.add(id);
      }
    }
    await _writeScheduledIds(newIds);
  }

  /// Snooze: stop sound, reschedule this alarm +10 min.
  Future<void> snooze(String alarmId, {String? label}) async {
    await stopSound();
    if (!_isAndroid) return;
    final id = _alarmId(alarmId, 99); // dedicated snooze slot
    await AndroidAlarmManager.oneShotAt(
      DateTime.now().add(const Duration(minutes: _snoozeMinutes)),
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      params: {'alarmId': alarmId, 'label': label ?? 'Alarm'},
    );
  }

  /// Stop: stop sound and dismiss the notification. (Pending smart-window
  /// rechecks would be cancelled here too once implemented.)
  Future<void> stop() async {
    await stopSound();
  }

  // --- Sound (foreground, on the alarm-ringing screen) ---------------------

  Future<void> startSound() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/alarm.mp3'));
    } catch (_) {
      // No bundled sound asset present — fail silently (UI still shows).
    }
  }

  Future<void> stopSound() async {
    try {
      await _player.stop();
    } catch (_) {}
    await NotificationService.instance.cancelAlarm();
  }

  // --- ID + persistence helpers --------------------------------------------

  /// Stable 31-bit id from an alarm id + occurrence index.
  int _alarmId(String alarmId, int occurrence) {
    final base = alarmId.hashCode & 0x00FFFFFF; // 24 bits
    return base * 128 + (occurrence & 0x7F); // keeps it < 2^31
  }

  List<int> _readScheduledIds() {
    final raw = LocalStore.prefs.getStringList(_scheduledIdsKey) ?? const [];
    return raw.map(int.parse).toList();
  }

  Future<void> _writeScheduledIds(List<int> ids) =>
      LocalStore.prefs.setStringList(
        _scheduledIdsKey,
        ids.map((e) => e.toString()).toList(),
      );
}

final alarmServiceProvider = Provider<AlarmService>((ref) => AlarmService(ref));
