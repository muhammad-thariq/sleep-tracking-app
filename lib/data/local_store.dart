import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_config.dart';
import '../models/disturbance.dart';
import '../models/sleep_session.dart';
import '../models/sleep_stage_breakdown.dart';

/// One-time local-storage bootstrap. Initializes Hive, registers every adapter,
/// and opens the boxes that stay open for the app lifetime. All data lives in
/// the app's sandboxed documents dir — nothing leaves the device.
class LocalStore {
  LocalStore._();

  static const sessionsBoxName = 'sleep_sessions';
  static const alarmsBoxName = 'alarms';

  static late Box<SleepSession> sessionsBox;
  static late Box<AlarmConfig> alarmsBox;
  static late SharedPreferences prefs;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register in dependency order; typeIds are stable (see each model).
    _registerOnce(SleepStageBreakdownAdapter());
    _registerOnce(DisturbanceAdapter());
    _registerOnce(SleepSessionAdapter());
    _registerOnce(AlarmConfigAdapter());

    sessionsBox = await Hive.openBox<SleepSession>(sessionsBoxName);
    alarmsBox = await Hive.openBox<AlarmConfig>(alarmsBoxName);
    prefs = await SharedPreferences.getInstance();
  }

  static void _registerOnce<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
