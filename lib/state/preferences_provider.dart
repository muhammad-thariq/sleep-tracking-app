import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_preferences.dart';
import 'repositories.dart';

/// User toggle settings, persisted to SharedPreferences on every change.
class PreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() => ref.read(preferencesRepositoryProvider).read();

  Future<void> _update(UserPreferences next) async {
    state = next;
    await ref.read(preferencesRepositoryProvider).write(next);
  }

  Future<void> setSleepGoals(bool v) =>
      _update(state.copyWith(sleepGoalsEnabled: v));

  Future<void> setDarkMode(bool v) =>
      _update(state.copyWith(darkModeEnabled: v));

  Future<void> setNotifications(bool v) =>
      _update(state.copyWith(notificationsEnabled: v));

  Future<void> setAutoTracking(bool v) =>
      _update(state.copyWith(autoTrackingEnabled: v));
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, UserPreferences>(
        PreferencesNotifier.new);
