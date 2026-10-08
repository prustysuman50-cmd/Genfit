import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/personalized_goal_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/meal_category.dart';
import 'package:genfit/models/user_profile.dart';
import 'package:genfit/screens/home/widgets/hostel_fuel_preview.dart';
import 'package:genfit/screens/nutrition/widgets/nutrition_dashboard_header.dart';

void main() {
  late Directory tempStatsDir;
  late Directory tempNutritionDir;
  late Directory tempUserDir;

  final statsService = DailyStatsService.instance;
  final nutritionService = NutritionService.instance;
  final userService = UserService.instance;
  final goalService = PersonalizedGoalService.instance;
  final gamificationService = GamificationService.instance;

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
    tempStatsDir = Directory.systemTemp.createTempSync('nutr_targets_stats_');
    tempNutritionDir = Directory.systemTemp.createTempSync(
      'nutr_targets_nutr_',
    );
    tempUserDir = Directory.systemTemp.createTempSync('nutr_targets_user_');

    statsService.setCustomStoragePath(tempStatsDir.path);
    nutritionService.setCustomStoragePath(tempNutritionDir.path);
    userService.setCustomStoragePath(tempUserDir.path);

    await userService.resetToDefaults();
    await statsService.resetToDefaults();
    await nutritionService.resetToDefaults();

    statsService.attachNutritionListener(nutritionService);
    statsService.attachGoalListener(goalService);
    nutritionService.setDailyStatsService(statsService);
  });

  tearDown(() {
    statsService.detachNutritionListener();
    statsService.detachGoalListener();
    nutritionService.setDailyStatsService(null);
    try {
      if (tempStatsDir.existsSync()) tempStatsDir.deleteSync(recursive: true);
      if (tempNutritionDir.existsSync()) {
        tempNutritionDir.deleteSync(recursive: true);
      }
      if (tempUserDir.existsSync()) tempUserDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Phase 1 Step 8C: Personalized Nutrition Targets Tests', () {
    test(
      '1. Personalized calorie target is used by nutrition target consumers',
      () async {
        await userService.updateProfile(muscleProfile);

        final expectedGoals = goalService.currentGoals;
        expect(
          statsService.todayStats.caloriesConsumedGoal,
          equals(expectedGoals.caloriesConsumedGoal),
        );
        expect(
          nutritionService.calorieTarget,
          equals(expectedGoals.caloriesConsumedGoal),
        );
      },
    );

    test(
      '2. Personalized protein target is used by nutrition target consumers',
      () async {
        await userService.updateProfile(muscleProfile);

        final expectedGoals = goalService.currentGoals;
        expect(
          statsService.todayStats.proteinGoalGrams,
          equals(expectedGoals.proteinGoalGrams),
        );
        expect(
          nutritionService.proteinTarget,
          equals(expectedGoals.proteinGoalGrams),
        );
      },
    );

    test('3. Default/unavailable profile still produces existing default nutrition targets', () {
      // Default user (isCompleted = false)
      expect(goalService.hasUsableProfile, isFalse);

      expect(statsService.todayStats.caloriesConsumedGoal, equals(2100.0));
      expect(statsService.todayStats.proteinGoalGrams, equals(110.0));
      expect(nutritionService.calorieTarget, equals(2100.0));
      expect(nutritionService.proteinTarget, equals(110.0));
    });

    test('4. Changing profile updates today\'s nutrition targets', () async {
      await userService.updateProfile(muscleProfile);
      final muscleGoals = goalService.calculateGoals(muscleProfile);

      expect(
        nutritionService.calorieTarget,
        equals(muscleGoals.caloriesConsumedGoal),
      );
      expect(
        nutritionService.proteinTarget,
        equals(muscleGoals.proteinGoalGrams),
      );

      // Switch to fatLossProfile
      await userService.updateProfile(fatLossProfile);
      final fatLossGoals = goalService.calculateGoals(fatLossProfile);

      expect(
        nutritionService.calorieTarget,
        equals(fatLossGoals.caloriesConsumedGoal),
      );
      expect(
        nutritionService.proteinTarget,
        equals(fatLossGoals.proteinGoalGrams),
      );
      expect(
        statsService.todayStats.caloriesConsumedGoal,
        equals(fatLossGoals.caloriesConsumedGoal),
      );
      expect(
        statsService.todayStats.proteinGoalGrams,
        equals(fatLossGoals.proteinGoalGrams),
      );
    });

    test(
      '5. Actual calories consumed remain unchanged after target changes',
      () async {
        final rice = LocalFoodDatabase.getFoodById('food_rice')!;
        await nutritionService.logFood(
          food: rice,
          category: MealCategory.lunch,
          servings: 2.0, // 390.0 kcal
        );
        await statsService.syncNutritionFromService(service: nutritionService);

        expect(nutritionService.todayCalories, equals(390.0));
        expect(statsService.todayStats.caloriesConsumed, equals(390.0));

        await userService.updateProfile(muscleProfile);

        expect(nutritionService.todayCalories, equals(390.0));
        expect(statsService.todayStats.caloriesConsumed, equals(390.0));
      },
    );

    test(
      '6. Actual protein consumed remains unchanged after target changes',
      () async {
        final soya = LocalFoodDatabase.getFoodById('food_soya')!;
        await nutritionService.logFood(
          food: soya,
          category: MealCategory.lunch,
          servings: 1.0, // 26.0g protein
        );
        await statsService.syncNutritionFromService(service: nutritionService);

        expect(nutritionService.todayProtein, equals(26.0));
        expect(statsService.todayStats.proteinGrams, equals(26.0));

        await userService.updateProfile(muscleProfile);

        expect(nutritionService.todayProtein, equals(26.0));
        expect(statsService.todayStats.proteinGrams, equals(26.0));
      },
    );

    test(
      '7. Actual carbs/fats remain unchanged after target changes',
      () async {
        final dal = LocalFoodDatabase.getFoodById('food_dal')!;
        await nutritionService.logFood(
          food: dal,
          category: MealCategory.dinner,
          servings: 1.0,
        );
        await statsService.syncNutritionFromService(service: nutritionService);

        final initialCarbs = nutritionService.todayCarbs;
        final initialFats = nutritionService.todayFats;

        await userService.updateProfile(fatLossProfile);

        expect(nutritionService.todayCarbs, equals(initialCarbs));
        expect(nutritionService.todayFats, equals(initialFats));
        expect(statsService.todayStats.carbsGrams, equals(initialCarbs));
        expect(statsService.todayStats.fatsGrams, equals(initialFats));
      },
    );

    test('8. Logged meal history remains unchanged', () async {
      final egg = LocalFoodDatabase.getFoodById('food_eggs')!;
      final meal1 = await nutritionService.logFood(
        food: egg,
        category: MealCategory.breakfast,
        servings: 2.0,
      );

      expect(nutritionService.allMeals.length, equals(1));
      expect(nutritionService.allMeals.first.id, equals(meal1.id));

      await userService.updateProfile(muscleProfile);

      expect(nutritionService.allMeals.length, equals(1));
      expect(nutritionService.allMeals.first.id, equals(meal1.id));
      expect(nutritionService.todayMeals.length, equals(1));
    });

    test(
      '9. NutritionService +20 XP meal logging behavior remains unchanged',
      () async {
        await gamificationService.init();
        final initialXp = gamificationService.xp;
        final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;

        await nutritionService.logFood(
          food: chicken,
          category: MealCategory.lunch,
          servings: 1.0,
        );

        expect(gamificationService.xp, equals(initialXp + 20));
      },
    );

    test('10. DailyStats nutrition goal values and nutrition UI target values stay consistent', () async {
      await userService.updateProfile(muscleProfile);

      final stats = statsService.todayStats;
      final expectedGoals = goalService.currentGoals;

      expect(
        stats.caloriesConsumedGoal,
        equals(expectedGoals.caloriesConsumedGoal),
      );
      expect(stats.proteinGoalGrams, equals(expectedGoals.proteinGoalGrams));
      expect(
        nutritionService.calorieTarget,
        equals(stats.caloriesConsumedGoal),
      );
      expect(nutritionService.proteinTarget, equals(stats.proteinGoalGrams));
    });

    test('11. Persistence still works', () async {
      await userService.updateProfile(muscleProfile);
      final rice = LocalFoodDatabase.getFoodById('food_rice')!;
      await nutritionService.logFood(
        food: rice,
        category: MealCategory.dinner,
        servings: 1.0,
      );

      // Re-initialize nutritionService from saved disk file
      await nutritionService.init();

      expect(nutritionService.todayMeals.length, equals(1));
      expect(nutritionService.todayCalories, equals(195.0));
      expect(
        nutritionService.calorieTarget,
        equals(goalService.currentGoals.caloriesConsumedGoal),
      );
      expect(
        nutritionService.proteinTarget,
        equals(goalService.currentGoals.proteinGoalGrams),
      );
    });

    test('12. No duplicate listeners or circular dependency', () async {
      // Re-attaching does not cause duplicate listeners
      statsService.attachNutritionListener(nutritionService);
      statsService.attachNutritionListener(nutritionService);
      statsService.attachGoalListener(goalService);
      statsService.attachGoalListener(goalService);

      int statsNotifyCount = 0;
      int nutritionNotifyCount = 0;
      statsService.addListener(() => statsNotifyCount++);
      nutritionService.addListener(() => nutritionNotifyCount++);

      // Updating profile
      await userService.updateProfile(muscleProfile);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify notification occurred cleanly without infinite loop
      expect(statsNotifyCount, greaterThan(0));

      // Logging food
      final rice = LocalFoodDatabase.getFoodById('food_rice')!;
      await nutritionService.logFood(
        food: rice,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      expect(nutritionNotifyCount, greaterThan(0));
    });

    testWidgets(
      '13. NutritionDashboardHeader widget displays personalized targets',
      (tester) async {
        await userService.updateProfile(muscleProfile);
        final expectedGoals = goalService.currentGoals;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NutritionDashboardHeader(
                nutrition: nutritionService,
                dailyStatsService: statsService,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DAILY TARGETS'), findsOneWidget);
        expect(
          find.textContaining(
            '${expectedGoals.caloriesConsumedGoal.toInt()} kcal',
          ),
          findsWidgets,
        );
        expect(
          find.textContaining('${expectedGoals.proteinGoalGrams.toInt()}g'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      '14. HostelFuelPreview widget displays personalized targets and updates on profile change',
      (tester) async {
        await userService.updateProfile(muscleProfile);
        final muscleGoals = goalService.currentGoals;

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: HostelFuelPreview())),
        );
        await tester.pumpAndSettle();

        // Should show muscle goals
        expect(
          find.text('Goal ${muscleGoals.caloriesConsumedGoal.toInt()} kcal'),
          findsOneWidget,
        );
        expect(
          find.text('Goal ${muscleGoals.proteinGoalGrams.toInt()}g'),
          findsOneWidget,
        );

        // Change profile to fatLoss
        await userService.updateProfile(fatLossProfile);
        final fatLossGoals = goalService.currentGoals;
        await tester.pumpAndSettle();

        // UI should reactively update to fatLoss goals
        expect(
          find.text('Goal ${fatLossGoals.caloriesConsumedGoal.toInt()} kcal'),
          findsOneWidget,
        );
        expect(
          find.text('Goal ${fatLossGoals.proteinGoalGrams.toInt()}g'),
          findsOneWidget,
        );
      },
    );
  });
}
