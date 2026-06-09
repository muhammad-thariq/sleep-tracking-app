import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/alarm_ringing_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/sleep_analysis_screen.dart';
import '../screens/sleep_tracking_screen.dart';
import '../screens/smart_alarms_screen.dart';
import '../widgets/sleep_bottom_nav.dart';

/// App navigation. The 5 main tabs live inside a [StatefulShellRoute] so each
/// keeps its own state across tab switches; `/alarm-ringing` is a top-level
/// route that sits outside the shell (full screen, no nav chrome).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/track', builder: (_, _) => const SleepTrackingScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/analysis',
                builder: (_, _) => const SleepAnalysisScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/alarms', builder: (_, _) => const SmartAlarmsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileSettingsScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/alarm-ringing',
      builder: (context, state) =>
          AlarmRingingScreen(alarmId: state.uri.queryParameters['alarmId']),
    ),
  ],
);

/// Hosts the active tab's [Navigator] and the shared bottom nav.
class _ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SleepBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab again returns it to its initial route.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
