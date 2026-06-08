import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

/// Bottom nav for the 5 main tabs. Driven by the [StatefulShellRoute]:
/// [currentIndex] is the active branch, [onTap] switches branch.
class SleepBottomNav extends StatelessWidget {
  static const _items = [
    _NavItem(Icons.home_outlined, 'Home'),
    _NavItem(Icons.show_chart, 'Track'),
    _NavItem(Icons.bar_chart, 'Analysis'),
    _NavItem(Icons.alarm_outlined, 'Alarm'),
    _NavItem(Icons.person_outline, 'Profile'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  const SleepBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              final color =
                  active ? AppColors.primary : AppColors.textSecondary;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: color, size: 24),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Small dot indicator under the active item.
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
