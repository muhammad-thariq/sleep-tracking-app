import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

/// Stage colors, shared between the bar chart and the legend.
const _awakeColor = Color(0xFFEC4899); // pink/red
const _lightColor = Color(0xFF6B7280); // gray
const _remColor = AppColors.primary; // light blue
const _deepColor = AppColors.success; // green

class SleepAnalysisScreen extends StatelessWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const SleepAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          children: [
            _dateNavigator(theme),
            const SizedBox(height: AppSpacing.md),
            _stagesCard(theme),
            const SizedBox(height: AppSpacing.lg),
            Text('Disturbances', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final d in mockDisturbances) ...[
              _disturbanceCard(theme, d),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateNavigator(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        Expanded(
          child: Column(
            children: [
              Text('Last Night', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text('Oct 24 – Oct 25', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _stagesCard(ThemeData theme) {
    final s = mockSleepStages;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SLEEP STAGES', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(s.totalDuration,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.md),
              PillBadge(label: s.statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _stackedBar(s),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.startTime, style: theme.textTheme.labelSmall),
              Text(s.midTime, style: theme.textTheme.labelSmall),
              Text(s.endTime, style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _legend(theme, _awakeColor, 'Awake', s.awakePercent),
              _legend(theme, _lightColor, 'Light', s.lightPercent),
              _legend(theme, _remColor, 'REM', s.remPercent),
              _legend(theme, _deepColor, 'Deep', s.deepPercent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stackedBar(MockSleepStages s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            Expanded(flex: s.awakePercent, child: Container(color: _awakeColor)),
            Expanded(flex: s.lightPercent, child: Container(color: _lightColor)),
            Expanded(flex: s.remPercent, child: Container(color: _remColor)),
            Expanded(flex: s.deepPercent, child: Container(color: _deepColor)),
          ],
        ),
      ),
    );
  }

  Widget _legend(ThemeData theme, Color color, String label, int percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text('$label $percent%',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _disturbanceCard(ThemeData theme, MockDisturbance d) {
    final isNoise = d.type == DisturbanceType.noise;
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNoise
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(d.icon,
                size: 20,
                color: isNoise ? AppColors.warning : AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(d.title,
                          style: theme.textTheme.titleMedium),
                    ),
                    Text(d.time, style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(d.description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
