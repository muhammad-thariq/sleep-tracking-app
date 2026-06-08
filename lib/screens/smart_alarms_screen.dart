import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/day_selector.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class SmartAlarmsScreen extends StatefulWidget {
  const SmartAlarmsScreen({super.key});

  @override
  State<SmartAlarmsScreen> createState() => _SmartAlarmsScreenState();
}

class _SmartAlarmsScreenState extends State<SmartAlarmsScreen> {
  late final MockAlarm _smart =
      mockAlarms.firstWhere((a) => a.type == AlarmType.smart);
  late final MockAlarm _standard =
      mockAlarms.firstWhere((a) => a.type == AlarmType.standard);

  late final List<bool> _smartDays = List.of(_smart.days);
  late bool _smartEnabled = _smart.enabled;
  late bool _standardEnabled = _standard.enabled;

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
            Text('Smart Alarms', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Wake up gently during your optimal sleep cycle.',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            _smartCard(theme),
            const SizedBox(height: AppSpacing.md),
            _standardCard(theme),
            const SizedBox(height: AppSpacing.md),
            _addAlarmButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _smartCard(ThemeData theme) {
    return SurfaceCard(
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text('SMART WAKE', style: theme.textTheme.labelSmall),
              const Spacer(),
              const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Switch(
                value: _smartEnabled,
                onChanged: (v) => setState(() => _smartEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_smart.time,
              style: theme.textTheme.displayMedium
                  ?.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(_smart.window ?? '', style: theme.textTheme.bodyMedium),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          DaySelector(
            selected: _smartDays,
            onChanged: (i) =>
                setState(() => _smartDays[i] = !_smartDays[i]),
          ),
        ],
      ),
    );
  }

  Widget _standardCard(ThemeData theme) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_outlined,
                  color: AppColors.textTertiary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text('STANDARD', style: theme.textTheme.labelSmall),
              const Spacer(),
              Switch(
                value: _standardEnabled,
                onChanged: (v) => setState(() => _standardEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_standard.time,
              style: theme.textTheme.displayMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(_standard.label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textTertiary)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          DaySelector(selected: _standard.days), // read-only, all inactive
        ],
      ),
    );
  }

  Widget _addAlarmButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add New Alarm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
