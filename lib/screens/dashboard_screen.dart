import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _autoTracking = true;

  @override
  Widget build(BuildContext context) {
    final session = mockLatestSession;
    return Scaffold(
      appBar: const SleepAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          children: [
            _scoreCard(session),
            const SizedBox(height: AppSpacing.md),
            _latestSessionCard(session),
            const SizedBox(height: AppSpacing.md),
            _autoTrackingRow(),
            const SizedBox(height: AppSpacing.md),
            _startTrackingButton(),
            const SizedBox(height: AppSpacing.md),
            // Temporary debug entry point to the full-screen alarm (Phase 2
            // will trigger this automatically).
            TextButton(
              onPressed: () => context.push('/alarm-ringing'),
              child: const Text(
                'Debug: open Alarm Ringing screen',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(MockLatestSession session) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      child: Column(
        children: [
          Text('SLEEP QUALITY SCORE',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${session.score}',
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          PillBadge(label: session.recoveryLabel),
        ],
      ),
    );
  }

  Widget _latestSessionCard(MockLatestSession session) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Latest Session',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const Icon(Icons.nightlight_round,
                  color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: '${session.durationHours}'),
                const TextSpan(
                  text: ' h ',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary),
                ),
                TextSpan(text: '${session.durationMinutes}'),
                const TextSpan(
                  text: ' m',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sessionStat('Fell Asleep', session.fellAsleep,
                  CrossAxisAlignment.start),
              _sessionStat('Woke Up', session.wokeUp, CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionStat(String label, String value, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _autoTrackingRow() {
    return SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('Auto-Sleep Tracking',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(
            value: _autoTracking,
            onChanged: (v) => setState(() => _autoTracking = v),
          ),
        ],
      ),
    );
  }

  Widget _startTrackingButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/track'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Tracking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
