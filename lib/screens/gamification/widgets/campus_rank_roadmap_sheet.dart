import 'package:flutter/material.dart';

import '../../../core/services/gamification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/gamification/campus_rank.dart';

/// Reusable modal sheet displaying GenFit's 8-Tier Campus Rank Roadmap.
///
/// Features:
/// - Displays all 8 ranks in strict progression order.
/// - Shows real XP thresholds from [GamificationService].
/// - Clearly highlights the current active rank with reactive progress.
/// - Handles max-rank (Grandmaster) cleanly without nonexistent next-rank calculation.
/// - Completely read-only: does not modify XP, awards, or persistence.
class CampusRankRoadmapSheet extends StatelessWidget {
  const CampusRankRoadmapSheet({super.key});

  /// Presents the Campus Rank Roadmap modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CampusRankRoadmapSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamificationService.instance,
      builder: (context, _) {
        final gamification = GamificationService.instance;
        final tiers = gamification.allTiers;
        final currentLevel = gamification.currentLevel;
        final isMaxRank = gamification.isMaxRank;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorderDark, width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.cardBorderDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.brightPurple.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.military_tech_rounded,
                                size: 18,
                                color: AppColors.brightPurple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CAMPUS RANK ROADMAP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                                Text(
                                  '8-Tier Campus RPG Progression',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondaryDark,
                            size: 20,
                          ),
                          splashRadius: 18,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.dividerDark, height: 1),

              // 2. Active Athlete Summary Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E1A33),
                      Color(0xFF26194A),
                      Color(0xFF161426),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.brightPurple.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brightPurple.withValues(
                                  alpha: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LEVEL $currentLevel',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brightPurple,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gamification.levelTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimaryDark,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${gamification.xp} XP',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: gamification.levelProgress,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceDark.withValues(
                          alpha: 0.8,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brightPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMaxRank
                          ? '🏆 Maximum Campus Rank Achieved (Pinnacle)'
                          : '${gamification.xpRequiredForNextLevel} XP needed for Level ${currentLevel + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Scrollable List of All 8 Tiers
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  child: Column(
                    children: [
                      for (int i = 0; i < tiers.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _RankTierCard(
                          tier: tiers[i],
                          isCurrent: tiers[i].level == currentLevel,
                          isUnlocked: tiers[i].level < currentLevel,
                          isLocked: tiers[i].level > currentLevel,
                          gamification: gamification,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankTierCard extends StatelessWidget {
  final CampusRankTier tier;
  final bool isCurrent;
  final bool isUnlocked;
  final bool isLocked;
  final GamificationService gamification;

  const _RankTierCard({
    required this.tier,
    required this.isCurrent,
    required this.isUnlocked,
    required this.isLocked,
    required this.gamification,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color backgroundColor;
    Color iconColor;
    Widget statusBadge;

    if (isCurrent) {
      borderColor = AppColors.brightPurple;
      backgroundColor = const Color(0xFF221A3D);
      iconColor = AppColors.accentYellow;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.brightPurple.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.brightPurple.withValues(alpha: 0.6),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 11, color: AppColors.accentYellow),
            SizedBox(width: 3),
            Text(
              'CURRENT RANK',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: AppColors.accentYellow,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    } else if (isUnlocked) {
      borderColor = AppColors.primary.withValues(alpha: 0.3);
      backgroundColor = AppColors.surfaceDark;
      iconColor = AppColors.primary;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 10, color: AppColors.primary),
            SizedBox(width: 3),
            Text(
              'UNLOCKED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    } else {
      borderColor = AppColors.cardBorderDark;
      backgroundColor = AppColors.surfaceDark.withValues(alpha: 0.5);
      iconColor = AppColors.textMutedDark;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 10, color: AppColors.textMutedDark),
            SizedBox(width: 3),
            Text(
              'LOCKED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedDark,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.purpleGlow.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tier Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.brightPurple.withValues(alpha: 0.25)
                      : AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tier.icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level ${tier.level} • ${tier.title}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isLocked
                                ? AppColors.textSecondaryDark
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isLocked
                            ? AppColors.textMutedDark
                            : AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.xpRangeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? AppColors.accentYellow
                            : isUnlocked
                                ? AppColors.primary
                                : AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // If Current Rank: Show embedded progress toward next rank
          if (isCurrent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.brightPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tier.level == 8
                            ? 'Max Rank Reached'
                            : 'Progress to Level ${tier.level + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        '${(gamification.levelProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brightPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: gamification.levelProgress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceElevatedDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brightPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tier.level == 8
                        ? '🏆 Maximum Athletic Rank Achieved — No higher rank exists!'
                        : '${gamification.xpRequiredForNextLevel} XP needed for Level ${tier.level + 1} (${tier.maxXp + 1} XP)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
