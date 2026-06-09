import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes/app_router.dart';

/// Wraps `flutter_local_notifications` for the two things SleepWell notifies
/// about: an auto-detected sleep session, and a firing alarm (full-screen).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _autoChannelId = 'sleepwell_auto';
  static const _alarmChannelId = 'sleepwell_alarm';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onTapBackground,
    );
    _initialized = true;
  }

  /// Android 13+ runtime notification permission.
  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Shown after auto-detection creates a session.
  Future<void> showAutoDetected(Duration slept) async {
    final h = slept.inHours;
    final m = slept.inMinutes % 60;
    await _plugin.show(
      id: 1001,
      title: 'Sleep detected',
      body: 'We detected you slept ${h}h ${m}m last night. Tap to view.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _autoChannelId,
          'Auto Sleep Detection',
          channelDescription: 'Notifies when a sleep session is auto-detected.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: 'auto',
    );
  }

  /// Full-screen alarm notification that launches `/alarm-ringing`.
  Future<void> showAlarm({required String alarmId, String? label}) async {
    await _plugin.show(
      id: 2001,
      title: label?.isNotEmpty == true ? label : 'Alarm',
      body: 'Time to wake up',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _alarmChannelId,
          'Alarms',
          channelDescription: 'Wake-up alarms.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          playSound: false, // sound handled by AlarmService via audioplayers
        ),
      ),
      payload: 'alarm:$alarmId',
    );
  }

  Future<void> cancelAlarm() => _plugin.cancel(id: 2001);

  static void _onTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.startsWith('alarm:')) {
      final id = payload.substring('alarm:'.length);
      appRouter.go('/alarm-ringing?alarmId=$id');
    } else if (payload == 'auto') {
      appRouter.go('/analysis');
    }
  }
}

/// Background isolate tap handler — must be a top-level/static entry point.
@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse response) {
  // The app is brought to foreground; the foreground handler will route.
}
