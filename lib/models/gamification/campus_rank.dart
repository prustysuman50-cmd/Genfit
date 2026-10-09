import 'package:flutter/material.dart';

/// Represents a distinct athletic tier in GenFit's 8-tier Campus RPG progression system.
class CampusRankTier {
  final int level;
  final int minXp;
  final int maxXp;
  final String title;
  final String subtitle;
  final IconData icon;

  const CampusRankTier({
    required this.level,
    required this.minXp,
    required this.maxXp,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  /// Human-readable XP threshold range for this tier.
  String get xpRangeLabel {
    if (level == 8) {
      return '$minXp+ XP';
    }
    return '$minXp – $maxXp XP';
  }
}
