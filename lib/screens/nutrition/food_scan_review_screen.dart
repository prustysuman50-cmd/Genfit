import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/nutrition_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/local_food_database.dart';
import '../../models/nutrition/food_item.dart';
import '../../models/nutrition/food_preparation_level.dart';
import '../../models/nutrition/food_recognition_result.dart';
import '../../models/nutrition/meal_category.dart';

/// Screen for reviewing an AI-scanned food detection before confirming and logging.
///
/// Allows:
/// - Adjusting serving size multiplier (0.5x, 1x, 1.5x, 2x, 3x)
/// - Adjusting preparation / oil level (Light 0.90x, Standard 1.00x, Rich 1.15x)
/// - Selecting target meal category (Breakfast, Lunch, Dinner, Snacks)
/// - Real-time dynamic preview of calculated calories and macros
/// - Logging via existing [NutritionService] which automatically awards +20 XP
class FoodScanReviewScreen extends StatefulWidget {
  final FoodRecognitionResult scanResult;
  final XFile? imageFile;
  final NutritionService? nutritionService;

  const FoodScanReviewScreen({
    super.key,
    required this.scanResult,
    this.imageFile,
    this.nutritionService,
  });

  @override
  State<FoodScanReviewScreen> createState() => _FoodScanReviewScreenState();
}

class _FoodScanReviewScreenState extends State<FoodScanReviewScreen> {
  late final NutritionService _nutritionService;
  late FoodRecognitionResult _currentResult;

  double _selectedServing = 1.0;
  FoodPreparationLevel _selectedPreparation = FoodPreparationLevel.standard;
  late MealCategory _selectedCategory;

  bool _isLogging = false;
  bool _isLogged = false;

  static const List<double> _servingOptions = [0.5, 1.0, 1.5, 2.0, 3.0];

  @override
  void initState() {
    super.initState();
    _nutritionService = widget.nutritionService ?? NutritionService.instance;
    _currentResult = widget.scanResult;
    _selectedCategory = _defaultCategoryForCurrentTime();
  }

