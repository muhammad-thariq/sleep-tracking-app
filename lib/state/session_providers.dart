import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_session.dart';
import 'repositories.dart';

/// Latest completed session, kept live off the Hive box's change stream.
class LatestSessionNotifier extends AsyncNotifier<SleepSession?> {
  @override
  Future<SleepSession?> build() async {
    final repo = ref.watch(sleepSessionRepositoryProvider);
    final sub = repo.watchLatest().listen((latest) {
      state = AsyncData(latest);
    });
    ref.onDispose(sub.cancel);
    return repo.getLatest();
  }
}

final latestSessionProvider =
    AsyncNotifierProvider<LatestSessionNotifier, SleepSession?>(
        LatestSessionNotifier.new);

/// Session for a given calendar date (the night that *started* on that date).
/// Depends on [latestSessionProvider] so it rebuilds whenever the box changes.
final sessionByDateProvider =
    Provider.family<SleepSession?, DateTime>((ref, date) {
  ref.watch(latestSessionProvider);
  final repo = ref.watch(sleepSessionRepositoryProvider);
  return repo.getByDate(date);
});

/// All sessions, newest first (used for history navigation).
final allSessionsProvider = Provider<List<SleepSession>>((ref) {
  ref.watch(latestSessionProvider);
  return ref.watch(sleepSessionRepositoryProvider).getAll();
});
