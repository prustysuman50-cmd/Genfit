import 'package:flutter/material.dart';
import '../../../core/services/adaptive_difficulty_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/workout.dart';

class TodaysWorkoutSection extends StatelessWidget {
  final VoidCallback onStartWorkout;
  final Workout? workout;

  const TodaysWorkoutSection({
    super.key,
    required this.onStartWorkout,
    this.workout,
  });

  @override
  Widget build(BuildContext context) {
    final Workout activeWorkout = workout ??
        AdaptiveDifficultyService.instance.getAdaptiveTodaysWorkout();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    "TODAY'S PLAN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 15,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${activeWorkout.calories} kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentOrange,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeWorkout.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activeWorkout.category} • ${activeWorkout.equipment}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Specs Row
                Row(
                  children: [
                    _buildSpecChip(
                      Icons.timer_outlined,
                      '${activeWorkout.durationMinutes} mins',
                    ),
                    const SizedBox(width: 8),
                    _buildSpecChip(
                      Icons.fitness_center_outlined,
                      '${activeWorkout.exercisesCount} exercises',
                    ),
                    const SizedBox(width: 8),
                    _buildSpecChip(
                      Icons.trending_up_rounded,
                      activeWorkout.intensity,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: activeWorkout.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.dividerDark.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMutedDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onStartWorkout,
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: const Text(
                      'Start Today\'s AI Session',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondaryDark),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
