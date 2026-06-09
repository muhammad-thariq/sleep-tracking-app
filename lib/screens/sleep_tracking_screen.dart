import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/formatting.dart';
import '../services/manual_tracking_service.dart';
import '../state/tracking_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class SleepTrackingScreen extends ConsumerWidget {
  const SleepTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracking = ref.watch(trackingControllerProvider);
    final controller = ref.read(trackingControllerProvider.notifier);
    final service = ref.read(manualTrackingServiceProvider);
    final paused = tracking.status == TrackingStatus.paused;

    return Scaffold(
      appBar: const SleepAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          children: [
            Center(
              child: PillBadge(
                label: paused ? 'PAUSED' : 'RECORDING',
                variant: paused ? PillVariant.info : PillVariant.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _timerDisplay(theme, tracking.elapsed),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                tracking.startedAt != null
                    ? 'Sleep tracking initiated at ${Fmt.clock(tracking.startedAt!)}'
                    : 'Not currently tracking',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _sensorCard(
                    theme,
                    icon: Icons.mic_none_rounded,
                    label: 'Audio',
                    value: tracking.audioEnabled,
                    denied: tracking.audioDenied,
                    onChanged: (v) => service.setAudio(v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _sensorCard(
                    theme,
                    icon: Icons.sensors_rounded,
                    label: 'Motion',
                    value: tracking.motionEnabled,
                    denied: tracking.motionDenied,
                    onChanged: (v) => service.setMotion(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _pauseButton(theme, paused, () {
                    paused ? controller.resume() : controller.pause();
                  }),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _stopButton(theme, () async {
                    await service.stop();
                    controller.stop();
                    if (context.mounted) context.go('/');
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerDisplay(ThemeData theme, Duration elapsed) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(Fmt.elapsed(elapsed),
          style: theme.textTheme.displayLarge
              ?.copyWith(color: AppColors.textPrimary)),
    );
  }

  Widget _sensorCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool value,
    required bool denied,
    required ValueChanged<bool> onChanged,
  }) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const Spacer(),
              Switch(value: value && !denied, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            denied
                ? 'PERMISSION DENIED'
                : (value ? 'ACTIVE' : 'INACTIVE'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: denied ? AppColors.warning : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pauseButton(ThemeData theme, bool paused, VoidCallback onTap) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Text(paused ? 'Resume' : 'Pause',
              style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _stopButton(ThemeData theme, VoidCallback onTap) {
    return SurfaceCard(
      onTap: onTap,
      color: AppColors.danger.withValues(alpha: 0.15),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stop_rounded, color: AppColors.danger),
          SizedBox(width: AppSpacing.sm),
          Text('Stop',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger)),
        ],
      ),
    );
  }
}
