import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/alarm_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/pill_badge.dart';

/// Full-screen alarm view — no app bar, no bottom nav. Opened by the alarm
/// notification's full-screen intent (Phase 2) or the dashboard debug button.
class AlarmRingingScreen extends ConsumerStatefulWidget {
  final String? alarmId;
  const AlarmRingingScreen({super.key, this.alarmId});

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> {
  @override
  void initState() {
    super.initState();
    // Start the looping alarm sound as soon as the screen appears.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(alarmServiceProvider).startSound());
  }

  Future<void> _snooze() async {
    await ref.read(alarmServiceProvider).snooze(widget.alarmId ?? '');
    if (mounted) _leave();
  }

  /// To stop the alarm the user must first solve a quick math puzzle — this
  /// forces a bit of mental effort so they're actually awake, not dismissing it
  /// in their sleep. The alarm keeps ringing until the puzzle is solved.
  Future<void> _attemptStop() async {
    final solved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WakeUpPuzzleSheet(),
    );
    if (solved == true) _stop();
  }

  Future<void> _stop() async {
    await ref.read(alarmServiceProvider).stop();
    if (mounted) _leave();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

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
              _stopButton(),
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
    return GestureDetector(
      onTap: _snooze,
      child: Container(
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
      ),
    );
  }

  Widget _stopButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _attemptStop,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        icon: const Icon(Icons.lock_open),
        label: const Text('Solve to Stop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// A simple wake-up challenge: solve a randomly generated arithmetic problem by
/// picking the correct answer. Pops `true` only when solved. A wrong tap
/// shakes/regenerates so a sleepy user can't just mash a button.
class _WakeUpPuzzleSheet extends StatefulWidget {
  const _WakeUpPuzzleSheet();

  @override
  State<_WakeUpPuzzleSheet> createState() => _WakeUpPuzzleSheetState();
}

class _WakeUpPuzzleSheetState extends State<_WakeUpPuzzleSheet> {
  final _rng = Random();
  late int _a;
  late int _b;
  late String _op;
  late int _answer;
  late List<int> _choices;
  bool _wrong = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    // Keep numbers small and positive so it's solvable, not frustrating.
    final ops = ['+', '−', '×'];
    _op = ops[_rng.nextInt(ops.length)];
    switch (_op) {
      case '+':
        _a = _rng.nextInt(40) + 10; // 10–49
        _b = _rng.nextInt(40) + 10;
        _answer = _a + _b;
        break;
      case '−':
        _a = _rng.nextInt(40) + 20; // 20–59
        _b = _rng.nextInt(_a - 5) + 1; // < _a so result is positive
        _answer = _a - _b;
        break;
      default: // ×
        _a = _rng.nextInt(8) + 3; // 3–10
        _b = _rng.nextInt(8) + 3;
        _answer = _a * _b;
    }

    // Build four unique choices including the correct answer.
    final set = <int>{_answer};
    while (set.length < 4) {
      final delta = _rng.nextInt(11) - 5; // -5..+5
      final candidate = _answer + (delta == 0 ? 7 : delta);
      if (candidate >= 0) set.add(candidate);
    }
    _choices = set.toList()..shuffle(_rng);
  }

  void _onTap(int choice) {
    if (choice == _answer) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _wrong = true;
      _attempts++;
      _generate(); // new problem on every miss
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const PillBadge(
            label: 'WAKE-UP CHALLENGE',
            variant: PillVariant.success,
            icon: Icons.bolt,
            outlined: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Solve to stop the alarm',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$_a $_op $_b = ?',
            style: theme.textTheme.displayLarge
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.6,
            children: [
              for (final choice in _choices)
                _ChoiceButton(value: choice, onTap: () => _onTap(choice)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 20,
            child: _wrong
                ? Text(
                    'Not quite — here\'s a new one ($_attempts misses)',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.warning),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final int value;
  final VoidCallback onTap;
  const _ChoiceButton({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          '$value',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
