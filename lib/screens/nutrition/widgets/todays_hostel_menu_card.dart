import 'package:flutter/material.dart';

import '../../../core/services/hostel_menu_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/nutrition/food_item.dart';
import '../../../models/nutrition/meal_category.dart';
import 'hostel_food_detail_sheet.dart';

/// Interactive UI section for "Today's Hostel/Mess Menu".
/// Displays individual selectable food items organized across Breakfast, Lunch, Evening, and Dinner.
class TodaysHostelMenuCard extends StatefulWidget {
  final Function(FoodItem food, MealCategory category)? onFoodSelected;

  const TodaysHostelMenuCard({super.key, this.onFoodSelected});

  @override
  State<TodaysHostelMenuCard> createState() => _TodaysHostelMenuCardState();
}

class _TodaysHostelMenuCardState extends State<TodaysHostelMenuCard> {
  final HostelMenuService _hostelMenuService = HostelMenuService.instance;

  // Selected filter tab: null means 'All' sections visible
  MealCategory? _selectedCategoryFilter;

  final List<MealCategory> _orderedCategories = const [
    MealCategory.breakfast,
    MealCategory.lunch,
    MealCategory.snacks, // Represents "Evening"
    MealCategory.dinner,
  ];

  String _getSectionTitle(MealCategory cat) {
    return _hostelMenuService.getSectionTitle(cat);
  }

  String _getSectionTiming(MealCategory cat) {
    switch (cat) {
      case MealCategory.breakfast:
        return '7:30 AM - 9:30 AM';
      case MealCategory.lunch:
        return '12:30 PM - 2:30 PM';
      case MealCategory.snacks:
        return '4:30 PM - 6:00 PM';
      case MealCategory.dinner:
        return '7:30 PM - 9:30 PM';
    }
  }

  void _handleFoodTapped(FoodItem food, MealCategory category) {
    if (widget.onFoodSelected != null) {
      widget.onFoodSelected!(food, category);
    } else {
      HostelFoodDetailSheet.show(context, food: food, category: category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.instance.currentUser;
    final activeMenu = _hostelMenuService.getTodaysMenu(
      college: user.college,
      campus: user.campus,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerDark, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Hostel/Mess Menu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 11,
                            color: AppColors.textSecondaryDark,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${activeMenu.college} • ${activeMenu.messName}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: const Text(
                    'LIVE MESS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Filter Chips: All, Breakfast, Lunch, Evening, Dinner
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Meals',
                  isSelected: _selectedCategoryFilter == null,
                  onTap: () {
                    setState(() {
                      _selectedCategoryFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 6),
                ..._orderedCategories.map((cat) {
                  final isSelected = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterChip(
                      label: _getSectionTitle(cat),
                      isSelected: isSelected,
                      accentColor: cat.accentColor,
                      onTap: () {
                        setState(() {
                          _selectedCategoryFilter = cat;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorderDark, height: 1),

          // Meal Sections List
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCategoryFilter == null) ...[
                  // Show all 4 sections
                  for (int i = 0; i < _orderedCategories.length; i++) ...[
                    _buildMealSectionBlock(
                      _orderedCategories[i],
                      college: user.college,
                      campus: user.campus,
                    ),
                    if (i < _orderedCategories.length - 1)
                      const SizedBox(height: 14),
                  ],
                ] else ...[
                  // Show only the selected section
                  _buildMealSectionBlock(
                    _selectedCategoryFilter!,
                    college: user.college,
                    campus: user.campus,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? accentColor,
    required VoidCallback onTap,
  }) {
    final effectiveAccent = accentColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveAccent.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? effectiveAccent : AppColors.cardBorderDark,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? effectiveAccent : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildMealSectionBlock(
    MealCategory category, {
    String? college,
    String? campus,
  }) {
    final foods = _hostelMenuService.getFoodsForSection(
      category,
      college: college,
      campus: campus,
    );
    final sectionTitle = _getSectionTitle(category);
    final timing = _getSectionTiming(category);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: category.accentColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Sub-Header: Title & Timing
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: category.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: category.accentColor,
                ),
              ),
              const Spacer(),
              Text(
                timing,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Individual Food Items
          if (foods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No mess items scheduled for this meal.',
                style: TextStyle(fontSize: 12, color: AppColors.textMutedDark),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: foods.map((food) {
                return _buildIndividualFoodChip(food, category);
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _getFoodDisplayName(FoodItem food) {
    if (food.id == 'food_potato_curry') return 'Alu Dum';
    if (food.id == 'food_fish') return 'Fish Curry';
    if (food.id == 'food_soya') return 'Soya Bean';
    if (food.id == 'food_vegetables') return 'Mixed Vegetable';
    if (food.name.contains('(')) {
      return food.name.split('(').first.trim();
    }
    return food.name;
  }

  Widget _buildIndividualFoodChip(FoodItem food, MealCategory category) {
    final displayName = _getFoodDisplayName(food);
    return InkWell(
      onTap: () => _handleFoodTapped(food, category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 130, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderDark, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Veg/Non-Veg dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: food.isVegetarian
                      ? AppColors.primary
                      : AppColors.accentRed,
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: food.isVegetarian
                        ? AppColors.primary
                        : AppColors.accentRed,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Name & Macros
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.calories.toInt()} kcal • ${food.protein.toStringAsFixed(1)}g P',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Tap indicator
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
