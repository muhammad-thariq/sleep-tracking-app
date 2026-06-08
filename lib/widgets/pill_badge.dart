import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum PillVariant { success, info }

/// Rounded full pill with a colored dot + label, e.g. green dot +
/// "Excellent Recovery".
class PillBadge extends StatelessWidget {
  final String label;
  final PillVariant variant;
  final IconData? icon;
  final bool outlined;

  const PillBadge({
    super.key,
    required this.label,
    this.variant = PillVariant.success,
    this.icon,
    this.outlined = false,
  });

  Color get _accent =>
      variant == PillVariant.success ? AppColors.success : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: _accent, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: AppSpacing.xs + 2),
          ] else ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }
}
