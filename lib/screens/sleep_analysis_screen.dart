import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/disturbance.dart';
import '../models/sleep_session.dart';
import '../models/sleep_stage_breakdown.dart';
import '../services/formatting.dart';
import '../state/session_providers.dart';
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

class SleepAnalysisScreen extends ConsumerStatefulWidget {
  const SleepAnalysisScreen({super.key});

  @override
  ConsumerState<SleepAnalysisScreen> createState() =>
      _SleepAnalysisScreenState();
}

class _SleepAnalysisScreenState extends ConsumerState<SleepAnalysisScreen> {
  DateTime? _selectedDate;

  DateTime _dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _effectiveDate {
    if (_selectedDate != null) return _selectedDate!;
    final latest = ref.read(latestSessionProvider).value;
    return _dateKey(latest?.startedAt ?? DateTime.now());
  }

  void _shiftDay(int deltaDays) {
    setState(() {
      _selectedDate =
          _dateKey(_effectiveDate.add(Duration(days: deltaDays)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _effectiveDate;
    final session = ref.watch(sessionByDateProvider(date));

    return Scaffold(
      appBar: const SleepAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          children: [
            _dateNavigator(theme, date, session),
            const SizedBox(height: AppSpacing.md),
            if (session == null)
              _emptyState(theme)
            else ...[
              _stagesCard(theme, session),
              const SizedBox(height: AppSpacing.lg),
              Text('Disturbances', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (session.disturbances.isEmpty)
                Text('No disturbances recorded.',
                    style: theme.textTheme.bodyMedium)
              else
                for (final d in session.disturbances) ...[
                  _disturbanceCard(theme, d),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateNavigator(
      ThemeData theme, DateTime date, SleepSession? session) {
    final isToday = _dateKey(DateTime.now()) == date;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          onPressed: () => _shiftDay(-1),
        ),
        Expanded(
          child: Column(
            children: [
              Text(isToday ? 'Last Night' : Fmt.dayLabel(date),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(Fmt.nightRange(date, session?.endedAt),
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          icon:
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onPressed: () => _shiftDay(1),
        ),
      ],
    );
  }

  Widget _emptyState(ThemeData theme) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.md),
      child: Column(
        children: [
          const Icon(Icons.bedtime_outlined,
              color: AppColors.textTertiary, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text('No sleep recorded for this night',
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Track a session or enable auto-detection to see analysis here.',
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _stagesCard(ThemeData theme, SleepSession session) {
    final s = session.stageBreakdown;
    final start = session.startedAt;
    final end = session.endedAt ?? start;
    final mid = start.add(Duration(
        milliseconds: end.difference(start).inMilliseconds ~/ 2));

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SLEEP STAGES', style: theme.textTheme.labelSmall),
              const Spacer(),
              if (session.source == SleepSource.auto)
                const PillBadge(label: 'Auto-detected', variant: PillVariant.info),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(Fmt.durationHm(session.durationMinutes),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.md),
              PillBadge(label: _qualityLabel(session.qualityScore)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _stackedBar(s),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Fmt.clock(start), style: theme.textTheme.labelSmall),
              Text(Fmt.clock(mid), style: theme.textTheme.labelSmall),
              Text(Fmt.clock(end), style: theme.textTheme.labelSmall),
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

  String _qualityLabel(int score) => score >= 70 ? 'Optimal' : 'Fair';

  Widget _stackedBar(SleepStageBreakdown stage) {
    int flex(double pct) => (pct * 10).round().clamp(1, 1000);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            Expanded(
                flex: flex(stage.awakePercent),
                child: Container(color: _awakeColor)),
            Expanded(
                flex: flex(stage.lightPercent),
                child: Container(color: _lightColor)),
            Expanded(
                flex: flex(stage.remPercent),
                child: Container(color: _remColor)),
            Expanded(
                flex: flex(stage.deepPercent),
                child: Container(color: _deepColor)),
          ],
        ),
      ),
    );
  }

  Widget _legend(ThemeData theme, Color color, String label, double percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text('$label ${percent.round()}%',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _disturbanceCard(ThemeData theme, Disturbance d) {
    final isNoise = d.type == DisturbanceType.environmentalNoise;
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
            child: Icon(
                isNoise
                    ? Icons.volume_up_rounded
                    : Icons.directions_walk_rounded,
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
                      child: Text(
                          isNoise ? 'Loud Noise Detected' : 'Restless Movement',
                          style: theme.textTheme.titleMedium),
                    ),
                    Text(Fmt.clock(d.timestamp),
                        style: theme.textTheme.bodyMedium),
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
