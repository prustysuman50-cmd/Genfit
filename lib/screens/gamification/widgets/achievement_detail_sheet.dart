import 'package:flutter/material.dart';

import '../../../core/services/gamification_service.dart';
import '../../../core/services/heritage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/gamification/achievement_progress.dart';
import '../../../models/gamification/badge_item.dart';

/// Polished modal bottom sheet displaying complete achievement details.
///
/// Features:
/// - Shows badge emblem, name, category, and locked/unlocked state.
/// - Shows genuine verified progress and target derived from source-of-truth services.
/// - Shows human-readable unlock timestamp when available.
/// - Shows an honest, motivating instruction message when locked.
/// - Completely read-only: opening and dismissing leaves all state unmodified.
class AchievementDetailSheet extends StatelessWidget {
  final BadgeItem badge;
  final GamificationService gamification;
  final HeritageService? heritageService;

  const AchievementDetailSheet({
    super.key,
    required this.badge,
    required this.gamification,
    this.heritageService,
  });

  /// Presents the Achievement Detail bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required BadgeItem badge,
    required GamificationService gamification,
    HeritageService? heritageService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AchievementDetailSheet(
        badge: badge,
        gamification: gamification,
        heritageService: heritageService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = AchievementProgress.compute(
      badge,
      gamification,
      heritageService: heritageService,
    );
    final isUnlocked = badge.isUnlocked;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: isUnlocked
                ? AppColors.brightPurple.withValues(alpha: 0.5)
                : AppColors.cardBorderDark,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          if (isUnlocked)
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Top Drag Handle & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 36),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondaryDark,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Large Badge Icon Emblem
              _buildBadgeEmblem(isUnlocked),
              const SizedBox(height: 16),

              // 3. Badge Name
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // 4. Category & Status Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      badge.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.softPurple,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.cardBorderDark,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked
                              ? Icons.check_circle_rounded
                              : Icons.lock_rounded,
                          size: 12,
                          color: isUnlocked
                              ? AppColors.success
                              : AppColors.textMutedDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isUnlocked ? 'UNLOCKED' : 'LOCKED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isUnlocked
                                ? AppColors.success
                                : AppColors.textMutedDark,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Verified Progress Indicator Card
              _buildProgressCard(progress, isUnlocked),
              const SizedBox(height: 16),

              // 7. Unlock Status / Motivation Card
              if (isUnlocked)
                _buildUnlockedInfoCard()
              else
                _buildMotivationCard(),
              const SizedBox(height: 24),

              // 8. Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevatedDark,
                    foregroundColor: AppColors.textPrimaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.cardBorderDark),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeEmblem(bool isUnlocked) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUnlocked
            ? const LinearGradient(
                colors: [Color(0xFF381E72), Color(0xFF1E153D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  AppColors.surfaceElevatedDark,
                  AppColors.surfaceDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isUnlocked
              ? AppColors.accentYellow.withValues(alpha: 0.8)
              : AppColors.cardBorderDark,
          width: isUnlocked ? 2.0 : 1.2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.accentYellow.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.purpleGlow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          badge.icon,
          size: 44,
          color: isUnlocked ? AppColors.accentYellow : AppColors.textMutedDark,
        ),
      ),
    );
  }

  Widget _buildProgressCard(AchievementProgress progress, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? AppColors.brightPurple.withValues(alpha: 0.3)
              : AppColors.cardBorderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMutedDark,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${progress.displayText} (${progress.percent}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked
                      ? AppColors.accentYellow
                      : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevatedDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUnlocked ? AppColors.accentYellow : AppColors.brightPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedInfoCard() {
    final unlockedDate = badge.unlockedAt != null
        ? AchievementProgress.formatUnlockDate(badge.unlockedAt!)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Achievement Unlocked',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unlockedDate != null
                      ? 'Unlocked on $unlockedDate'
                      : 'Completed and recorded in your profile',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    final motivation = AchievementProgress.motivationForBadgeId(badge.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorderDark,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How to Unlock',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  motivation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
