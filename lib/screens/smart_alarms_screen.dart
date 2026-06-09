import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm_config.dart';
import '../services/formatting.dart';
import '../state/alarms_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/alarm_edit_sheet.dart';
import '../widgets/day_selector.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class SmartAlarmsScreen extends ConsumerWidget {
  const SmartAlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alarms = ref.watch(alarmsProvider);

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
            for (final alarm in alarms) ...[
              alarm.type == AlarmType.smart
                  ? _smartCard(context, ref, theme, alarm)
                  : _standardCard(context, ref, theme, alarm),
              const SizedBox(height: AppSpacing.md),
            ],
            _addAlarmButton(context, ref, theme),
          ],
        ),
      ),
    );
  }

  Widget _smartCard(
      BuildContext context, WidgetRef ref, ThemeData theme, AlarmConfig a) {
    final on = a.enabled;
    return Opacity(
      opacity: on ? 1 : 0.55,
      child: SurfaceCard(
        border: Border.all(
          color: on
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: on ? 1.5 : 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text('SMART WAKE', style: theme.textTheme.labelSmall),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () =>
                      showAlarmEditSheet(context, ref, existing: a),
                ),
                Switch(
                  value: on,
                  onChanged: (_) =>
                      ref.read(alarmsProvider.notifier).toggle(a.id),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(Fmt.hm24FromMinutes(a.time),
                style: theme.textTheme.displayMedium
                    ?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(_windowLabel(a), style: theme.textTheme.bodyMedium),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(),
            ),
            DaySelector(
              selected: a.activeDays,
              onChanged: (i) => _toggleDay(ref, a, i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _standardCard(
      BuildContext context, WidgetRef ref, ThemeData theme, AlarmConfig a) {
    final on = a.enabled;
    return Opacity(
      opacity: on ? 1 : 0.55,
      child: SurfaceCard(
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
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () =>
                      showAlarmEditSheet(context, ref, existing: a),
                ),
                Switch(
                  value: on,
                  onChanged: (_) =>
                      ref.read(alarmsProvider.notifier).toggle(a.id),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(Fmt.hm24FromMinutes(a.time),
                style: theme.textTheme.displayMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Text(a.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textTertiary)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(),
            ),
            DaySelector(
              selected: a.activeDays,
              onChanged: (i) => _toggleDay(ref, a, i),
            ),
          ],
        ),
      ),
    );
  }

  String _windowLabel(AlarmConfig a) {
    final w = a.windowMinutes ?? 30;
    final startMin = a.time - w;
    return 'Window: ${Fmt.hm24FromMinutes(startMin)} – ${Fmt.hm24FromMinutes(a.time)}';
  }

  void _toggleDay(WidgetRef ref, AlarmConfig a, int index) {
    final days = List.of(a.activeDays);
    days[index] = !days[index];
    ref.read(alarmsProvider.notifier).upsert(a.copyWith(activeDays: days));
  }

  Widget _addAlarmButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => showAlarmEditSheet(context, ref),
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
