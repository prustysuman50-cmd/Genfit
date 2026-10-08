import 'package:flutter/material.dart';

import '../../../core/services/nutrition_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/local_food_database.dart';
import '../../../models/nutrition/food_item.dart';
import '../../../models/nutrition/meal_category.dart';

class AddMealSheet extends StatefulWidget {
  final MealCategory initialCategory;
  final FoodItem? initialFood;

  const AddMealSheet({
    super.key,
    this.initialCategory = MealCategory.breakfast,
    this.initialFood,
  });

  static Future<void> show(
    BuildContext context, {
    MealCategory initialCategory = MealCategory.breakfast,
    FoodItem? initialFood,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMealSheet(
        initialCategory: initialCategory,
        initialFood: initialFood,
      ),
    );
  }

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  late MealCategory _selectedCategory;
  FoodItem? _selectedFood;
  double _servings = 1.0;
  String _searchQuery = '';
  bool _vegetarianOnly = false;
  bool _highProteinOnly = false;
  bool _isBudgetAlternativeUsed = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedFood = widget.initialFood ?? LocalFoodDatabase.foods.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectFood(FoodItem food, {bool fromAlternative = false}) {
    setState(() {
      _selectedFood = food;
      if (fromAlternative) {
        _isBudgetAlternativeUsed = true;
      }
    });
  }

