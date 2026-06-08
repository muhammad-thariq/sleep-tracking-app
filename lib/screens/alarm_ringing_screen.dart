import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';

/// Full-screen alarm view — no app bar, no bottom nav. Reached via a debug
/// button for now; Phase 2 will trigger it from the alarm scheduler.
class AlarmRingingScreen extends StatelessWidget {
  const AlarmRingingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              const PillBadge(
                label: 'OPTIMAL WAKE WINDOW',
                variant: PillVariant.success,
                icon: Icons.check_circle_outline,
                outlined: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Sleep Cycle Complete', style: theme.textTheme.bodyMedium),
              const Spacer(),
              _rings(theme),
              const Spacer(),
              _snoozeButton(theme),
              const SizedBox(height: AppSpacing.md),
              _stopButton(context),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rings(ThemeData theme) {
    return Container(
      width: 300,
      height: 300,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Container(
        width: 240,
        height: 240,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('06:30',
                style: theme.textTheme.displayLarge
                    ?.copyWith(color: AppColors.primary)),
            Text('AM', style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  Widget _snoozeButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Text('Snooze',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('10 MINUTES', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _stopButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => context.pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        icon: const Icon(Icons.close),
        label: const Text('Stop Alarm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
