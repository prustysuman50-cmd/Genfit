import 'package:flutter/material.dart';

import '../../../core/services/nutrition_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/nutrition/logged_meal.dart';
import '../../../models/nutrition/meal_category.dart';

class MealCategorySection extends StatelessWidget {
  final MealCategory category;
  final List<LoggedMeal> meals;
  final VoidCallback onAddMeal;
  final Function(LoggedMeal) onDeleteMeal;

  const MealCategorySection({
    super.key,
    required this.category,
    required this.meals,
    required this.onAddMeal,
    required this.onDeleteMeal,
  });

  @override
  Widget build(BuildContext context) {
    final subtotalCalories = NutritionService.instance.caloriesForCategory(
      category,
    );
    final subtotalProtein = NutritionService.instance.proteinForCategory(
      category,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: meals.isNotEmpty
              ? category.accentColor.withValues(alpha: 0.25)
              : AppColors.dividerDark,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: category.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.accentColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Category Title & Timing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.displayName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (meals.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: category.accentColor.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${meals.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: category.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.suggestedTiming,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Add Meal Action Button
                FilledButton.tonal(
                  onPressed: onAddMeal,
                  style: FilledButton.styleFrom(
                    backgroundColor: category.accentColor.withValues(
                      alpha: 0.15,
                    ),
                    foregroundColor: category.accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: category.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Add Meal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Subtotal Bar if meals are logged
          if (meals.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    size: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Subtotal: ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  Text(
                    '${subtotalCalories.toInt()} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentOrange,
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: Colors.white38)),
                  Text(
                    '${subtotalProtein.toStringAsFixed(1)}g protein',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Meals List or Empty State
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: InkWell(
                onTap: onAddMeal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorderDark.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: category.accentColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No ${category.displayName.toLowerCase()} logged yet • Tap to add',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark.withValues(
                            alpha: 0.9,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              itemCount: meals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return _buildMealTile(context, meal);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMealTile(BuildContext context, LoggedMeal meal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderDark, width: 0.8),
      ),
      child: Row(
        children: [
          // Veg/Non-veg indicator
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(
                color: meal.isVegetarian
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: meal.isVegetarian
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Meal Name and Servings
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${meal.servings}x (${meal.servingSize})',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (meal.isBudgetAlternativeUsed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Budget Hack',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Calories & Protein tags
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal.calories.toInt()} kcal',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${meal.protein.toStringAsFixed(1)}g protein',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Delete Action
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textMutedDark,
            ),
            tooltip: 'Remove Meal',
            visualDensity: VisualDensity.compact,
            onPressed: () => onDeleteMeal(meal),
          ),
        ],
      ),
    );
  }
}
