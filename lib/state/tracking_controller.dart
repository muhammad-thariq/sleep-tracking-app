import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/disturbance.dart';
import '../models/sleep_session.dart';
import '../services/scoring.dart';
import 'alarms_provider.dart';
import 'repositories.dart';

enum TrackingStatus { idle, recording, paused }

/// Snapshot of the live manual-tracking session surfaced to the UI.
class TrackingState {
  final TrackingStatus status;
  final Duration elapsed;
  final bool audioEnabled;
  final bool motionEnabled;
  final bool audioDenied; // mic permission denied while toggle is on
  final bool motionDenied; // activity-recognition denied
  final DateTime? startedAt;
  final int disturbanceCount;

  const TrackingState({
    this.status = TrackingStatus.idle,
    this.elapsed = Duration.zero,
    this.audioEnabled = false,
    this.motionEnabled = false,
    this.audioDenied = false,
    this.motionDenied = false,
    this.startedAt,
    this.disturbanceCount = 0,
  });

  bool get isActive => status != TrackingStatus.idle;

  TrackingState copyWith({
    TrackingStatus? status,
    Duration? elapsed,
    bool? audioEnabled,
    bool? motionEnabled,
    bool? audioDenied,
    bool? motionDenied,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? disturbanceCount,
  }) {
    return TrackingState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      motionEnabled: motionEnabled ?? this.motionEnabled,
      audioDenied: audioDenied ?? this.audioDenied,
      motionDenied: motionDenied ?? this.motionDenied,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      disturbanceCount: disturbanceCount ?? this.disturbanceCount,
    );
  }
}

/// Owns the live tracking session: the elapsed-time ticker, sensor toggle
/// state, the in-progress disturbance buffer, and persistence on stop.
///
/// Sensor subscriptions themselves live in `ManualTrackingService`, which calls
/// [addDisturbance] — keeping platform plugins out of this pure-Dart notifier.
class TrackingController extends Notifier<TrackingState> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  final List<Disturbance> _disturbances = [];
  String? _sessionId;
  DateTime? _startedAt;

  @override
  TrackingState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const TrackingState();
  }

  SleepSession? get _orphanTemplate {
    if (_sessionId == null || _startedAt == null) return null;
    return SleepSession(
      id: _sessionId!,
      startedAt: _startedAt!,
      endedAt: null,
      durationMinutes: 0,
      qualityScore: 0,
      stageBreakdown: Scoring.manualStageStub(0),
      disturbances: const [],
      audioTrackingEnabled: state.audioEnabled,
      motionTrackingEnabled: state.motionEnabled,
      source: SleepSource.manual,
    );
  }

  /// Begin a new session. Persists an orphan record immediately so an app kill
  /// mid-tracking leaves a recoverable trace (see edge cases).
  void start({bool audio = false, bool motion = false}) {
    if (state.isActive) return;
    _disturbances.clear();
    _sessionId = AlarmsNotifier.newId();
    _startedAt = DateTime.now();
    _stopwatch
      ..reset()
      ..start();
    _startTicker();
    state = TrackingState(
      status: TrackingStatus.recording,
      elapsed: Duration.zero,
      audioEnabled: audio,
      motionEnabled: motion,
      startedAt: _startedAt,
    );
    final orphan = _orphanTemplate;
    if (orphan != null) {
      ref.read(sleepSessionRepositoryProvider).addSession(orphan);
    }
  }

  void pause() {
    if (state.status != TrackingStatus.recording) return;
    _stopwatch.stop();
    state = state.copyWith(status: TrackingStatus.paused);
  }

  void resume() {
    if (state.status != TrackingStatus.paused) return;
    _stopwatch.start();
    state = state.copyWith(status: TrackingStatus.recording);
  }

  /// Finalize and persist the session, then reset to idle. Returns the saved
  /// session (null if nothing was recording).
  SleepSession? stop() {
    if (!state.isActive) return null;
    _stopwatch.stop();
    _ticker?.cancel();

    final stage = Scoring.manualStageStub(_disturbances.length);
    final durationMinutes = _stopwatch.elapsed.inMinutes;
    final score = Scoring.qualityScore(
      awakePercent: stage.awakePercent,
      disturbanceCount: _disturbances.length,
      durationMinutes: durationMinutes,
    );
    final session = SleepSession(
      id: _sessionId ?? AlarmsNotifier.newId(),
      startedAt: _startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      durationMinutes: durationMinutes,
      qualityScore: score,
      stageBreakdown: stage,
      disturbances: List.of(_disturbances),
      audioTrackingEnabled: state.audioEnabled,
      motionTrackingEnabled: state.motionEnabled,
      source: SleepSource.manual,
    );
    ref.read(sleepSessionRepositoryProvider).addSession(session);

    _sessionId = null;
    _startedAt = null;
    _disturbances.clear();
    state = const TrackingState();
    return session;
  }

  void setAudioEnabled(bool enabled, {bool denied = false}) {
    state = state.copyWith(audioEnabled: enabled, audioDenied: denied);
  }

  void setMotionEnabled(bool enabled, {bool denied = false}) {
    state = state.copyWith(motionEnabled: enabled, motionDenied: denied);
  }

  /// Called by `ManualTrackingService` when a debounced disturbance is detected.
  void addDisturbance(Disturbance d) {
    _disturbances.add(d);
    state = state.copyWith(disturbanceCount: _disturbances.length);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TrackingStatus.recording) {
        state = state.copyWith(elapsed: _stopwatch.elapsed);
      }
    });
  }
}

final trackingControllerProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);
