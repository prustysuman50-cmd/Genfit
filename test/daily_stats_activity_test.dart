import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/daily_stats.dart';
import 'package:genfit/models/nutrition/meal_category.dart';

void main() {
  late Directory tempDir;
  late Directory tempNutritionDir;
  final service = DailyStatsService.instance;
  final nutrition = NutritionService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('activity_stats_test_');
    tempNutritionDir = Directory.systemTemp.createTempSync(
      'activity_nutr_test_',
    );

    service.setCustomStoragePath(tempDir.path);
    nutrition.setCustomStoragePath(tempNutritionDir.path);

    await service.resetToDefaults();
    await nutrition.resetToDefaults();
  });

  tearDown(() {
    service.detachNutritionListener();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (tempNutritionDir.existsSync()) {
        tempNutritionDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DailyStats Activity & Steps Integration Tests', () {
    test('1. Fresh activity stats start at zero', () {
      final today = service.todayStats;
      expect(today.steps, 0);
      expect(today.activeMinutes, 0);
      expect(today.caloriesBurned, 0);
      expect(today.stepsGoal, 10000);
      expect(today.activeMinutesGoal, 45);
      expect(today.caloriesBurnedGoal, 650);
      expect(today.stepsProgress, 0.0);
      expect(today.activeMinutesProgress, 0.0);
      expect(today.caloriesBurnedProgress, 0.0);
    });

    test('2. Updating steps correctly updates DailyStats', () async {
      await service.updateActivity(steps: 3200);

      final today = service.todayStats;
      expect(today.steps, 3200);
      expect(today.stepsProgress, closeTo(3200 / 10000, 0.001));
    });

    test('3. Updating active minutes correctly updates DailyStats', () async {
      await service.updateActivity(activeMinutes: 25);

      final today = service.todayStats;
      expect(today.activeMinutes, 25);
      expect(today.activeMinutesProgress, closeTo(25 / 45, 0.001));
    });

    test('4. Updating calories burned correctly updates DailyStats', () async {
      await service.updateActivity(caloriesBurned: 350);

      final today = service.todayStats;
      expect(today.caloriesBurned, 350);
      expect(today.caloriesBurnedProgress, closeTo(350 / 650, 0.001));
    });

    test(
      '5. Multiple updates accumulate and set correctly according to methods',
      () async {
        // Absolute update
        await service.updateActivity(
          steps: 4000,
          activeMinutes: 30,
          caloriesBurned: 220,
        );

        expect(service.todayStats.steps, 4000);
        expect(service.todayStats.activeMinutes, 30);
        expect(service.todayStats.caloriesBurned, 220);

        // Incremental add steps
        await service.addSteps(250, caloriesBurned: 12);
        expect(service.todayStats.steps, 4250);
        expect(service.todayStats.caloriesBurned, 232);

        // Incremental add active minutes
        await service.addActiveMinutes(10, caloriesBurned: 25);
        expect(service.todayStats.activeMinutes, 40);
        expect(service.todayStats.caloriesBurned, 257);

        // Incremental add calories burned
        await service.addCaloriesBurned(43);
        expect(service.todayStats.caloriesBurned, 300);
      },
    );

    test(
      '6. Persistence after reload/re-init restores activity values',
      () async {
        await service.updateActivity(
          steps: 6500,
          activeMinutes: 42,
          caloriesBurned: 410,
        );

        // Re-initialize service reading from disk
        await service.init();

        final today = service.todayStats;
        expect(today.steps, 6500);
        expect(today.activeMinutes, 42);
        expect(today.caloriesBurned, 410);
      },
    );

    test(
      '7. Date isolation: yesterday activity does not bleed into today',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayKey = DailyStats.formatDate(yesterday);
        final todayKey = DailyStats.formatDate(DateTime.now());

        await service.updateActivity(
          steps: 8000,
          activeMinutes: 50,
          caloriesBurned: 520,
          date: yesterday,
        );

        final today = service.todayStats;
        expect(today.date, todayKey);
        expect(today.steps, 0);
        expect(today.activeMinutes, 0);
        expect(today.caloriesBurned, 0);

        final yesterdayStats = service.getStatsForDate(yesterday);
        expect(yesterdayStats.date, yesterdayKey);
        expect(yesterdayStats.steps, 8000);
        expect(yesterdayStats.activeMinutes, 50);
        expect(yesterdayStats.caloriesBurned, 520);
      },
    );

    test(
      '8. Water, nutrition, and workout telemetry remain completely unaffected',
      () async {
        // Record water
        await service.addWater(750);

        // Record workout
        await service.recordWorkoutCompleted(
          durationMinutes: 20,
          totalReps: 35,
          caloriesBurned: 140,
        );

        // Log nutrition and sync
        final rice = LocalFoodDatabase.getFoodById('food_rice')!;
        await nutrition.logFood(
          food: rice,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        await service.syncNutritionFromService(service: nutrition);

        // Now update activity (steps and active minutes)
        await service.updateActivity(steps: 5000, activeMinutes: 30);

        final today = service.todayStats;
        // Activity updated
        expect(today.steps, 5000);
        expect(today.activeMinutes, 30);

        // Water unaffected
        expect(today.waterMl, 750);

        // Workout telemetry unaffected (workout caloriesBurned preserved and accumulated)
        expect(today.workoutsCompleted, 1);
        expect(today.workoutMinutes, 20);
        expect(today.totalReps, 35);
        expect(today.caloriesBurned, 140);

        // Nutrition unaffected
        expect(today.caloriesConsumed, 195.0);
        expect(today.proteinGrams, 4.1);
        expect(today.mealsLogged, 1);
      },
    );

    test('9. Idempotent: repeated updates of same value do NOT cause accidental accumulation', () async {
      await service.updateActivity(
        steps: 4500,
        activeMinutes: 35,
        caloriesBurned: 300,
      );

      expect(service.todayStats.steps, 4500);
      expect(service.todayStats.activeMinutes, 35);
      expect(service.todayStats.caloriesBurned, 300);

      // Second update reporting same sensor values
      await service.updateActivity(
        steps: 4500,
        activeMinutes: 35,
        caloriesBurned: 300,
      );

      expect(service.todayStats.steps, 4500);
      expect(service.todayStats.activeMinutes, 35);
      expect(service.todayStats.caloriesBurned, 300);

      // Third update
      await service.setActivityMetrics(
        steps: 4500,
        activeMinutes: 35,
        caloriesBurned: 300,
      );

      expect(service.todayStats.steps, 4500);
      expect(service.todayStats.activeMinutes, 35);
      expect(service.todayStats.caloriesBurned, 300);
    });

    test('10. Notifies listeners on activity changes', () async {
      int notifyCount = 0;
      service.addListener(() {
        notifyCount++;
      });

      await service.updateActivity(steps: 1200);
      expect(notifyCount, 1);

      await service.addSteps(250);
      expect(notifyCount, 2);

      await service.addActiveMinutes(10);
      expect(notifyCount, 3);

      await service.addCaloriesBurned(20);
      expect(notifyCount, 4);
    });
  });
}
