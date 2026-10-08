import 'package:flutter/material.dart';

import '../../../core/services/daily_stats_service.dart';
import '../../../core/services/hostel_menu_service.dart';
import '../../../core/services/nutrition_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/nutrition/meal_category.dart';

class HostelFuelPreview extends StatelessWidget {
  final VoidCallback? onOpenMenu;

  const HostelFuelPreview({super.key, this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        NutritionService.instance,
        DailyStatsService.instance,
      ]),
      builder: (context, _) {
        final ns = NutritionService.instance;
        final stats = DailyStatsService.instance.todayStats;
        final cals = ns.todayCalories.toInt();
        final calGoal = stats.caloriesConsumedGoal.toInt();
        final protein = ns.todayProtein.toInt();
        final proteinGoal = stats.proteinGoalGrams.toInt();
        final calProg = calGoal > 0 ? (cals / calGoal).clamp(0.0, 1.0) : 0.0;
        final protProg = proteinGoal > 0
            ? (protein / proteinGoal).clamp(0.0, 1.0)
            : 0.0;

        final lunchFoods = HostelMenuService.instance.getFoodsForSection(
          MealCategory.lunch,
        );
        final sampleFoodNames = lunchFoods
            .take(4)
            .map((f) => f.name)
            .join(' • ');

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorderDark, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Hostel Fuel & Nutrition',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onOpenMenu,
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'Full Menu →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brightPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Mess fuel intake, protein tracking & budget swaps',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 14),

              // 2-Column Macros
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'CALORIES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentOrange,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cals kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: calProg,
                              minHeight: 5,
                              backgroundColor: AppColors.surfaceDark,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accentOrange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal $calGoal kcal',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMutedDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'PROTEIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brightPurple,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${protein}g',
                                style: const TextStyle(
                                  fontSize: 12,
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
                              value: protProg,
                              minHeight: 5,
                              backgroundColor: AppColors.surfaceDark,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.brightPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal ${proteinGoal}g',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMutedDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (sampleFoodNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Today in mess: $sampleFoodNames',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
