import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/food_item.dart';
import 'package:genfit/models/nutrition/food_preparation_level.dart';
import 'package:genfit/models/nutrition/food_recognition_result.dart';
import 'package:genfit/models/nutrition/logged_meal.dart';
import 'package:genfit/models/nutrition/meal_category.dart';
import 'package:genfit/screens/nutrition/food_scan_review_screen.dart';

void main() {
  group('FoodReviewNutrition Calculation Tests', () {
    late FoodItem chicken;

    setUp(() {
      chicken = LocalFoodDatabase.getFoodById('food_chicken')!;
    });

    test('1. Serving multiplier changes nutrition correctly', () {
      // Base: 245.0 kcal, 31.0g protein, 4.0g carbs, 11.5g fats
      final halfServing = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 0.5,
        preparation: FoodPreparationLevel.standard,
      );
      expect(halfServing.calories, equals(122.5));
      expect(halfServing.protein, equals(15.5));
      expect(halfServing.carbohydrates, equals(2.0));
      expect(halfServing.fats, equals(5.8));

      final doubleServing = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 2.0,
        preparation: FoodPreparationLevel.standard,
      );
      expect(doubleServing.calories, equals(490.0));
      expect(doubleServing.protein, equals(62.0));
      expect(doubleServing.carbohydrates, equals(8.0));
      expect(doubleServing.fats, equals(23.0));

      final tripleServing = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 3.0,
        preparation: FoodPreparationLevel.standard,
      );
      expect(tripleServing.calories, equals(735.0));
      expect(tripleServing.protein, equals(93.0));
      expect(tripleServing.carbohydrates, equals(12.0));
      expect(tripleServing.fats, equals(34.5));
    });

    test('2. Light / Standard / Rich preparation factors work correctly', () {
      // Light = 0.90x
      final lightPrep = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 1.0,
        preparation: FoodPreparationLevel.light,
      );
      expect(lightPrep.calories, equals(220.5)); // 245 * 0.90
      expect(lightPrep.protein, equals(27.9)); // 31.0 * 0.90
      expect(lightPrep.carbohydrates, equals(3.6)); // 4.0 * 0.90
      expect(lightPrep.fats, equals(10.3)); // 11.5 * 0.90 = 10.3499... -> 10.3

      // Standard = 1.00x
      final standardPrep = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 1.0,
        preparation: FoodPreparationLevel.standard,
      );
      expect(standardPrep.calories, equals(245.0));
      expect(standardPrep.protein, equals(31.0));
      expect(standardPrep.carbohydrates, equals(4.0));
      expect(standardPrep.fats, equals(11.5));

      // Rich = 1.15x
      final richPrep = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 1.0,
        preparation: FoodPreparationLevel.rich,
      );
      expect(richPrep.calories, equals(281.8)); // 245 * 1.15 = 281.75 -> 281.8
      expect(
        richPrep.protein,
        equals(35.6),
      ); // 31.0 * 1.15 = 35.6499... -> 35.6
      expect(richPrep.carbohydrates, equals(4.6)); // 4.0 * 1.15 = 4.6
      expect(richPrep.fats, equals(13.2)); // 11.5 * 1.15 = 13.2249... -> 13.2
    });

    test('3. Changing both serving size and preparation combines cleanly', () {
      final combined = FoodReviewNutrition.calculate(
        food: chicken,
        servings: 2.0,
        preparation: FoodPreparationLevel.rich, // 1.15x
      );
      // 245 * 2 = 490; 490 * 1.15 = 563.5
      expect(combined.calories, equals(563.5));
      // 31 * 2 = 62; 62 * 1.15 = 71.3
      expect(combined.protein, equals(71.3));
      // 4 * 2 = 8; 8 * 1.15 = 9.2
      expect(combined.carbohydrates, equals(9.2));
      // 11.5 * 2 = 23; 23 * 1.15 = 26.4499... -> 26.4
      expect(combined.fats, equals(26.4));
    });
  });

  group('Food Scan Logging Integration & Gamification Tests', () {
    late Directory tempDir;
    late NutritionService nutritionService;
    late GamificationService gamificationService;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('genfit_review_test_');
      nutritionService = NutritionService.instance;
      nutritionService.setCustomStoragePath(tempDir.path);
      await nutritionService.init();
      await nutritionService.clearAllMeals();

      gamificationService = GamificationService.instance;
      gamificationService.setCustomStoragePath(tempDir.path);
      await gamificationService.init();
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('4. Confirming a meal uses existing NutritionService flow with prep multiplier', () async {
      final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;
      final initialMealCount = nutritionService.allMeals.length;

      // Log meal with 1.5x serving and Rich prep (1.15x)
      final LoggedMeal meal = await nutritionService.logFood(
        food: chicken,
        category: MealCategory.lunch,
        servings: 1.5,
        preparationMultiplier: 1.15,
      );

      expect(meal.foodId, equals('food_chicken'));
      expect(meal.servings, equals(1.5));
      expect(meal.preparationMultiplier, equals(1.15));

      // Scaled base 1.5x: calories = 367.5; with 1.15x = 422.6
      expect(meal.calories, equals(422.6));
      expect(nutritionService.allMeals.length, equals(initialMealCount + 1));
      expect(nutritionService.todayCalories, equals(422.6));
    });

    test('5. Existing nutrition/gamification listener automatically triggers +20 XP', () async {
      final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;
      final initialXp = gamificationService.xp;
      final initialTotalMeals = gamificationService.totalMealsLogged;

      // Log meal via NutritionService
      await nutritionService.logFood(
        food: chicken,
        category: MealCategory.dinner,
        servings: 1.0,
        preparationMultiplier: 1.0,
      );

      // GamificationService observes NutritionService and awards +20 XP
      expect(gamificationService.xp, equals(initialXp + 20));
      expect(
        gamificationService.totalMealsLogged,
        equals(initialTotalMeals + 1),
      );
      expect(gamificationService.streakDays, greaterThanOrEqualTo(1));
    });
  });

  group('FoodScanReviewScreen Widget Tests', () {
    late Directory tempDir;
    late NutritionService nutritionService;
    late FoodItem chicken;
    late FoodRecognitionResult mockResult;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('genfit_review_widget_');
      nutritionService = NutritionService.instance;
      nutritionService.setCustomStoragePath(tempDir.path);
      await nutritionService.init();
      await nutritionService.clearAllMeals();

      chicken = LocalFoodDatabase.getFoodById('food_chicken')!;
      mockResult = FoodRecognitionResult(
        detectedLabel: 'Chicken Curry',
        confidence: 0.91,
        matchedFoodItem: chicken,
        imagePath: '/test/plate.jpg',
        analyzedAt: DateTime.now(),
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets(
      'renders review screen with initial 1x Standard nutrition preview',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: FoodScanReviewScreen(
              scanResult: mockResult,
              nutritionService: nutritionService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Header & Food preview
        expect(find.text('Review & Customize'), findsOneWidget);
        expect(find.text('AI DETECTED • 91%'), findsOneWidget);
        expect(find.text(chicken.name), findsOneWidget);

        // Serving options
        expect(find.text('Serving Size'), findsOneWidget);
        expect(find.text('0.5x'), findsOneWidget);
        expect(find.text('1x'), findsOneWidget);
        expect(find.text('2x'), findsOneWidget);

        // Preparation level
        expect(find.text('Preparation / Oil Level'), findsOneWidget);
        expect(
          find.text('Preparation is estimated — adjust if needed.'),
          findsOneWidget,
        );
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Standard'), findsOneWidget);
        expect(find.text('Rich'), findsOneWidget);

        // Baseline nutrition preview (1x Standard: 245 kcal, 31.0g protein)
        expect(find.text('245 kcal'), findsOneWidget);
        expect(find.text('31.0g'), findsOneWidget);
        expect(find.text('4.0g'), findsOneWidget);
        expect(find.text('11.5g'), findsOneWidget);

        // Confirm button
        expect(find.text('Confirm & Log Meal'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping serving chips updates dynamic nutrition preview immediately',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: FoodScanReviewScreen(
              scanResult: mockResult,
              nutritionService: nutritionService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap 2x serving
        await tester.tap(find.text('2x'));
        await tester.pumpAndSettle();

        // 2x Standard Chicken: 490 kcal, 62.0g protein
        expect(find.text('490 kcal'), findsOneWidget);
        expect(find.text('62.0g'), findsOneWidget);
        expect(find.text('8.0g'), findsOneWidget);
        expect(find.text('23.0g'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping preparation level updates dynamic nutrition preview immediately',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: FoodScanReviewScreen(
              scanResult: mockResult,
              nutritionService: nutritionService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Rich (1.15x)
        await tester.tap(find.text('Rich'));
        await tester.pumpAndSettle();

        // 1x Rich Chicken: 281 kcal (281.8 kcal rounded to int), 35.6g protein
        expect(find.text('281 kcal'), findsOneWidget);
        expect(find.text('35.6g'), findsOneWidget);
      },
    );

    testWidgets(
      'confirming meal logs through NutritionService and presents success state',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: FoodScanReviewScreen(
              scanResult: mockResult,
              nutritionService: nutritionService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Confirm & Log Meal
        final confirmBtn = find.text('Confirm & Log Meal');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Success view displayed
        expect(find.text('Meal Logged! +20 XP'), findsOneWidget);
        expect(find.text('Meal Confirmed'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        // Meal must be logged in NutritionService
        expect(nutritionService.allMeals.length, equals(1));
        expect(nutritionService.allMeals.first.foodId, equals('food_chicken'));
      },
    );
  });
}
