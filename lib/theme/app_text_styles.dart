import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named text styles for SleepWell.
///
/// These are mapped into the [TextTheme] in `app_theme.dart`, so screens can
/// reach them via `Theme.of(context).textTheme.*`. They are also exposed
/// directly here for the handful of cases where the theme slot doesn't line up.
class AppTextStyles {
  AppTextStyles._();

  /// "06:30" alarm time, "03:14:02" tracker.
  static const displayLarge = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.05,
  );

  /// Sleep quality score "85".
  static const displayMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.05,
  );

  /// Screen titles like "Smart Alarms".
  static const headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Card titles.
  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// List item titles.
  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Descriptions.
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Uppercase labels like "PREFERENCES", "SMART WAKE".
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.textTertiary,
  );
}
