import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized premium typography hierarchy for GenFit.
/// Strong athletic display headings, impactful numerical metrics, and modern sports editorial rhythm.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heroHeadline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.15,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
    height: 1.2,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.35,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMutedDark,
    height: 1.35,
  );

  // High-emphasis numerical metrics (reps, steps, calories, xp, streak)
  static const TextStyle statHero = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimaryDark,
    letterSpacing: -1.5,
    height: 1.0,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimaryDark,
    letterSpacing: -0.8,
    height: 1.05,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryDark,
    letterSpacing: 0.6,
  );

  static const TextStyle kicker = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.brightPurple,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );
}
