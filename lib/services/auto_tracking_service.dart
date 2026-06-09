import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/sleep_session.dart';
import '../state/preferences_provider.dart';
import '../state/repositories.dart';
import 'idle_window_detector.dart';
import 'notification_service.dart';
import 'scoring.dart';

const _uuid = Uuid();

/// Tracks whether PACKAGE_USAGE_STATS access appears to be granted. Starts
/// optimistic (true) and is corrected by [AutoTrackingService.runDetectionNow].
/// The dashboard watches this to show a re-grant banner when it flips false.
class UsageAccessNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool granted) => state = granted;
}

final usageAccessGrantedProvider =
    NotifierProvider<UsageAccessNotifier, bool>(UsageAccessNotifier.new);

/// Passive sleep detection from phone-idle periods. No foreground service, no
/// sensors — cheap and battery-friendly. Runs once at launch and hourly while
/// the app is foregrounded (no background daemon, by design).
///
/// LIMITATIONS (surfaced as an "auto-detected" pill in the UI):
///  - Can't distinguish sleep from a phone idle on the nightstand.
///  - Daytime naps are filtered out by the overnight midpoint rule.
///  - Stage breakdown is a flat guess (no sensors ran).
class AutoTrackingService {
  AutoTrackingService(this._ref);

  final Ref _ref;
  final IdleWindowDetector _detector = const IdleWindowDetector();

  static const _replaceThreshold = Duration(minutes: 15);

  /// Heuristic access check: PACKAGE_USAGE_STATS isn't a runtime permission and
  /// app_usage 4.x exposes no `checkUsageAccess`, so we probe — without access
  /// the platform returns an empty list.
  Future<bool> hasUsageAccess() async {
    if (!_isAndroid) return false;
    try {
      final now = DateTime.now();
      final infos =
          await AppUsage().getAppUsage(now.subtract(const Duration(hours: 2)), now);
      return infos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Opens Settings → Special access → Usage access.
  Future<void> openUsageAccessSettings() async {
    if (!_isAndroid) return;
    const intent =
        AndroidIntent(action: 'android.settings.USAGE_ACCESS_SETTINGS');
    await intent.launch();
  }

  /// Run a detection pass now. Safe to call repeatedly; no-ops unless
  /// auto-tracking is enabled and usage access is granted.
  Future<void> runDetectionNow() async {
    final prefs = _ref.read(preferencesProvider);
    if (!prefs.autoTrackingEnabled || !_isAndroid) return;

    final now = DateTime.now();
    List<AppUsageInfo> infos;
    try {
      infos =
          await AppUsage().getAppUsage(now.subtract(const Duration(hours: 24)), now);
    } catch (_) {
      infos = [];
    }

    final granted = infos.isNotEmpty;
    _ref.read(usageAccessGrantedProvider.notifier).set(granted);
    if (!granted) return;

    // Approximate each app's active span as ending at its last-foreground time.
    final activity = infos
        .map((i) => ActiveInterval(i.lastForeground.subtract(i.usage),
            i.lastForeground))
        .toList();

    final window = _detector.detect(activity: activity, now: now);
    if (window == null) return;

    final repo = _ref.read(sleepSessionRepositoryProvider);

    // Conflict resolution: manual data is higher fidelity — never overwrite it.
    final manual = repo.findOverlapping(window.start, window.end,
        source: SleepSource.manual);
    if (manual != null) return;

    // Replace an existing auto session only if the new window is meaningfully
    // longer (handles a later check finding a fuller picture).
    final existingAuto = repo.findOverlapping(window.start, window.end,
        source: SleepSource.auto);
    if (existingAuto != null) {
      final diff =
          (window.duration.inMinutes - existingAuto.durationMinutes).abs();
      if (diff <= _replaceThreshold.inMinutes) return;
      await repo.delete(existingAuto.id);
    }

    final stage = Scoring.autoStageStub();
    final durationMinutes = window.duration.inMinutes;
    final score = Scoring.qualityScore(
      awakePercent: stage.awakePercent,
      disturbanceCount: 0,
      durationMinutes: durationMinutes,
    );
    await repo.addSession(SleepSession(
      id: _uuid.v4(),
      startedAt: window.start,
      endedAt: window.end,
      durationMinutes: durationMinutes,
      qualityScore: score,
      stageBreakdown: stage,
      disturbances: const [],
      audioTrackingEnabled: false,
      motionTrackingEnabled: false,
      source: SleepSource.auto,
    ));

    if (prefs.notificationsEnabled) {
      await NotificationService.instance.showAutoDetected(window.duration);
    }
  }

  bool get _isAndroid => Platform.isAndroid;
}

final autoTrackingServiceProvider =
    Provider<AutoTrackingService>((ref) => AutoTrackingService(ref));
