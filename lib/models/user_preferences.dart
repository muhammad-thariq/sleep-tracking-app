/// Simple on/off user settings.
///
/// Persisted via `shared_preferences` (not Hive) per the storage plan — these
/// are flat booleans, so the key/value XML store is the natural fit.
class UserPreferences {
  final bool sleepGoalsEnabled;
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final bool autoTrackingEnabled;

  const UserPreferences({
    required this.sleepGoalsEnabled,
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.autoTrackingEnabled,
  });

  /// Defaults match the Phase 1 mock UI (goals/dark on, notifications off,
  /// auto-tracking on).
  static const defaults = UserPreferences(
    sleepGoalsEnabled: true,
    darkModeEnabled: true,
    notificationsEnabled: false,
    autoTrackingEnabled: true,
  );

  UserPreferences copyWith({
    bool? sleepGoalsEnabled,
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    bool? autoTrackingEnabled,
  }) {
    return UserPreferences(
      sleepGoalsEnabled: sleepGoalsEnabled ?? this.sleepGoalsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoTrackingEnabled: autoTrackingEnabled ?? this.autoTrackingEnabled,
    );
  }
}
