import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm_config.dart';
import '../services/formatting.dart';
import '../state/alarms_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'day_selector.dart';

/// Opens the alarm editor as a modal bottom sheet. Pass [existing] to edit, or
/// null to create a new alarm.
Future<void> showAlarmEditSheet(
  BuildContext context,
  WidgetRef ref, {
  AlarmConfig? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
    ),
    builder: (_) => _AlarmEditSheet(existing: existing),
  );
}

class _AlarmEditSheet extends ConsumerStatefulWidget {
  final AlarmConfig? existing;
  const _AlarmEditSheet({this.existing});

  @override
  ConsumerState<_AlarmEditSheet> createState() => _AlarmEditSheetState();
}

class _AlarmEditSheetState extends ConsumerState<_AlarmEditSheet> {
  late AlarmType _type;
  late TimeOfDay _time;
  late TextEditingController _label;
  late double _windowMinutes;
  late List<bool> _days;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? AlarmType.smart;
    _time = e?.timeOfDay ?? const TimeOfDay(hour: 6, minute: 30);
    _label = TextEditingController(text: e?.label ?? '');
    _windowMinutes = (e?.windowMinutes ?? 30).toDouble();
    _days = List.of(e?.activeDays ?? const [false, true, true, true, true, true, false]);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final alarm = AlarmConfig(
      id: widget.existing?.id ?? AlarmsNotifier.newId(),
      type: _type,
      time: AlarmConfig.minutesFromTimeOfDay(_time),
      label: _label.text.trim().isEmpty
          ? (_type == AlarmType.smart ? 'Smart Wake' : 'Alarm')
          : _label.text.trim(),
      windowMinutes: _type == AlarmType.smart ? _windowMinutes.round() : null,
      activeDays: _days,
      enabled: widget.existing?.enabled ?? true,
    );
    ref.read(alarmsProvider.notifier).upsert(alarm);
    Navigator.of(context).pop();
  }

  void _delete() {
    if (widget.existing != null) {
      ref.read(alarmsProvider.notifier).delete(widget.existing!.id);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditing ? 'Edit Alarm' : 'New Alarm',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),

          // Time
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(Fmt.hm24(_time),
                  style: theme.textTheme.displayMedium
                      ?.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Type
          SegmentedButton<AlarmType>(
            segments: const [
              ButtonSegment(value: AlarmType.smart, label: Text('Smart')),
              ButtonSegment(value: AlarmType.standard, label: Text('Standard')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Label
          TextField(
            controller: _label,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: theme.textTheme.bodyMedium,
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Smart window slider
          if (_type == AlarmType.smart) ...[
            Text('WAKE WINDOW: ${_windowMinutes.round()} MIN',
                style: theme.textTheme.labelSmall),
            Slider(
              value: _windowMinutes,
              min: 15,
              max: 45,
              divisions: 6,
              activeColor: AppColors.primary,
              label: '${_windowMinutes.round()} min',
              onChanged: (v) => setState(() => _windowMinutes = v),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Days
          Text('REPEAT', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          DaySelector(
            selected: _days,
            onChanged: (i) => setState(() => _days[i] = !_days[i]),
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              if (_isEditing) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.6)),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
