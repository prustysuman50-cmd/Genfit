import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/personalized_goal_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/daily_stats.dart';
import 'package:genfit/models/nutrition/meal_category.dart';
import 'package:genfit/models/personalized_goals.dart';
import 'package:genfit/models/user_profile.dart';

void main() {
  late Directory tempStatsDir;
  late Directory tempNutritionDir;
  late Directory tempUserDir;

  final statsService = DailyStatsService.instance;
  final nutritionService = NutritionService.instance;
  final userService = UserService.instance;
  final goalService = PersonalizedGoalService.instance;

  const muscleProfile = UserProfile(
    isCompleted: true,
    age: 21,
    heightCm: 175.0,
    weightKg: 70.0,
    fitnessGoal: 'Build Muscle',
    fitnessLevel: 'Advanced',
    dietPreference: 'Non-Vegetarian',
  );

  const fatLossProfile = UserProfile(
    isCompleted: true,
    age: 22,
    heightCm: 168.0,
    weightKg: 80.0,
    fitnessGoal: 'Lose Fat',
    fitnessLevel: 'Beginner',
    dietPreference: 'Vegetarian',
  );

  setUp(() async {
    tempStatsDir = Directory.systemTemp.createTempSync('stats_goals_test_');
    tempNutritionDir = Directory.systemTemp.createTempSync('nutr_goals_test_');
    tempUserDir = Directory.systemTemp.createTempSync('user_goals_test_');

    statsService.setCustomStoragePath(tempStatsDir.path);
    nutritionService.setCustomStoragePath(tempNutritionDir.path);
    userService.setCustomStoragePath(tempUserDir.path);

    await userService.resetToDefaults();
    await statsService.resetToDefaults();
    await nutritionService.resetToDefaults();

    statsService.attachNutritionListener(nutritionService);
    statsService.attachGoalListener(goalService);
  });

  tearDown(() {
    statsService.detachNutritionListener();
    statsService.detachGoalListener();
    try {
      if (tempStatsDir.existsSync()) tempStatsDir.deleteSync(recursive: true);
      if (tempNutritionDir.existsSync()) {
        tempNutritionDir.deleteSync(recursive: true);
      }
      if (tempUserDir.existsSync()) tempUserDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('GenFit Phase 1 Step 8B: DailyStats & PersonalizedGoals Integration Tests', () {
    test('1. New DailyStats uses PersonalizedGoalService goals', () async {
      await userService.updateProfile(muscleProfile);

      final expected = goalService.currentGoals;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStats = statsService.getStatsForDate(tomorrow);

      expect(tomorrowStats.stepsGoal, equals(expected.stepsGoal));
      expect(tomorrowStats.waterGoalMl, equals(expected.waterGoalMl));
      expect(
        tomorrowStats.caloriesBurnedGoal,
        equals(expected.caloriesBurnedGoal),
      );
      expect(
        tomorrowStats.activeMinutesGoal,
        equals(expected.activeMinutesGoal),
      );
      expect(
        tomorrowStats.caloriesConsumedGoal,
        equals(expected.caloriesConsumedGoal),
      );
      expect(tomorrowStats.proteinGoalGrams, equals(expected.proteinGoalGrams));
      // Actual telemetry must be 0
      expect(tomorrowStats.steps, equals(0));
      expect(tomorrowStats.waterMl, equals(0));
      expect(tomorrowStats.activeMinutes, equals(0));
      expect(tomorrowStats.caloriesBurned, equals(0));
      expect(tomorrowStats.caloriesConsumed, equals(0.0));
    });

    test(
      '2. Default/unavailable profile produces the existing default goals',
      () {
        // UserService starts with defaultUser (isCompleted = false)
        expect(goalService.hasUsableProfile, isFalse);

        final today = statsService.todayStats;
        expect(
          today.stepsGoal,
          equals(PersonalizedGoals.defaultGoals.stepsGoal),
        );
        expect(
          today.waterGoalMl,
          equals(PersonalizedGoals.defaultGoals.waterGoalMl),
        );
        expect(
          today.caloriesBurnedGoal,
          equals(PersonalizedGoals.defaultGoals.caloriesBurnedGoal),
        );
        expect(
          today.activeMinutesGoal,
          equals(PersonalizedGoals.defaultGoals.activeMinutesGoal),
        );
        expect(
          today.caloriesConsumedGoal,
          equals(PersonalizedGoals.defaultGoals.caloriesConsumedGoal),
        );
        expect(
          today.proteinGoalGrams,
          equals(PersonalizedGoals.defaultGoals.proteinGoalGrams),
        );
      },
    );

    test(
      '3. A personalized profile produces personalized DailyStats goal values',
      () async {
        await userService.updateProfile(muscleProfile);

        final today = statsService.todayStats;
        final expected = goalService.calculateGoals(muscleProfile);

        expect(today.stepsGoal, equals(expected.stepsGoal));
        expect(today.waterGoalMl, equals(expected.waterGoalMl));
        expect(today.caloriesBurnedGoal, equals(expected.caloriesBurnedGoal));
        expect(today.activeMinutesGoal, equals(expected.activeMinutesGoal));
        expect(
          today.caloriesConsumedGoal,
          equals(expected.caloriesConsumedGoal),
        );
        expect(today.proteinGoalGrams, equals(expected.proteinGoalGrams));
      },
    );

    test('4. Changing the profile updates goal values appropriately', () async {
      await userService.updateProfile(muscleProfile);
      final muscleGoals = goalService.calculateGoals(muscleProfile);
      expect(statsService.todayStats.stepsGoal, equals(muscleGoals.stepsGoal));

      await userService.updateProfile(fatLossProfile);
      final fatLossGoals = goalService.calculateGoals(fatLossProfile);

      final today = statsService.todayStats;
      expect(today.stepsGoal, equals(fatLossGoals.stepsGoal));
      expect(today.waterGoalMl, equals(fatLossGoals.waterGoalMl));
      expect(today.caloriesBurnedGoal, equals(fatLossGoals.caloriesBurnedGoal));
      expect(today.activeMinutesGoal, equals(fatLossGoals.activeMinutesGoal));
      expect(
        today.caloriesConsumedGoal,
        equals(fatLossGoals.caloriesConsumedGoal),
      );
      expect(today.proteinGoalGrams, equals(fatLossGoals.proteinGoalGrams));
    });

    test(
      '5. Changing the profile does NOT modify today\'s actual steps',
      () async {
        await statsService.updateActivity(
          steps: 4250,
          activeMinutes: 35,
          caloriesBurned: 220,
        );
        expect(statsService.todayStats.steps, equals(4250));

        await userService.updateProfile(muscleProfile);

        final today = statsService.todayStats;
        expect(today.steps, equals(4250));
        expect(today.activeMinutes, equals(35));
        expect(today.caloriesBurned, equals(220));
        expect(today.stepsGoal, equals(goalService.currentGoals.stepsGoal));
      },
    );

    test(
      '6. Changing the profile does NOT modify today\'s actual water',
      () async {
        await statsService.addWater(1250);
        expect(statsService.todayStats.waterMl, equals(1250));

        await userService.updateProfile(fatLossProfile);

        final today = statsService.todayStats;
        expect(today.waterMl, equals(1250));
        expect(today.waterGoalMl, equals(goalService.currentGoals.waterGoalMl));
      },
    );

    test(
      '7. Changing the profile does NOT modify today\'s workout/reps',
      () async {
        await statsService.recordWorkoutCompleted(
          durationMinutes: 30,
          totalReps: 55,
          caloriesBurned: 180,
        );

        final before = statsService.todayStats;
        expect(before.workoutsCompleted, equals(1));
        expect(before.workoutMinutes, equals(30));
        expect(before.totalReps, equals(55));
        expect(before.caloriesBurned, equals(180));

        await userService.updateProfile(muscleProfile);

        final after = statsService.todayStats;
        expect(after.workoutsCompleted, equals(1));
        expect(after.workoutMinutes, equals(30));
        expect(after.totalReps, equals(55));
        expect(after.caloriesBurned, equals(180));
      },
    );

    test(
      '8. Changing the profile does NOT modify nutrition actual totals',
      () async {
        final rice = LocalFoodDatabase.getFoodById('food_rice')!;
        await nutritionService.logFood(
          food: rice,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        await statsService.syncNutritionFromService(service: nutritionService);

        final before = statsService.todayStats;
        expect(before.caloriesConsumed, equals(195.0));
        expect(before.proteinGrams, equals(4.1));
        expect(before.carbsGrams, equals(43.5));
        expect(before.fatsGrams, equals(0.5));
        expect(before.mealsLogged, equals(1));

        await userService.updateProfile(muscleProfile);

        final after = statsService.todayStats;
        expect(after.caloriesConsumed, equals(195.0));
        expect(after.proteinGrams, equals(4.1));
        expect(after.carbsGrams, equals(43.5));
        expect(after.fatsGrams, equals(0.5));
        expect(after.mealsLogged, equals(1));
        // Goals must be updated
        expect(
          after.caloriesConsumedGoal,
          equals(goalService.currentGoals.caloriesConsumedGoal),
        );
        expect(
          after.proteinGoalGrams,
          equals(goalService.currentGoals.proteinGoalGrams),
        );
      },
    );

    test('9. Historical DailyStats actual values remain unchanged', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = DailyStats.formatDate(yesterday);

      // Record activity, water and workout for yesterday
      await statsService.addWater(800, date: yesterday);
      await statsService.updateActivity(
        steps: 6000,
        activeMinutes: 40,
        caloriesBurned: 350,
        date: yesterday,
      );
      await statsService.recordWorkoutCompleted(
        durationMinutes: 20,
        totalReps: 40,
        date: yesterday,
      );

      final yesterdayRecord = statsService.getStatsForDate(yesterday);
      final historicalStepsGoal = yesterdayRecord.stepsGoal;
      final historicalWaterGoal = yesterdayRecord.waterGoalMl;

      // Update profile today
      await userService.updateProfile(muscleProfile);

      // Verify today has new goals
      expect(
        statsService.todayStats.stepsGoal,
        equals(goalService.currentGoals.stepsGoal),
      );

      // Verify yesterday remains completely untouched and frozen
      final reloadedYesterday = statsService.getStatsForDate(yesterday);
      expect(reloadedYesterday.date, equals(yesterdayKey));
      expect(reloadedYesterday.steps, equals(6000));
      expect(reloadedYesterday.waterMl, equals(800));
      expect(reloadedYesterday.activeMinutes, equals(40));
      expect(reloadedYesterday.caloriesBurned, equals(350));
      expect(reloadedYesterday.workoutsCompleted, equals(1));
      expect(reloadedYesterday.workoutMinutes, equals(20));
      expect(reloadedYesterday.totalReps, equals(40));
      expect(reloadedYesterday.stepsGoal, equals(historicalStepsGoal));
      expect(reloadedYesterday.waterGoalMl, equals(historicalWaterGoal));
    });

    test('10. Repeated profile/goal updates do not duplicate listeners or corrupt values', () async {
      // Attach listener multiple times
      statsService.attachGoalListener(goalService);
      statsService.attachGoalListener(goalService);
      statsService.attachGoalListener(goalService);

      int notifyCount = 0;
      void listener() => notifyCount++;
      statsService.addListener(listener);

      // Multiple profile updates
      await userService.updateProfile(muscleProfile);
      await userService.updateProfile(fatLossProfile);
      await userService.updateProfile(muscleProfile);

      statsService.removeListener(listener);

      // Final goals match latest profile
      final expected = goalService.calculateGoals(muscleProfile);
      expect(statsService.todayStats.stepsGoal, equals(expected.stepsGoal));
      expect(statsService.todayStats.waterGoalMl, equals(expected.waterGoalMl));
      expect(notifyCount, greaterThan(0));
    });

    test('11. Existing DailyStats persistence still works', () async {
      await userService.updateProfile(muscleProfile);
      await statsService.addWater(1500);
      await statsService.updateActivity(
        steps: 7200,
        activeMinutes: 45,
        caloriesBurned: 480,
      );

      // Reload service from disk
      await statsService.init();

      final today = statsService.todayStats;
      expect(today.waterMl, equals(1500));
      expect(today.steps, equals(7200));
      expect(today.activeMinutes, equals(45));
      expect(today.caloriesBurned, equals(480));
      expect(today.stepsGoal, equals(goalService.currentGoals.stepsGoal));
      expect(today.waterGoalMl, equals(goalService.currentGoals.waterGoalMl));
    });

    test('12. Existing date isolation still works', () async {
      final pastDate = DateTime(2026, 3, 15);
      final pastKey = DailyStats.formatDate(pastDate);
      final todayKey = DailyStats.formatDate(DateTime.now());

      await statsService.updateActivity(steps: 9000, date: pastDate);
      await statsService.updateActivity(steps: 2000);

      final pastStats = statsService.getStatsForDate(pastDate);
      final todayStats = statsService.todayStats;

      expect(pastStats.date, equals(pastKey));
      expect(pastStats.steps, equals(9000));
      expect(todayStats.date, equals(todayKey));
      expect(todayStats.steps, equals(2000));

      await userService.updateProfile(muscleProfile);

      // Today updated, pastDate isolated
      expect(statsService.todayStats.steps, equals(2000));
      expect(statsService.getStatsForDate(pastDate).steps, equals(9000));
    });
  });
}
