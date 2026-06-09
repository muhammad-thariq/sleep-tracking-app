import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/sleep_session.dart';
import '../services/auto_tracking_service.dart';
import '../services/formatting.dart';
import '../services/manual_tracking_service.dart';
import '../state/preferences_provider.dart';
import '../state/repositories.dart';
import '../state/session_providers.dart';
import '../state/tracking_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverOrphans());
  }

  /// On launch, surface any session left un-finalized by an app kill mid-track.
  Future<void> _recoverOrphans() async {
    final repo = ref.read(sleepSessionRepositoryProvider);
    final orphans = repo.getOrphaned();
    if (orphans.isEmpty || !mounted) return;
    final orphan = orphans.first;

    final finalize = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unfinished session'),
        content: Text(
          'A sleep session from ${Fmt.clock(orphan.startedAt)} was never '
          'stopped (the app may have closed). Save it or discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (finalize == true) {
      await repo.finalizeOrphan(orphan);
    } else {
      await repo.delete(orphan.id);
    }
    ref.invalidate(latestSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final latest = ref.watch(latestSessionProvider);
    final prefs = ref.watch(preferencesProvider);
    final usageAccess = ref.watch(usageAccessGrantedProvider);
    final showAccessBanner = prefs.autoTrackingEnabled && !usageAccess;

    return Scaffold(
      appBar: const SleepAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          children: [
            if (showAccessBanner) ...[
              _usageAccessBanner(context, ref),
              const SizedBox(height: AppSpacing.md),
            ],
            _scoreCard(context, latest.value),
            const SizedBox(height: AppSpacing.md),
            _latestSessionCard(context, latest.value),
            const SizedBox(height: AppSpacing.md),
            _autoTrackingRow(context, ref, prefs.autoTrackingEnabled),
            const SizedBox(height: AppSpacing.md),
            _startTrackingButton(context, ref),
            const SizedBox(height: AppSpacing.md),
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

  Widget _scoreCard(BuildContext context, SleepSession? session) {
    final score = session?.qualityScore;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      child: Column(
        children: [
          Text('SLEEP QUALITY SCORE',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            score?.toString() ?? '--',
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          PillBadge(
            label: score == null ? 'No data yet' : Fmt.recoveryLabel(score),
            variant: score == null
                ? PillVariant.info
                : Fmt.recoveryVariant(score),
          ),
        ],
      ),
    );
  }

  Widget _latestSessionCard(BuildContext context, SleepSession? session) {
    final fellAsleep = session != null ? Fmt.clock(session.startedAt) : '--';
    final wokeUp = session?.endedAt != null ? Fmt.clock(session!.endedAt!) : '--';
    final hours = session != null ? session.durationMinutes ~/ 60 : 0;
    final minutes = session != null ? session.durationMinutes % 60 : 0;

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
                TextSpan(text: '$hours'),
                const TextSpan(
                  text: ' h ',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary),
                ),
                TextSpan(text: '$minutes'),
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
              _sessionStat(context, 'Fell Asleep', fellAsleep,
                  CrossAxisAlignment.start),
              _sessionStat(
                  context, 'Woke Up', wokeUp, CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionStat(BuildContext context, String label, String value,
      CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _autoTrackingRow(BuildContext context, WidgetRef ref, bool enabled) {
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
            value: enabled,
            onChanged: (v) async {
              await ref.read(preferencesProvider.notifier).setAutoTracking(v);
              if (v && context.mounted) {
                await _ensureUsageAccess(context, ref);
              }
            },
          ),
        ],
      ),
    );
  }

  /// On enabling auto-tracking, check the special usage-access grant and, if
  /// missing, explain why and offer to open the settings screen.
  Future<void> _ensureUsageAccess(BuildContext context, WidgetRef ref) async {
    final service = ref.read(autoTrackingServiceProvider);
    final granted = await service.hasUsageAccess();
    ref.read(usageAccessGrantedProvider.notifier).set(granted);
    if (granted || !context.mounted) return;

    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Usage access needed'),
        content: const Text(
          'Auto-Sleep Tracking infers your sleep from phone-idle periods. '
          'This needs the special "Usage access" permission. Open settings to '
          'grant it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (open == true) await service.openUsageAccessSettings();
  }

  Widget _usageAccessBanner(BuildContext context, WidgetRef ref) {
    return SurfaceCard(
      color: AppColors.warning.withValues(alpha: 0.12),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      onTap: () => _ensureUsageAccess(context, ref),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Usage access is off — auto-detection is paused. Tap to re-grant.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _startTrackingButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(trackingControllerProvider.notifier).start();
          ref.read(manualTrackingServiceProvider).start();
          context.go('/track');
        },
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
