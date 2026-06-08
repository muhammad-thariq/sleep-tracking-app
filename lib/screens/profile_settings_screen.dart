import 'package:flutter/material.dart';

import '../models/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/sleep_app_bar.dart';
import '../widgets/surface_card.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _sleepGoals = true;
  bool _darkMode = true;
  bool _notifications = false;

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
            _profileCard(theme),
            const SizedBox(height: AppSpacing.md),
            _recommendationsCta(theme),
            const SizedBox(height: AppSpacing.lg),
            Text('PREFERENCES', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            _preferencesCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(ThemeData theme) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: NetworkImage(mockUser.avatarUrl),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(mockUser.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Sleep Explorer since ${mockUser.joinedYear}',
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _recommendationsCta(ThemeData theme) {
    return SurfaceCard(
      color: AppColors.primary,
      border: Border.all(color: AppColors.primary),
      onTap: () {},
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sleep Recommendations',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text('View your personalized insights',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textOnPrimary.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppColors.textOnPrimary, size: 18),
        ],
      ),
    );
  }

  Widget _preferencesCard(ThemeData theme) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _prefRow(Icons.flag_outlined, 'Sleep Goals', _sleepGoals,
              (v) => setState(() => _sleepGoals = v)),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          _prefRow(Icons.dark_mode_outlined, 'Dark Mode', _darkMode,
              (v) => setState(() => _darkMode = v)),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          _prefRow(Icons.notifications_outlined, 'Notifications',
              _notifications, (v) => setState(() => _notifications = v)),
        ],
      ),
    );
  }

  Widget _prefRow(
      IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
