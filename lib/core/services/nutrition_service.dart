import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/nutrition/food_item.dart';
import '../../models/nutrition/logged_meal.dart';
import '../../models/nutrition/meal_category.dart';
import 'daily_stats_service.dart';

class NutritionService extends ChangeNotifier {
  NutritionService._();

  static final NutritionService instance = NutritionService._();

  static const String _fileName = 'genfit_nutrition.json';
  static const double defaultCalorieTarget = 2100.0;
  static const double defaultProteinTarget = 110.0;

  double? _customCalorieTarget;
  double? _customProteinTarget;
  DailyStatsService? _customDailyStatsService;
  final List<LoggedMeal> _meals = [];
  bool _isInitialized = false;

  String? _customStoragePath;

  bool get isInitialized => _isInitialized;

  /// Sets a custom [DailyStatsService] instance (useful for unit testing isolation).
  void setDailyStatsService(DailyStatsService? service) {
    _customDailyStatsService = service;
  }

  DailyStatsService get _effectiveDailyStatsService =>
      _customDailyStatsService ?? DailyStatsService.instance;

  /// Returns the user's daily calorie target.
  /// Uses an explicit custom override if set; otherwise delegates to the
  /// personalized target managed by [DailyStatsService].
  double get calorieTarget {
    if (_customCalorieTarget != null) return _customCalorieTarget!;
    return _effectiveDailyStatsService.todayStats.caloriesConsumedGoal;
  }

  /// Returns the user's daily protein target in grams.
  /// Uses an explicit custom override if set; otherwise delegates to the
  /// personalized target managed by [DailyStatsService].
  double get proteinTarget {
    if (_customProteinTarget != null) return _customProteinTarget!;
    return _effectiveDailyStatsService.todayStats.proteinGoalGrams;
  }

  List<LoggedMeal> get allMeals => List.unmodifiable(_meals);

  List<LoggedMeal> get todayMeals {
    final now = DateTime.now();
    return _meals.where((meal) => _isSameDay(meal.loggedAt, now)).toList();
  }

  double get todayCalories {
    final total = todayMeals.fold<double>(0.0, (sum, m) => sum + m.calories);
    return double.parse(total.toStringAsFixed(1));
  }

  double get todayProtein {
    final total = todayMeals.fold<double>(0.0, (sum, m) => sum + m.protein);
    return double.parse(total.toStringAsFixed(1));
  }

  double get todayCarbs {
    final total = todayMeals.fold<double>(
      0.0,
      (sum, m) => sum + m.carbohydrates,
    );
    return double.parse(total.toStringAsFixed(1));
  }

  double get todayFats {
    final total = todayMeals.fold<double>(0.0, (sum, m) => sum + m.fats);
    return double.parse(total.toStringAsFixed(1));
  }

  double get calorieProgress {
    if (calorieTarget <= 0) return 0.0;
    return (todayCalories / calorieTarget).clamp(0.0, 1.0);
  }

  double get proteinProgress {
    if (proteinTarget <= 0) return 0.0;
    return (todayProtein / proteinTarget).clamp(0.0, 1.0);
  }

  double get remainingCalories {
    final remaining = calorieTarget - todayCalories;
    return remaining > 0 ? double.parse(remaining.toStringAsFixed(1)) : 0.0;
  }

  double get remainingProtein {
    final remaining = proteinTarget - todayProtein;
    return remaining > 0 ? double.parse(remaining.toStringAsFixed(1)) : 0.0;
  }

  List<LoggedMeal> mealsForCategory(MealCategory category) {
    return todayMeals.where((meal) => meal.category == category).toList();
  }

  double caloriesForCategory(MealCategory category) {
    final meals = mealsForCategory(category);
    final total = meals.fold<double>(0.0, (sum, m) => sum + m.calories);
    return double.parse(total.toStringAsFixed(1));
  }

  double proteinForCategory(MealCategory category) {
    final meals = mealsForCategory(category);
    final total = meals.fold<double>(0.0, (sum, m) => sum + m.protein);
    return double.parse(total.toStringAsFixed(1));
  }