  Future<void> _handleSaveMeal() async {
    if (_selectedFood == null) return;

    final food = _selectedFood!;
    await NutritionService.instance.logFood(
      food: food,
      category: _selectedCategory,
      servings: _servings,
      isBudgetAlternativeUsed: _isBudgetAlternativeUsed,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${food.name} (${_servings}x) to ${_selectedCategory.displayName}',
          ),
          backgroundColor: AppColors.surfaceElevatedDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = LocalFoodDatabase.searchFoods(
      _searchQuery,
      vegetarianOnly: _vegetarianOnly ? true : null,
      highProteinOnly: _highProteinOnly ? true : null,
    );

    final selectedFood = _selectedFood;
    final liveValues = selectedFood?.calculateForServings(_servings);

    final alternative = selectedFood?.alternativeFoodId != null
        ? LocalFoodDatabase.getFoodById(selectedFood!.alternativeFoodId!)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorderDark, width: 1.2),
            ),
          ),
          child: Column(
            children: [
              // Top drag bar & header
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorderDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Log Meal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondaryDark,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorderDark, height: 1),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                  children: [
                    // Step 1: Select Category
                    _buildStepHeader(
                      stepNumber: '1',
                      title: 'Select Meal Category',
                    ),
                    const SizedBox(height: 10),
                    _buildCategorySelector(),
                    const SizedBox(height: 22),

                    // Step 2: Select Food
                    _buildStepHeader(
                      stepNumber: '2',
                      title: 'Select Food Item',
                    ),
                    const SizedBox(height: 10),
                    _buildSearchAndFilters(),
                    const SizedBox(height: 12),
                    _buildFoodList(filteredFoods),
                    const SizedBox(height: 16),

                    // Rule-based Affordable Alternative Highlight
                    if (selectedFood != null && alternative != null)
                      _buildAlternativeSwapCard(selectedFood, alternative),

                    // Step 3: Serving Quantity Selector
                    const SizedBox(height: 14),
                    _buildStepHeader(
                      stepNumber: '3',
                      title: 'Select Serving Quantity',
                    ),
                    const SizedBox(height: 10),
                    _buildServingSelector(selectedFood),
                    const SizedBox(height: 16),

                    // Live Calculated Nutrition Preview
                    if (liveValues != null && selectedFood != null)
                      _buildLiveNutritionCard(selectedFood, liveValues),

                    const SizedBox(height: 24),

                    // Step 4: Add Meal Button
                    FilledButton(
                      onPressed: _handleSaveMeal,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Add to ${_selectedCategory.displayName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepHeader({required String stepNumber, required String title}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MealCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                category.icon,
                size: 16,
                color: isSelected ? Colors.black : category.accentColor,
              ),
              label: Text(category.displayName),
              selected: isSelected,
              selectedColor: category.accentColor,
              backgroundColor: AppColors.surfaceDark,
              side: BorderSide(
                color: isSelected
                    ? category.accentColor
                    : AppColors.cardBorderDark,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.black : AppColors.textPrimaryDark,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search TextField
        TextField(
          controller: _searchController,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search Rice, Dalma, Pakhala, Soya, Chicken...',
            hintStyle: const TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondaryDark,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: AppColors.textMutedDark,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),

        // Quick filter chips
        Row(
          children: [
            FilterChip(
              label: const Text('Veg Only'),
              selected: _vegetarianOnly,
              onSelected: (val) {
                setState(() {
                  _vegetarianOnly = val;
                });
              },
              side: const BorderSide(color: AppColors.cardBorderDark),
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                fontSize: 11,
                color: _vegetarianOnly
                    ? AppColors.primary
                    : AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('High Protein (≥10g)'),
              selected: _highProteinOnly,
              onSelected: (val) {
                setState(() {
                  _highProteinOnly = val;
                });
              },
              side: const BorderSide(color: AppColors.cardBorderDark),
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.accentOrange.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                fontSize: 11,
                color: _highProteinOnly
                    ? AppColors.accentOrange
                    : AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodList(List<FoodItem> foods) {
    if (foods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text(
          'No food found. Try searching for "Rice", "Dalma", "Soya", or "Chana".',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 210),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: foods.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final food = foods[index];
          final isSelected = _selectedFood?.id == food.id;

          return InkWell(
            onTap: () => _onSelectFood(food),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBorderDark.withValues(alpha: 0.6),
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Veg indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: food.isVegetarian
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: food.isVegetarian
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name and tags
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              food.servingSize,
                              style: AppTextStyles.bodySmall,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                food.budgetCategory,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.accentCyan,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Macros
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${food.calories.toInt()} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentOrange,
                        ),
                      ),
                      Text(
                        '${food.protein.toStringAsFixed(1)}g pro',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlternativeSwapCard(
    FoodItem selectedFood,
    FoodItem alternative,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF261D12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.accentOrange,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Affordable Alternative Recommendation',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentOrange,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            selectedFood.alternativeHint ??
                'Swap with ${alternative.name} for lower hostel budget cost and high nutrition.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimaryDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _onSelectFood(alternative, fromAlternative: true),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text('Switch to ${alternative.name.split(' ').first}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentOrange,
                side: const BorderSide(color: AppColors.accentOrange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingSelector(FoodItem? selectedFood) {
    final unit = selectedFood?.servingUnit ?? 'serving';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  Text(
                    '$_servings $unit${_servings > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),

              // Stepper controls
              Row(
                children: [
                  IconButton(
                    onPressed: _servings > 0.5
                        ? () {
                            setState(() {
                              _servings = double.parse(
                                (_servings - 0.5).toStringAsFixed(1),
                              );
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.primary,
                    iconSize: 28,
                  ),
                  IconButton(
                    onPressed: _servings < 5.0
                        ? () {
                            setState(() {
                              _servings = double.parse(
                                (_servings + 0.5).toStringAsFixed(1),
                              );
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.primary,
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick multiplier chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [0.5, 1.0, 1.5, 2.0, 3.0].map((val) {
              final isCurrent = _servings == val;
              return InkWell(
                onTap: () {
                  setState(() {
                    _servings = val;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.cardBorderDark,
                    ),
                  ),
                  child: Text(
                    '${val}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? Colors.black
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNutritionCard(
    FoodItem food,
    FoodNutritionalValues liveValues,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_rounded,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Calculated Nutrition ($_servings serving)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroStat(
                label: 'Calories',
                value: '${liveValues.calories.toInt()}',
                unit: 'kcal',
                color: AppColors.accentOrange,
              ),
              _buildMacroStat(
                label: 'Protein',
                value: liveValues.protein.toStringAsFixed(1),
                unit: 'g',
                color: AppColors.primary,
              ),
              _buildMacroStat(
                label: 'Carbs',
                value: liveValues.carbohydrates.toStringAsFixed(1),
                unit: 'g',
                color: AppColors.accentYellow,
              ),
              _buildMacroStat(
                label: 'Fats',
                value: liveValues.fats.toStringAsFixed(1),
                unit: 'g',
                color: AppColors.accentCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMutedDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
