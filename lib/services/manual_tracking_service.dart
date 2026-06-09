import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/disturbance.dart';
import '../state/tracking_controller.dart';
import 'disturbance_debouncer.dart';

const _uuid = Uuid();

/// Entry point for the foreground service isolate. The actual sensor work runs
/// in the main isolate while this service merely keeps the process alive, so
/// the handler itself is a no-op.
@pragma('vm:entry-point')
void manualTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
  @override
  void onRepeatEvent(DateTime timestamp) {}
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Tuning constants for disturbance detection.
class _Thresholds {
  static const noiseDb = -20.0; // dBFS above which a sound counts as loud
  static const noiseSustain = Duration(seconds: 2);
  static const motionVariance = 0.8; // accel magnitude variance (m/s²)²
  static const motionWindow = 50; // ~10s of samples at 200ms
}

/// Runs the live sensor capture for a manual tracking session and feeds
/// debounced disturbances into the [TrackingController].
///
/// Privacy: audio capture reads *amplitude only* — raw PCM bytes from the
/// stream are drained and discarded, never stored or transmitted.
class ManualTrackingService {
  ManualTrackingService(this._ref);

  final Ref _ref;
  final AudioRecorder _recorder = AudioRecorder();
  final DisturbanceDebouncer _debouncer = DisturbanceDebouncer();

  StreamSubscription<Uint8List>? _pcmSub;
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _flushTimer;

  // Noise sustain tracking.
  DateTime? _noiseStart;
  bool _noiseEmitted = false;

  // Motion variance window.
  final List<double> _accelMagnitudes = [];

  TrackingController get _controller =>
      _ref.read(trackingControllerProvider.notifier);

  Future<void> start({bool audio = false, bool motion = false}) async {
    await _startForegroundService();
    _flushTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _flushDue());
    if (audio) await setAudio(true);
    if (motion) await setMotion(true);
  }

  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _stopAudio();
    await _stopMotion();
    for (final d in _debouncer.flushAll()) {
      _controller.addDisturbance(d);
    }
    await _stopForegroundService();
  }

  // --- Audio ---------------------------------------------------------------

  Future<void> setAudio(bool enabled) async {
    if (!enabled) {
      await _stopAudio();
      _controller.setAudioEnabled(false);
      return;
    }
    // record.hasPermission(request: true) prompts for RECORD_AUDIO.
    final granted = await _recorder.hasPermission();
    if (!granted) {
      _controller.setAudioEnabled(false, denied: true);
      return;
    }
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    // Drain and discard raw audio — we only consume amplitude.
    _pcmSub = stream.listen((_) {});
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 500))
        .listen(_onAmplitude);
    _controller.setAudioEnabled(true);
  }

  Future<void> _stopAudio() async {
    await _ampSub?.cancel();
    await _pcmSub?.cancel();
    _ampSub = null;
    _pcmSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _noiseStart = null;
    _noiseEmitted = false;
  }

  void _onAmplitude(Amplitude amp) {
    final loud = amp.current > _Thresholds.noiseDb; // dBFS, closer to 0 = louder
    if (!loud) {
      _noiseStart = null;
      _noiseEmitted = false;
      return;
    }
    final now = DateTime.now();
    _noiseStart ??= now;
    if (!_noiseEmitted &&
        now.difference(_noiseStart!) >= _Thresholds.noiseSustain) {
      _noiseEmitted = true;
      _debouncer.submit(Disturbance(
        id: _uuid.v4(),
        type: DisturbanceType.environmentalNoise,
        timestamp: now,
        description: 'A sustained sound disturbance was detected.',
        intensity: amp.current,
      ));
    }
  }

  // --- Motion --------------------------------------------------------------

  Future<void> setMotion(bool enabled) async {
    if (!enabled) {
      await _stopMotion();
      _controller.setMotionEnabled(false);
      return;
    }
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      _controller.setMotionEnabled(false, denied: true);
      return;
    }
    _accelMagnitudes.clear();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen(_onAccel);
    _controller.setMotionEnabled(true);
  }

  Future<void> _stopMotion() async {
    await _accelSub?.cancel();
    _accelSub = null;
    _accelMagnitudes.clear();
  }

  void _onAccel(AccelerometerEvent e) {
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    _accelMagnitudes.add(magnitude);
    if (_accelMagnitudes.length > _Thresholds.motionWindow) {
      _accelMagnitudes.removeAt(0);
    }
    if (_accelMagnitudes.length < _Thresholds.motionWindow) return;

    final variance = _variance(_accelMagnitudes);
    if (variance > _Thresholds.motionVariance) {
      _debouncer.submit(Disturbance(
        id: _uuid.v4(),
        type: DisturbanceType.restlessMovement,
        timestamp: DateTime.now(),
        description: 'Several seconds of movement were recorded.',
        intensity: variance,
      ));
    }
  }

  double _variance(List<double> xs) {
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    final sq = xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    return sq / xs.length;
  }

  // --- Flush ---------------------------------------------------------------

  void _flushDue() {
    for (final d in _debouncer.flushDue(DateTime.now())) {
      _controller.addDisturbance(d);
    }
  }

  // --- Foreground service --------------------------------------------------

  Future<void> _startForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sleepwell_tracking',
        channelName: 'Sleep Tracking',
        channelDescription: 'Keeps sleep tracking running while you sleep.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceTypes: const [
        ForegroundServiceTypes.microphone,
        ForegroundServiceTypes.dataSync,
      ],
      notificationTitle: 'SleepWell is tracking your sleep.',
      notificationText: 'Tap to return to the app.',
      callback: manualTrackingCallback,
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

final manualTrackingServiceProvider =
    Provider<ManualTrackingService>((ref) => ManualTrackingService(ref));
