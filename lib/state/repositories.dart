import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alarm_repository.dart';
import '../data/preferences_repository.dart';
import '../data/sleep_session_repository.dart';

/// Repositories are stateless wrappers over the already-open Hive boxes /
/// SharedPreferences, so plain [Provider]s are enough.
final sleepSessionRepositoryProvider =
    Provider<SleepSessionRepository>((ref) => SleepSessionRepository());

final alarmRepositoryProvider =
    Provider<AlarmRepository>((ref) => AlarmRepository());

final preferencesRepositoryProvider =
    Provider<PreferencesRepository>((ref) => PreferencesRepository());
