import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local_store.dart';
import 'routes/app_router.dart';
import 'services/alarm_service.dart';
import 'services/auto_tracking_service.dart';
import 'services/notification_service.dart';
import 'state/alarms_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  runApp(const ProviderScope(child: SleepWellApp()));
}

class SleepWellApp extends ConsumerStatefulWidget {
  const SleepWellApp({super.key});

  @override
  ConsumerState<SleepWellApp> createState() => _SleepWellAppState();
}

class _SleepWellAppState extends ConsumerState<SleepWellApp>
    with WidgetsBindingObserver {
  Timer? _autoDetectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermission();

    // Alarms: init the scheduler, schedule from current config, and reschedule
    // on any change (also re-establishes alarms after a reboot).
    final alarmService = ref.read(alarmServiceProvider);
    await alarmService.init();
    await alarmService.rescheduleAll(ref.read(alarmsProvider));
    ref.listenManual(alarmsProvider, (_, next) {
      alarmService.rescheduleAll(next);
    });

    // Auto-detection: once now, then hourly while foregrounded.
    await ref.read(autoTrackingServiceProvider).runDetectionNow();
    _autoDetectTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => ref.read(autoTrackingServiceProvider).runDetectionNow(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check usage access + detect on resume (user may have just granted it).
    if (state == AppLifecycleState.resumed) {
      ref.read(autoTrackingServiceProvider).runDetectionNow();
    }
  }

  @override
  void dispose() {
    _autoDetectTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SleepWell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
