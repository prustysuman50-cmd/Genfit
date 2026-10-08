import 'package:flutter/material.dart';

import '../../../core/services/daily_stats_service.dart';
import '../../../core/services/nutrition_service.dart';
import '../../../core/theme/app_colors.dart';

class NutritionDashboardHeader extends StatelessWidget {
  final NutritionService nutrition;
  final DailyStatsService? dailyStatsService;

  const NutritionDashboardHeader({
    super.key,
    required this.nutrition,
    this.dailyStatsService,
  });

  @override
  Widget build(BuildContext context) {
    final daily = (dailyStatsService ?? DailyStatsService.instance).todayStats;
    final calorieConsumed = nutrition.todayCalories;
    final calorieTarget = daily.caloriesConsumedGoal;
    final calorieProgress = calorieTarget > 0
        ? (calorieConsumed / calorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final caloriesRemaining = (calorieTarget - calorieConsumed) > 0
        ? double.parse((calorieTarget - calorieConsumed).toStringAsFixed(1))
        : 0.0;

    final proteinConsumed = nutrition.todayProtein;
    final proteinTarget = daily.proteinGoalGrams;
    final proteinProgress = proteinTarget > 0
        ? (proteinConsumed / proteinTarget).clamp(0.0, 1.0)
        : 0.0;
    final proteinRemaining = (proteinTarget - proteinConsumed) > 0
        ? double.parse((proteinTarget - proteinConsumed).toStringAsFixed(1))
        : 0.0;

    final carbsConsumed = nutrition.todayCarbs;
    final fatsConsumed = nutrition.todayFats;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.purpleGlow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/nutrition/healthy_fuel.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: AppColors.surfaceDark);
                },
              ),
            ),

            // Deep Dark Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF09090D).withValues(alpha: 0.92),
                      const Color(0xFF14141D).withValues(alpha: 0.88),
                      const Color(0xFF211D2C).withValues(alpha: 0.85),
                      const Color(0xFF09090D).withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title kicker & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.brightPurple.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: AppColors.brightPurple,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'DAILY TARGETS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brightPurple,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Fuel your progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.softPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Hero Row: Large Circular Calorie/Macro Progress Gauge + Values
                  Row(
                    children: [
                      // Circular Gauge
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 96,
                              height: 96,
                              child: CircularProgressIndicator(
                                value: calorieProgress.clamp(0.0, 1.0),
                                strokeWidth: 9,
                                strokeCap: StrokeCap.round,
                                backgroundColor: AppColors.surfaceElevatedDark,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brightPurple,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${calorieConsumed.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimaryDark,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'KCAL',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.softPurple,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Side Details: Targets & Remaining
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goal: ${calorieTarget.toInt()} kcal',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${caloriesRemaining.toInt()} kcal left for today',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Quick Macro Progress row
                            Row(
                              children: [
                                _buildMiniMacroPill(
                                  'PROTEIN',
                                  '${proteinConsumed.toStringAsFixed(1)}g / ${proteinTarget.toStringAsFixed(0)}g',
                                  AppColors.brightPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2 Metric Cards: CALORIES & PROTEIN
                  Row(
                    children: [
                      // CALORIES Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(
                              alpha: 0.85,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CALORIES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentOrange,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${(calorieProgress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${calorieConsumed.toInt()} / ${calorieTarget.toInt()} kcal',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: calorieProgress.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor:
                                      AppColors.surfaceElevatedDark,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.accentOrange,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${caloriesRemaining.toInt()} kcal remaining',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // PROTEIN Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(
                              alpha: 0.85,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'PROTEIN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brightPurple,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${(proteinProgress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brightPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${proteinConsumed.toStringAsFixed(1)}g',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  Text(
                                    ' / ${proteinTarget.toStringAsFixed(0)}g',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: proteinProgress.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor:
                                      AppColors.surfaceElevatedDark,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.brightPurple,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${proteinRemaining.toStringAsFixed(1)}g remaining',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Carbs & Fats Breakdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark.withValues(
                        alpha: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorderDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroMetric(
                          'Carbs',
                          '${carbsConsumed.toStringAsFixed(1)}g',
                          AppColors.accentYellow,
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: AppColors.dividerDark,
                        ),
                        _buildMacroMetric(
                          'Fats',
                          '${fatsConsumed.toStringAsFixed(1)}g',
                          AppColors.accentCyan,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMetric(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }
}
