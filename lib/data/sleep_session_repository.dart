import 'package:hive/hive.dart';

import '../models/sleep_session.dart';
import '../services/scoring.dart';
import 'local_store.dart';

/// Thin wrapper over the Hive sessions box. Keys are session ids.
class SleepSessionRepository {
  Box<SleepSession> get _box => LocalStore.sessionsBox;

  Future<void> addSession(SleepSession session) =>
      _box.put(session.id, session);

  Future<void> delete(String id) => _box.delete(id);

  SleepSession? getById(String id) => _box.get(id);

  /// All sessions, newest first.
  List<SleepSession> getAll() {
    final all = _box.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return all;
  }

  /// Most recent *completed* session (ignores orphaned in-progress ones).
  SleepSession? getLatest() {
    final completed = getAll().where((s) => !s.isOrphaned);
    return completed.isEmpty ? null : completed.first;
  }

  /// The session whose window contains [date]'s night, if any. We match by the
  /// calendar date the session *started*.
  SleepSession? getByDate(DateTime date) {
    for (final s in getAll()) {
      if (_sameDay(s.startedAt, date)) return s;
    }
    return null;
  }

  /// Any session overlapping [start]..[end], optionally filtered by source.
  SleepSession? findOverlapping(DateTime start, DateTime end,
      {SleepSource? source}) {
    for (final s in _box.values) {
      if (source != null && s.source != source) continue;
      final sEnd = s.endedAt ?? s.startedAt;
      final overlaps = s.startedAt.isBefore(end) && sEnd.isAfter(start);
      if (overlaps) return s;
    }
    return null;
  }

  /// Sessions with no `endedAt` — left behind when the app was killed mid-track.
  List<SleepSession> getOrphaned() =>
      _box.values.where((s) => s.isOrphaned).toList();

  /// Close out an orphaned session: stamp `endedAt = now` and recompute the
  /// derived duration/score from the data captured before the app died.
  Future<void> finalizeOrphan(SleepSession s) {
    final end = DateTime.now();
    final duration = end.difference(s.startedAt).inMinutes;
    final score = Scoring.qualityScore(
      awakePercent: s.stageBreakdown.awakePercent,
      disturbanceCount: s.disturbances.length,
      durationMinutes: duration,
    );
    return addSession(s.copyWith(
      endedAt: end,
      durationMinutes: duration,
      qualityScore: score,
    ));
  }

  /// Emits the latest completed session now and on every box change.
  Stream<SleepSession?> watchLatest() async* {
    yield getLatest();
    await for (final _ in _box.watch()) {
      yield getLatest();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
