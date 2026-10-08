import 'package:flutter/material.dart';

/// Centralized premium color system for GenFit.
/// Deep Midnight background (#09090D) + sophisticated purple/violet accents (#7C3AED, #8B5CF6).
class AppColors {
  AppColors._();

  // Primary brand purple theme
  static const Color primary = Color(0xFF7C3AED); // Primary purple
  static const Color brightPurple = Color(0xFF8B5CF6); // Bright purple
  static const Color softPurple = Color(0xFFA78BFA); // Soft purple
  static const Color purpleGlow = Color(0xFF6D28D9); // Purple glow
  static const Color primaryGlow = Color(0xFF6D28D9); // Purple glow alias
  static const Color primaryDark = Color(0xFF5B21B6); // Deep purple
  static const Color primaryLight = Color(0xFFA78BFA); // Soft purple
  static const Color primaryContainer = Color(
    0xFF26184A,
  ); // Dark purple container

  // Energetic semantic accent colors
  static const Color accentCyan = Color(
    0xFF38BDF8,
  ); // Subtle telemetry blue/cyan
  static const Color accentOrange = Color(0xFFF97316); // Streak fire
  static const Color accentYellow = Color(0xFFEAB308); // XP & Badges
  static const Color accentPurple = Color(0xFF8B5CF6); // Bright purple accent
  static const Color accentRed = Color(0xFFEF4444); // Error/stop
  static const Color success = Color(0xFF10B981); // Subtle complementary green

  // Dark Theme Palette (Deep Black & Purple-tinted Midnight Surfaces)
  static const Color backgroundDark = Color(0xFF09090D); // Primary background
  static const Color secondaryBackgroundDark = Color(
    0xFF0F0F16,
  ); // Secondary background
  static const Color surfaceDark = Color(0xFF15151F); // Card / surface
  static const Color surfaceElevatedDark = Color(
    0xFF1C1A28,
  ); // Elevated surface
  static const Color cardDark = Color(0xFF15151F); // Muted card surface
  static const Color cardBorderDark = Color(
    0xFF292635,
  ); // Restrained border / divider
  static const Color dividerDark = Color(0xFF292635); // Clean divider

  // Light Theme Palette (fallback)
  static const Color backgroundLight = Color(0xFFF5F5FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFEFEFF8);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E0EE);

  // Text colors - Dark mode
  static const Color textPrimaryDark = Color(
    0xFFFFFFFF,
  ); // High-contrast primary text
  static const Color textSecondaryDark = Color(0xFFB8B5C7); // Secondary text
  static const Color textMutedDark = Color(
    0xFF777384,
  ); // Restrained caption text

  // Text colors - Light mode
  static const Color textPrimaryLight = Color(0xFF09090D);
  static const Color textSecondaryLight = Color(0xFF4A475A);
  static const Color textMutedLight = Color(0xFF8C889B);

  // Purposeful Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGlowGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1C1A28), Color(0xFF15151F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1A28), Color(0xFF15151F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFEA580C), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [Color(0xFFCA8A04), Color(0xFFEAB308)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
