import 'package:flutter/material.dart';

/// Central color palette for SleepWell.
///
/// Dark, minimalist base with light-blue accents. All widgets reference these
/// constants rather than hard-coding `Color(...)` values.
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF0A1224); // app scaffold
  static const surface = Color(0xFF161E36); // cards
  static const surfaceElevated = Color(0xFF1E2742); // nested cards / pills

  // Primary accent (light blue)
  static const primary = Color(0xFFA8D8F0); // main CTAs, brand text, score
  static const primaryDark = Color(0xFF7DB8E8); // selected day pills, accents

  // Status
  static const success = Color(0xFF22C55E); // "Excellent", "Optimal" badges
  static const danger = Color(0xFFDC2626); // Stop button, alerts
  static const warning = Color(0xFFEF4444); // disturbance icon bg

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B95A8);
  static const textTertiary = Color(0xFF5C6478); // small uppercase labels
  static const textOnPrimary = Color(0xFF0A1224); // dark text on light-blue buttons

  // Borders / dividers
  static const border = Color(0xFF2A3454);
}
