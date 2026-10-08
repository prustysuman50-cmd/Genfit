import 'package:flutter/material.dart';

import '../../core/services/daily_stats_service.dart';
import '../../core/services/nutrition_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/nutrition/food_item.dart';
import '../../models/nutrition/logged_meal.dart';
import '../../models/nutrition/meal_category.dart';
import 'food_scan_screen.dart';
import 'widgets/add_meal_sheet.dart';
import 'widgets/affordable_alternatives_card.dart';
import 'widgets/meal_category_section.dart';
import 'widgets/nutrition_dashboard_header.dart';
import 'widgets/todays_hostel_menu_card.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionService _nutritionService = NutritionService.instance;

  @override
  void initState() {
    super.initState();
    if (!_nutritionService.isInitialized) {
      _nutritionService.init();
    }
  }

  void _openAddMealSheet({
    MealCategory category = MealCategory.breakfast,
    FoodItem? preselectedFood,
  }) {
    AddMealSheet.show(
      context,
      initialCategory: category,
      initialFood: preselectedFood,
    );
  }

  void _handleDeleteMeal(LoggedMeal meal) async {
    await _nutritionService.removeMeal(meal.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${meal.name}'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primary,
            onPressed: () {
              _nutritionService.logMeal(meal);
            },
          ),
          backgroundColor: AppColors.surfaceElevatedDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleResetMeals() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Reset Today\'s Meals?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: const Text(
          'This will clear all logged meals for today.',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _nutritionService.clearAllMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Nutrition & Mess Fuel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _openAddMealSheet(category: MealCategory.lunch),
            tooltip: 'Add Meal',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.cardDark,
            onSelected: (value) {
              if (value == 'reset') {
                _handleResetMeals();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.accentRed,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Clear Today\'s Meals',
                      style: TextStyle(color: AppColors.textPrimaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _nutritionService,
          DailyStatsService.instance,
        ]),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. NUTRITION DASHBOARD HEADER (Calories, Protein targets, consumed & progress)
                NutritionDashboardHeader(
                  nutrition: _nutritionService,
                  dailyStatsService: DailyStatsService.instance,
                ),
                const SizedBox(height: 18),

                // Quick Log Action Banner
                _buildQuickLogBanner(),
                const SizedBox(height: 16),

                // AI Food Scan Feature Card (Coming Soon)
                _buildAiFoodScanCard(),
                const SizedBox(height: 18),

                // Today's Hostel/Mess Menu
                const TodaysHostelMenuCard(),
                const SizedBox(height: 10),

                // 2. MEAL CATEGORIES (Breakfast, Lunch, Dinner, Snacks)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Meals',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_nutritionService.todayMeals.length} logged',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Breakfast
                MealCategorySection(
                  category: MealCategory.breakfast,
                  meals: _nutritionService.mealsForCategory(
                    MealCategory.breakfast,
                  ),
                  onAddMeal: () =>
                      _openAddMealSheet(category: MealCategory.breakfast),
                  onDeleteMeal: _handleDeleteMeal,
                ),

                // Lunch
                MealCategorySection(
                  category: MealCategory.lunch,
                  meals: _nutritionService.mealsForCategory(MealCategory.lunch),
                  onAddMeal: () =>
                      _openAddMealSheet(category: MealCategory.lunch),
                  onDeleteMeal: _handleDeleteMeal,
                ),

                // Dinner
                MealCategorySection(
                  category: MealCategory.dinner,
                  meals: _nutritionService.mealsForCategory(
                    MealCategory.dinner,
                  ),
                  onAddMeal: () =>
                      _openAddMealSheet(category: MealCategory.dinner),
                  onDeleteMeal: _handleDeleteMeal,
                ),

                // Snacks
                MealCategorySection(
                  category: MealCategory.snacks,
                  meals: _nutritionService.mealsForCategory(
                    MealCategory.snacks,
                  ),
                  onAddMeal: () =>
                      _openAddMealSheet(category: MealCategory.snacks),
                  onDeleteMeal: _handleDeleteMeal,
                ),

                const SizedBox(height: 10),

                // 3. AFFORDABLE ALTERNATIVES (Rule-based budget protein swaps)
                AffordableAlternativesCard(
                  onSelectAlternative: (food, category) {
                    _openAddMealSheet(
                      category: category,
                      preselectedFood: food,
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddMealSheet(category: MealCategory.lunch),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Meal',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildQuickLogBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
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
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Mess & Street Food',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Rice, Dalma, Pakhala, Soya, Chana & more',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => _openAddMealSheet(category: MealCategory.lunch),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '+ Log',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFoodScanCard() {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const FoodScanScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1730), Color(0xFF14141D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.brightPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleGlow.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_enhance_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI Food Scan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.brightPurple.withValues(
                              alpha: 0.4,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'SCAN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.softPurple,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan your meal with camera to identify calories & macros',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FoodScanScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.softPurple,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