  MealCategory _defaultCategoryForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealCategory.breakfast;
    if (hour < 16) return MealCategory.lunch;
    if (hour < 19) return MealCategory.snacks;
    return MealCategory.dinner;
  }

  Future<void> _handleConfirmAndLog() async {
    final food =
        _currentResult.matchedFoodItem ?? widget.scanResult.matchedFoodItem;
    if (food == null) return;

    setState(() {
      _isLogging = true;
    });

    try {
      await _nutritionService.logFood(
        food: food,
        category: _selectedCategory,
        servings: _selectedServing,
        preparationMultiplier: _selectedPreparation.multiplier,
      );

      if (!mounted) return;

      setState(() {
        _isLogging = false;
        _isLogged = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLogging = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log meal: $e'),
          backgroundColor: AppColors.accentOrange,
        ),
      );
    }
  }

  void _showChangeFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final foods = query.trim().isEmpty
                ? LocalFoodDatabase.foods
                : LocalFoodDatabase.searchFoods(query);
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Dish from 101 Foods',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMutedDark,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      autofocus: true,
                      onChanged: (val) {
                        setSheetState(() {
                          query = val;
                        });
                      },
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search food (e.g. Rice, Dalma, Pakhala...)',
                        hintStyle: const TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceElevatedDark,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorderDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: foods.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: AppColors.cardBorderDark,
                          height: 1,
                        ),
                        itemBuilder: (_, index) {
                          final item = foods[index];
                          final isCurrent = item.id ==
                              (_currentResult.matchedFoodItem?.id ?? '');
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? AppColors.primary
                                    : AppColors.textPrimaryDark,
                              ),
                            ),
                            subtitle: Text(
                              '${item.calories.toInt()} kcal • ${item.servingSize}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            trailing: isCurrent
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _currentResult =
                                    _currentResult.copyWithManualFood(item);
                              });
                              Navigator.of(sheetCtx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final food =
        _currentResult.matchedFoodItem ?? widget.scanResult.matchedFoodItem;

    if (food == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: const Text('Review Meal'),
        ),
        body: const Center(
          child: Text(
            'No matching food item found to review.',
            style: TextStyle(color: AppColors.textPrimaryDark),
          ),
        ),
      );
    }

    // Dynamic nutrition calculated on the fly
    final dynamicNutrition = FoodReviewNutrition.calculate(
      food: food,
      servings: _selectedServing,
      preparation: _selectedPreparation,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isLogged ? 'Meal Confirmed' : 'Review & Customize',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLogged
            ? _buildSuccessView(food, dynamicNutrition)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Food Preview Card
                    _buildFoodPreviewCard(food),
                    const SizedBox(height: 20),

                    // B. Serving Size Selector
                    _buildServingSizeSelector(food),
                    const SizedBox(height: 20),

                    // C. Preparation / Oil Level Selector
                    _buildPreparationSelector(),
                    const SizedBox(height: 20),

                    // D. Nutrition Preview (Dynamically updated)
                    _buildNutritionPreview(dynamicNutrition),
                    const SizedBox(height: 20),

                    // E. Meal Category Selector
                    _buildMealCategorySelector(),
                    const SizedBox(height: 28),

                    // F. Confirm & Log Meal Button
                    FilledButton.icon(
                      onPressed: _isLogging ? null : _handleConfirmAndLog,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      icon: _isLogging
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        _isLogging ? 'Logging Meal...' : 'Confirm & Log Meal',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  /// A. Food Preview: photo, AI detected badge, and food name
  Widget _buildFoodPreviewCard(FoodItem food) {
    final imagePath = widget.imageFile?.path ?? widget.scanResult.imagePath;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFF1E1730),
              child:
                  imagePath != null && !kIsWeb && File(imagePath).existsSync()
                  ? Image.file(File(imagePath), fit: BoxFit.cover)
                  : const Icon(
                      Icons.restaurant_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Details & AI Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (_currentResult.isLiveAi
                                ? AppColors.brightPurple
                                : AppColors.accentOrange)
                            .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          (_currentResult.isLiveAi
                                  ? AppColors.brightPurple
                                  : AppColors.accentOrange)
                              .withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentResult.isLiveAi
                            ? Icons.auto_awesome_rounded
                            : Icons.science_outlined,
                        size: 11,
                        color: _currentResult.isLiveAi
                            ? AppColors.brightPurple
                            : AppColors.accentOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentResult.isLiveAi
                            ? 'GEMINI AI • ${_currentResult.confidencePercentage}'
                            : 'AI DETECTED • ${_currentResult.confidencePercentage}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: _currentResult.isLiveAi
                              ? AppColors.brightPurple
                              : AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Base: ${food.servingSize}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedDark,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showChangeFoodSheet,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Change dish',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_currentResult.detectedItems.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _currentResult.detectedItems.map((item) {
                      final isSelected =
                          item.label == _currentResult.detectedLabel;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _currentResult = _currentResult
                                .copyWithSelectedPrimary(item);
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.surfaceElevatedDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorderDark,
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// B. Serving Size Selector (0.5x, 1x, 1.5x, 2x, 3x)
  Widget _buildServingSizeSelector(FoodItem food) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Serving Size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '${_selectedServing}x (${food.servingUnit})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _servingOptions.map((opt) {
              final isSelected = _selectedServing == opt;
              final label = opt == 1.0
                  ? '1x'
                  : (opt % 1 == 0 ? '${opt.toInt()}x' : '${opt}x');
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedServing = opt;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorderDark,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.black
                              : AppColors.textPrimaryDark,
                        ),
                      ),
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

  /// C. Preparation / Oil Level Selector (Light 0.90x, Standard 1.00x, Rich 1.15x)
  Widget _buildPreparationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preparation / Oil Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '${_selectedPreparation.displayName} (${_selectedPreparation.multiplier.toStringAsFixed(2)}x)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Explanatory line requested by prompt
          const Text(
            'Preparation is estimated — adjust if needed.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMutedDark,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: FoodPreparationLevel.values.map((prep) {
              final isSelected = _selectedPreparation == prep;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPreparation = prep;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentCyan.withValues(alpha: 0.18)
                            : AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentCyan
                              : AppColors.cardBorderDark,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            prep.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.accentCyan
                                  : AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${prep.multiplier}x',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.accentCyan
                                  : AppColors.textMutedDark,
                            ),
                          ),
                        ],
                      ),
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

  /// D. Nutrition Preview (Dynamically updated based on serving & prep multipliers)
  Widget _buildNutritionPreview(FoodReviewNutrition nutrition) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nutrition Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE CALCULATED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroStat(
                  'Calories',
                  '${nutrition.calories.toInt()} kcal',
                  AppColors.accentOrange,
                ),
                _buildMacroStat(
                  'Protein',
                  '${nutrition.protein.toStringAsFixed(1)}g',
                  AppColors.primary,
                ),
                _buildMacroStat(
                  'Carbs',
                  '${nutrition.carbohydrates.toStringAsFixed(1)}g',
                  AppColors.accentCyan,
                ),
                _buildMacroStat(
                  'Fats',
                  '${nutrition.fats.toStringAsFixed(1)}g',
                  const Color(0xFFE2E8F0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// E. Meal Category Selector (Breakfast, Lunch, Dinner, Snacks)
  Widget _buildMealCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MealCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? Colors.black : cat.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(cat.displayName),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevatedDark,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBorderDark,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.black : AppColors.textPrimaryDark,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Success state after confirming and logging
  Widget _buildSuccessView(FoodItem food, FoodReviewNutrition nutrition) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success glow icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),

            // "Meal Logged! +20 XP" heading
            const Text(
              'Meal Logged! +20 XP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryDark,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Added to your ${_selectedCategory.displayName} log. Gamification XP and streak updated automatically.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Food Item',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorderDark, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Portion & Prep',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                      Text(
                        '${_selectedServing}x • ${_selectedPreparation.displayName} (${_selectedPreparation.multiplier}x)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorderDark, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Energy',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                      Text(
                        '${nutrition.calories.toInt()} kcal',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Macros (P / C / F)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                      Text(
                        '${nutrition.protein.toStringAsFixed(1)}g / ${nutrition.carbohydrates.toStringAsFixed(1)}g / ${nutrition.fats.toStringAsFixed(1)}g',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // "Done" Button
            FilledButton(
              onPressed: () {
                // Return to NutritionScreen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMutedDark,
          ),
        ),
      ],
    );
  }
}
