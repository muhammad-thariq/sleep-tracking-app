import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  bool _audioOn = false;
  bool _motionOn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const SleepAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          children: [
            const Center(
              child: PillBadge(
                  label: 'RECORDING', variant: PillVariant.success),
            ),
            const SizedBox(height: AppSpacing.xl),
            _timerDisplay(theme),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text('Sleep tracking initiated at 11:45 PM',
                  style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _sensorCard(
                    theme,
                    icon: Icons.mic_none_rounded,
                    label: 'Audio',
                    value: _audioOn,
                    onChanged: (v) => setState(() => _audioOn = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _sensorCard(
                    theme,
                    icon: Icons.sensors_rounded,
                    label: 'Motion',
                    value: _motionOn,
                    onChanged: (v) => setState(() => _motionOn = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _pauseButton(theme)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _stopButton(theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text('03:14:02',
          style: theme.textTheme.displayLarge
              ?.copyWith(color: AppColors.textPrimary)),
    );
  }

  Widget _sensorCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool value,
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
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(value ? 'ACTIVE' : 'INACTIVE',
              style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _pauseButton(ThemeData theme) {
    return SurfaceCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pause_rounded, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Text('Pause', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _stopButton(ThemeData theme) {
    return SurfaceCard(
      onTap: () {},
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
