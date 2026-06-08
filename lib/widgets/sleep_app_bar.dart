import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Top bar shared by the 5 main screens: avatar, "SleepWell" wordmark, gear.
///
/// Transparent over the scaffold background with no bottom border.
class SleepAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SleepAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppSpacing.md,
      leadingWidth: 36 + AppSpacing.md + AppSpacing.sm,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Center(
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceElevated,
            backgroundImage: NetworkImage(mockUser.avatarUrl),
          ),
        ),
      ),
      title: const Text(
        'SleepWell',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textPrimary, size: 24),
          onPressed: () => context.go('/profile'),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
