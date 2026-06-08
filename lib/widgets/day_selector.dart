import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Row of 7 circular day chips (S M T W T F S).
///
/// Stateful selection is owned by the parent: pass [selected] (length 7) and
/// receive taps through [onChanged]. When [onChanged] is null the row is
/// read-only (used for the faded "standard" alarm card).
class DaySelector extends StatelessWidget {
  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  final List<bool> selected;
  final ValueChanged<int>? onChanged;

  const DaySelector({
    super.key,
    required this.selected,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isActive = selected[i];
        return GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(i),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
