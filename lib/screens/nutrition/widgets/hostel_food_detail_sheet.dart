import 'package:flutter/material.dart';

import '../../../core/services/nutrition_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/nutrition/food_item.dart';
import '../../../models/nutrition/meal_category.dart';

/// Modal bottom sheet displaying detailed nutritional information
/// for a selected hostel food item with a direct "Add Meal" / "Log" action.
class HostelFoodDetailSheet extends StatefulWidget {
  final FoodItem food;
  final MealCategory category;

  const HostelFoodDetailSheet({
    super.key,
    required this.food,
    required this.category,
  });

  static Future<void> show(
    BuildContext context, {
    required FoodItem food,
    required MealCategory category,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          HostelFoodDetailSheet(food: food, category: category),
    );
  }

  @override
  State<HostelFoodDetailSheet> createState() => _HostelFoodDetailSheetState();
}

class _HostelFoodDetailSheetState extends State<HostelFoodDetailSheet> {
  double _servings = 1.0;
  bool _isLogging = false;

  String _getCategoryDisplayName(MealCategory cat) {
    switch (cat) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.snacks:
        return 'Evening';
      case MealCategory.dinner:
        return 'Dinner';
    }
  }

  Future<void> _handleLogMeal() async {
    setState(() {
      _isLogging = true;
    });

    try {
      await NutritionService.instance.logFood(
        food: widget.food,
        category: widget.category,
        servings: _servings,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged ${widget.food.name} (${_servings}x) to ${_getCategoryDisplayName(widget.category)}',
            ),
            backgroundColor: AppColors.surfaceElevatedDark,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final liveValues = food.calculateForServings(_servings);
    final categoryName = _getCategoryDisplayName(widget.category);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorderDark, width: 1.2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorderDark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row: Veg/Non-Veg Badge & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: food.isVegetarian
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: food.isVegetarian
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.accentRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: food.isVegetarian
                          ? AppColors.primary
                          : AppColors.accentRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      food.isVegetarian ? 'Vegetarian' : 'Non-Vegetarian',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: food.isVegetarian
                            ? AppColors.primary
                            : AppColors.accentRed,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondaryDark,
                ),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Food Name
          Text(
            food.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),

          // Serving Size & Category Tag
          Row(
            children: [
              const Icon(
                Icons.restaurant_outlined,
                size: 14,
                color: AppColors.textMutedDark,
              ),
              const SizedBox(width: 5),
              Text(
                'Serving Size: ${food.servingSize}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardBorderDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Nutritional Breakdown Grid (Calories, Protein, Carbs, Fats)
          Row(
            children: [
              _buildMacroBox(
                label: 'Calories',
                value: liveValues.calories.toStringAsFixed(0),
                unit: 'kcal',
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 8),
              _buildMacroBox(
                label: 'Protein',
                value: liveValues.protein.toStringAsFixed(1),
                unit: 'g',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildMacroBox(
                label: 'Carbs',
                value: liveValues.carbohydrates.toStringAsFixed(1),
                unit: 'g',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _buildMacroBox(
                label: 'Fats',
                value: liveValues.fats.toStringAsFixed(1),
                unit: 'g',
                color: const Color(0xFFA855F7),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Serving Quantity Multiplier Selector
          Row(
            children: [
              const Text(
                'Serving Quantity:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const Spacer(),
              ...[0.5, 1.0, 1.5, 2.0].map((qty) {
                final isSelected = (_servings - qty).abs() < 0.05;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _servings = qty;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorderDark,
                        ),
                      ),
                      child: Text(
                        '${qty}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.black
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Action Button: Add Meal / Log
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLogging ? null : _handleLogMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isLogging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.add_task_rounded, size: 20),
              label: Text(
                'Add to $categoryName • ${liveValues.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBox({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
