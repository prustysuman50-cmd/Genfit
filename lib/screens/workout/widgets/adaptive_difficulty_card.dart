import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/workout/adaptive_difficulty.dart';

/// Card presenting the explainable adaptive workout difficulty recommendation,
/// along with real historical metrics and user-selectable difficulty chips.
class AdaptiveDifficultyCard extends StatelessWidget {
  final AdaptiveDifficultyRecommendation recommendation;
  final ValueChanged<WorkoutDifficultyLevel>? onSelectLevel;
  final VoidCallback? onAcceptRecommendation;

  const AdaptiveDifficultyCard({
    super.key,
    required this.recommendation,
    this.onSelectLevel,
    this.onAcceptRecommendation,
  });

  Color _levelColor(WorkoutDifficultyLevel level) {
    switch (level) {
      case WorkoutDifficultyLevel.beginner:
        return AppColors.accentCyan;
      case WorkoutDifficultyLevel.intermediate:
        return AppColors.primary;
      case WorkoutDifficultyLevel.advanced:
        return AppColors.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLevel = recommendation.currentLevel;
    final recommended = recommendation.recommendedLevel;
    final badgeColor = _levelColor(recommended);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: recommendation.isPromotion
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.dividerDark,
          width: recommendation.isPromotion ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Adaptive AI Tag + Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 14,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ADAPTIVE DIFFICULTY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    recommended.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target Specs Summary
                Row(
                  children: [
                    Text(
                      'Suggested Pace: ${recommended.targetRepsRange}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '~${recommended.defaultDurationMinutes} mins',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Explainable Rationale Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.cardBorderDark,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation.explanation,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondaryDark,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Manual Level Selection Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Tier:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    Row(
                      children: WorkoutDifficultyLevel.values.map((lvl) {
                        final isSelected = lvl == activeLevel;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => onSelectLevel?.call(lvl),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _levelColor(lvl).withValues(alpha: 0.2)
                                    : AppColors.surfaceElevatedDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? _levelColor(lvl)
                                      : AppColors.cardBorderDark,
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Text(
                                lvl.displayName,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? _levelColor(lvl)
                                      : AppColors.textMutedDark,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Promotion/Ramp-up Action Button
                if (recommendation.differsFromCurrent) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onAcceptRecommendation,
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text(
                        'Apply ${recommended.displayName} (${recommended.targetRepsRange})',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: badgeColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