  /// Sets a custom storage directory path (useful for testing or isolation)
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data['customCalorieTarget'] != null) {
            _customCalorieTarget = (data['customCalorieTarget'] as num)
                .toDouble();
          } else if (data['calorieTarget'] != null) {
            final val = (data['calorieTarget'] as num).toDouble();
            if (val != defaultCalorieTarget) {
              _customCalorieTarget = val;
            }
          }
          if (data['customProteinTarget'] != null) {
            _customProteinTarget = (data['customProteinTarget'] as num)
                .toDouble();
          } else if (data['proteinTarget'] != null) {
            final val = (data['proteinTarget'] as num).toDouble();
            if (val != defaultProteinTarget) {
              _customProteinTarget = val;
            }
          }
          if (data['meals'] is List) {
            _meals.clear();
            for (final item in data['meals']) {
              if (item is Map<String, dynamic>) {
                _meals.add(LoggedMeal.fromJson(item));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('NutritionService init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Logs a meal, persists immediately, and notifies listeners
  Future<LoggedMeal> logFood({
    required FoodItem food,
    required MealCategory category,
    required double servings,
    DateTime? loggedAt,
    bool isBudgetAlternativeUsed = false,
    double preparationMultiplier = 1.0,
  }) async {
    final meal = LoggedMeal.fromFoodItem(
      food: food,
      category: category,
      servings: servings,
      loggedAt: loggedAt,
      isBudgetAlternativeUsed: isBudgetAlternativeUsed,
      preparationMultiplier: preparationMultiplier,
    );
    await logMeal(meal);
    return meal;
  }

  Future<void> logMeal(LoggedMeal meal) async {
    _meals.add(meal);
    await _persist();
    notifyListeners();
  }

  Future<void> removeMeal(String mealId) async {
    _meals.removeWhere((meal) => meal.id == mealId);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAllMeals() async {
    _meals.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> setTargets({
    double? calorieTarget,
    double? proteinTarget,
  }) async {
    if (calorieTarget != null && calorieTarget > 0) {
      _customCalorieTarget = calorieTarget;
    }
    if (proteinTarget != null && proteinTarget > 0) {
      _customProteinTarget = proteinTarget;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _customCalorieTarget = null;
    _customProteinTarget = null;
    _customDailyStatsService = null;
    _meals.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final Map<String, dynamic> data = {
          if (_customCalorieTarget != null)
            'customCalorieTarget': _customCalorieTarget,
          if (_customProteinTarget != null)
            'customProteinTarget': _customProteinTarget,
          'calorieTarget': calorieTarget,
          'proteinTarget': proteinTarget,
          'meals': _meals.map((m) => m.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('NutritionService persist error: $e');
    }
  }

  Future<File?> _getExistingFileOrTarget() async {
    try {
      if (_customStoragePath != null) {
        final dir = Directory(_customStoragePath!);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/$_fileName');
      }

      final candidates = _getCandidateDirectories();

      // Check if file already exists in any candidate
      for (final dirPath in candidates) {
        final file = File('$dirPath/$_fileName');
        if (file.existsSync()) {
          return file;
        }
      }

      // Return first writable candidate
      for (final dirPath in candidates) {
        try {
          final dir = Directory(dirPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final testFile = File('$dirPath/$_fileName');
          return testFile;
        } catch (_) {
          continue;
        }
      }

      return File('${Directory.systemTemp.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  List<String> _getCandidateDirectories() {
    final list = <String>[];

    if (Platform.isAndroid) {
      final pkg = _getAndroidPackageName() ?? 'com.example.genfit';
      list.addAll([
        '/data/user/0/$pkg/files',
        '/data/data/$pkg/files',
        '/data/user/0/$pkg/app_flutter',
        '/data/data/$pkg/app_flutter',
        '/data/user/0/com.example.genfit/files',
        '/data/data/com.example.genfit/files',
        '/data/user/0/$pkg/cache',
        '/data/data/$pkg/cache',
      ]);
    }

    list.add(Directory.systemTemp.path);
    return list;
  }

  String? _getAndroidPackageName() {
    try {
      final cmd = File('/proc/self/cmdline').readAsStringSync();
      final pkg = cmd.split('\u0000').first.trim();
      if (pkg.isNotEmpty && pkg.contains('.')) return pkg;
    } catch (_) {}
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
