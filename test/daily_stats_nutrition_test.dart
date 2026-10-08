import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/daily_stats.dart';
import 'package:genfit/models/nutrition/meal_category.dart';

void main() {
  late Directory tempStatsDir;
  late Directory tempNutritionDir;
  final statsService = DailyStatsService.instance;
  final nutritionService = NutritionService.instance;

  final riceFood = LocalFoodDatabase.getFoodById('food_rice')!;
  final dalFood = LocalFoodDatabase.getFoodById('food_dal')!;

  setUp(() async {
    tempStatsDir = Directory.systemTemp.createTempSync('stats_test_');
    tempNutritionDir = Directory.systemTemp.createTempSync('nutrition_test_');

    statsService.setCustomStoragePath(tempStatsDir.path);
    nutritionService.setCustomStoragePath(tempNutritionDir.path);

    await statsService.resetToDefaults();
    await nutritionService.resetToDefaults();

    statsService.attachNutritionListener(nutritionService);
  });

  tearDown(() {
    statsService.detachNutritionListener();
    try {
      if (tempStatsDir.existsSync()) {
        tempStatsDir.deleteSync(recursive: true);
      }
      if (tempNutritionDir.existsSync()) {
        tempNutritionDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DailyStats Nutrition Integration Tests', () {
    test('1. Fresh DailyStats has 0 consumed nutrition values', () {
      final today = statsService.todayStats;
      expect(today.caloriesConsumed, 0.0);
      expect(today.proteinGrams, 0.0);
      expect(today.carbsGrams, 0.0);
      expect(today.fatsGrams, 0.0);
      expect(today.mealsLogged, 0);
    });

    test(
      '2. Logging a single meal updates DailyStats today totals accurately',
      () async {
        await nutritionService.logFood(
          food: riceFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );

        // Explicit sync or listener sync
        await statsService.syncNutritionFromService(service: nutritionService);

        final today = statsService.todayStats;
        expect(today.caloriesConsumed, 195.0);
        expect(today.proteinGrams, 4.1);
        expect(today.carbsGrams, 43.5);
        expect(today.fatsGrams, 0.5);
        expect(today.mealsLogged, 1);
      },
    );

    test(
      '3. Logging a second meal aggregates nutrition totals correctly',
      () async {
        await nutritionService.logFood(
          food: riceFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        await nutritionService.logFood(
          food: dalFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );

        await statsService.syncNutritionFromService(service: nutritionService);

        final today = statsService.todayStats;
        // Rice (195.0 kcal, 4.1g P, 43.5g C, 0.5g F) + Dal (160.0 kcal, 9.2g P, 23.0g C, 3.2g F)
        expect(today.caloriesConsumed, 355.0);
        expect(today.proteinGrams, 13.3);
        expect(today.carbsGrams, 66.5);
        expect(today.fatsGrams, 3.7);
        expect(today.mealsLogged, 2);
      },
    );

    test('4. Idempotency / No Double Counting: Repeated sync calls do not accumulate duplicates', () async {
      await nutritionService.logFood(
        food: riceFood,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      // Sync first time
      await statsService.syncNutritionFromService(service: nutritionService);
      expect(statsService.todayStats.caloriesConsumed, 195.0);
      expect(statsService.todayStats.mealsLogged, 1);

      // Sync second time
      await statsService.syncNutritionFromService(service: nutritionService);
      expect(statsService.todayStats.caloriesConsumed, 195.0);
      expect(statsService.todayStats.mealsLogged, 1);

      // Sync third time
      await statsService.syncNutritionFromService(service: nutritionService);
      expect(statsService.todayStats.caloriesConsumed, 195.0);
      expect(statsService.todayStats.mealsLogged, 1);
    });

    test(
      '5. Removing a meal updates DailyStats back to remaining totals',
      () async {
        await nutritionService.logFood(
          food: riceFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        final meal2 = await nutritionService.logFood(
          food: dalFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );

        await statsService.syncNutritionFromService(service: nutritionService);
        expect(statsService.todayStats.mealsLogged, 2);
        expect(statsService.todayStats.caloriesConsumed, 355.0);

        // Remove meal2 (Dal)
        await nutritionService.removeMeal(meal2.id);
        await statsService.syncNutritionFromService(service: nutritionService);

        final today = statsService.todayStats;
        expect(today.mealsLogged, 1);
        expect(today.caloriesConsumed, 195.0);
        expect(today.proteinGrams, 4.1);
        expect(today.carbsGrams, 43.5);
        expect(today.fatsGrams, 0.5);
      },
    );

    test(
      '6. Clearing all meals resets DailyStats nutrition fields to 0',
      () async {
        await nutritionService.logFood(
          food: riceFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        await statsService.syncNutritionFromService(service: nutritionService);
        expect(statsService.todayStats.mealsLogged, 1);

        await nutritionService.clearAllMeals();
        await statsService.syncNutritionFromService(service: nutritionService);

        final today = statsService.todayStats;
        expect(today.mealsLogged, 0);
        expect(today.caloriesConsumed, 0.0);
        expect(today.proteinGrams, 0.0);
        expect(today.carbsGrams, 0.0);
        expect(today.fatsGrams, 0.0);
      },
    );

    test(
      '7. Nutrition data persists across DailyStatsService reload',
      () async {
        await nutritionService.logFood(
          food: riceFood,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        await statsService.syncNutritionFromService(service: nutritionService);
        expect(statsService.todayStats.caloriesConsumed, 195.0);

        // Reinitialize DailyStatsService from disk
        await statsService.init();

        final today = statsService.todayStats;
        expect(today.caloriesConsumed, 195.0);
        expect(today.proteinGrams, 4.1);
        expect(today.carbsGrams, 43.5);
        expect(today.fatsGrams, 0.5);
        expect(today.mealsLogged, 1);
      },
    );

    test('8. Sync preserves existing water and workout stats without overwriting them', () async {
      // Record water and workout first
      await statsService.addWater(500);
      await statsService.recordWorkoutCompleted(
        durationMinutes: 20,
        totalReps: 30,
        caloriesBurned: 150,
      );

      // Now log nutrition and sync
      await nutritionService.logFood(
        food: riceFood,
        category: MealCategory.lunch,
        servings: 1.0,
      );
      await statsService.syncNutritionFromService(service: nutritionService);

      final today = statsService.todayStats;
      // Water and workout intact
      expect(today.waterMl, 500);
      expect(today.workoutsCompleted, 1);
      expect(today.workoutMinutes, 20);
      expect(today.totalReps, 30);
      expect(today.caloriesBurned, 150);

      // Nutrition synced
      expect(today.caloriesConsumed, 195.0);
      expect(today.proteinGrams, 4.1);
      expect(today.mealsLogged, 1);
    });

    test('9. Yesterday meal does not contaminate today DailyStats', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = DailyStats.formatDate(yesterday);
      final todayKey = DailyStats.formatDate(DateTime.now());

      await nutritionService.logFood(
        food: riceFood,
        category: MealCategory.dinner,
        servings: 1.0,
        loggedAt: yesterday,
      );

      // Sync for yesterday
      await statsService.syncNutritionFromService(
        service: nutritionService,
        date: yesterday,
      );

      final today = statsService.todayStats;
      expect(today.date, todayKey);
      expect(today.mealsLogged, 0);
      expect(today.caloriesConsumed, 0.0);

      final yesterdayStats = statsService.getStatsForDate(yesterday);
      expect(yesterdayStats.date, yesterdayKey);
      expect(yesterdayStats.mealsLogged, 1);
      expect(yesterdayStats.caloriesConsumed, 195.0);
    });

    test('10. Automated observer sync: NutritionService logFood automatically updates DailyStats', () async {
      // When attached, calling logFood notifies listeners and triggers sync
      await nutritionService.logFood(
        food: dalFood,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      final today = statsService.todayStats;
      expect(today.caloriesConsumed, 160.0);
      expect(today.proteinGrams, 9.2);
      expect(today.mealsLogged, 1);
    });
  });
}
