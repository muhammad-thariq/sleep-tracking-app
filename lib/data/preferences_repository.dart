import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';
import 'local_store.dart';

/// Typed wrapper over `shared_preferences` for the flat boolean settings.
class PreferencesRepository {
  static const _kSleepGoals = 'pref_sleep_goals';
  static const _kDarkMode = 'pref_dark_mode';
  static const _kNotifications = 'pref_notifications';
  static const _kAutoTracking = 'pref_auto_tracking';

  SharedPreferences get _prefs => LocalStore.prefs;

  UserPreferences read() {
    const d = UserPreferences.defaults;
    return UserPreferences(
      sleepGoalsEnabled: _prefs.getBool(_kSleepGoals) ?? d.sleepGoalsEnabled,
      darkModeEnabled: _prefs.getBool(_kDarkMode) ?? d.darkModeEnabled,
      notificationsEnabled:
          _prefs.getBool(_kNotifications) ?? d.notificationsEnabled,
      autoTrackingEnabled:
          _prefs.getBool(_kAutoTracking) ?? d.autoTrackingEnabled,
    );
  }

  Future<void> write(UserPreferences prefs) async {
    await _prefs.setBool(_kSleepGoals, prefs.sleepGoalsEnabled);
    await _prefs.setBool(_kDarkMode, prefs.darkModeEnabled);
    await _prefs.setBool(_kNotifications, prefs.notificationsEnabled);
    await _prefs.setBool(_kAutoTracking, prefs.autoTrackingEnabled);
  }
}
