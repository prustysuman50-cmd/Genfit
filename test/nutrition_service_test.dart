import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/logged_meal.dart';
import 'package:genfit/models/nutrition/meal_category.dart';

void main() {
  group('FoodItem & Nutritional Calculation Tests', () {
    final food = LocalFoodDatabase.getFoodById('food_soya')!;

    test('1.0 serving preserves exact base nutrition values', () {
      final values = food.calculateForServings(1.0);
      expect(values.calories, food.calories);
      expect(values.protein, food.protein);
      expect(values.carbohydrates, food.carbohydrates);
      expect(values.fats, food.fats);
    });

    test('0.5 serving halves nutrition values accurately', () {
      final values = food.calculateForServings(0.5);
      expect(values.calories, 85.0);
      expect(values.protein, 13.0);
      expect(values.carbohydrates, 8.3);
      expect(values.fats, 0.4);
    });

    test('1.5 serving scales nutrition values accurately', () {
      final values = food.calculateForServings(1.5);
      expect(values.calories, 255.0);
      expect(values.protein, 39.0);
      expect(values.carbohydrates, 24.8);
      expect(values.fats, 1.2);
    });

    test('2.0 serving doubles nutrition values accurately', () {
      final values = food.calculateForServings(2.0);
      expect(values.calories, 340.0);
      expect(values.protein, 52.0);
      expect(values.carbohydrates, 33.0);
      expect(values.fats, 1.6);
    });
  });

  group('LocalFoodDatabase Content & Requirement Tests', () {
    test('contains all 12 required Odia & Indian staple foods', () {
      final allFoods = LocalFoodDatabase.getAllFoods();
      expect(allFoods.length, greaterThanOrEqualTo(12));

      final requiredFoodIds = [
        'food_rice', // Rice
        'food_dal', // Dal
        'food_dalma', // Dalma
        'food_pakhala', // Pakhala
        'food_ragi', // Ragi/Mandia
        'food_chana', // Chana
        'food_soya', // Soya
        'food_eggs', // Eggs
        'food_chicken', // Chicken
        'food_fish', // Fish
        'food_roti', // Roti
        'food_vegetables', // Common vegetables
      ];

      for (final id in requiredFoodIds) {
        final food = LocalFoodDatabase.getFoodById(id);
        expect(food, isNotNull, reason: 'Missing required food id: $id');
        expect(food!.name, isNotEmpty);
        expect(food.servingSize, isNotEmpty);
        expect(food.calories, greaterThan(0));
        expect(food.protein, greaterThan(0));
        expect(food.carbohydrates, greaterThanOrEqualTo(0));
        expect(food.fats, greaterThanOrEqualTo(0));
        expect(food.budgetCategory, isNotEmpty);
        expect(food.regionalTags, isNotEmpty);
      }
    });

    test('searches foods by query matching name, tag, or budget', () {
      final dalmaResult = LocalFoodDatabase.searchFoods('Dalma');
      expect(dalmaResult.length, 1);
      expect(dalmaResult.first.id, 'food_dalma');

      final odiaHeritage = LocalFoodDatabase.searchFoods('Odia Heritage');
      expect(odiaHeritage.length, greaterThanOrEqualTo(2));

      final highProtein = LocalFoodDatabase.searchFoods(
        '',
        highProteinOnly: true,
      );
      for (final f in highProtein) {
        expect(f.protein, greaterThanOrEqualTo(10.0));
      }

      final vegOnly = LocalFoodDatabase.searchFoods('', vegetarianOnly: true);
      for (final f in vegOnly) {
        expect(f.isVegetarian, isTrue);
      }
    });
  });

  group('Affordable Alternatives Rule-based Tests', () {
    test('provides budget protein alternative for chicken', () {
      final alt = LocalFoodDatabase.getAlternativeForFood('food_chicken');
      expect(alt, isNotNull);
      expect(alt!.alternativeFoodId, 'food_soya');
      expect(alt.estimatedSavings, contains('Save ₹75'));
      expect(alt.proteinComparison, contains('26g vs 31g'));
    });

    test('provides budget protein alternative for fish', () {
      final alt = LocalFoodDatabase.getAlternativeForFood('food_fish');
      expect(alt, isNotNull);
      expect(alt!.alternativeFoodId, 'food_eggs');
      expect(alt.estimatedSavings, contains('Save ₹66'));
    });

    test('provides millet mission upgrade for white rice', () {
      final alt = LocalFoodDatabase.getAlternativeForFood('food_rice');
      expect(alt, isNotNull);
      expect(alt!.alternativeFoodId, 'food_ragi');
      expect(alt.proteinComparison, contains('Mandia'));
    });
  });

  group('NutritionService Logging & Calculation Tests', () {
    late Directory tempDir;
    final service = NutritionService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('nutrition_test_');
      service.setCustomStoragePath(tempDir.path);
      await service.resetToDefaults();
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('initial state has sensible mock targets and 0 consumed macros', () {
      expect(service.calorieTarget, 2100.0);
      expect(service.proteinTarget, 110.0);
      expect(service.todayCalories, 0.0);
      expect(service.todayProtein, 0.0);
      expect(service.calorieProgress, 0.0);
      expect(service.proteinProgress, 0.0);
      expect(service.remainingCalories, 2100.0);
      expect(service.remainingProtein, 110.0);
      expect(service.todayMeals, isEmpty);
    });

    test(
      'adding a single meal updates calories, protein, and category',
      () async {
        final dalma = LocalFoodDatabase.getFoodById('food_dalma')!;
        await service.logFood(
          food: dalma,
          category: MealCategory.lunch,
          servings: 1.0,
        );

        expect(service.todayMeals.length, 1);
        expect(service.todayCalories, 175.0);
        expect(service.todayProtein, 8.5);
        expect(service.calorieProgress, closeTo(175.0 / 2100.0, 0.01));
        expect(service.proteinProgress, closeTo(8.5 / 110.0, 0.01));
        expect(service.remainingCalories, 1925.0);
        expect(service.remainingProtein, 101.5);

        final lunchMeals = service.mealsForCategory(MealCategory.lunch);
        expect(lunchMeals.length, 1);
        expect(lunchMeals.first.name, dalma.name);
        expect(lunchMeals.first.category, MealCategory.lunch);

        expect(service.mealsForCategory(MealCategory.breakfast), isEmpty);
        expect(service.mealsForCategory(MealCategory.dinner), isEmpty);
        expect(service.mealsForCategory(MealCategory.snacks), isEmpty);
      },
    );

    test('serving quantity dynamically affects nutrition totals', () async {
      final soya = LocalFoodDatabase.getFoodById('food_soya')!;
      // 2.0 servings: 340 kcal, 52g protein
      await service.logFood(
        food: soya,
        category: MealCategory.lunch,
        servings: 2.0,
      );

      expect(service.todayCalories, 340.0);
      expect(service.todayProtein, 52.0);
      expect(service.todayCarbs, 33.0);
      expect(service.todayFats, 1.6);
      expect(service.proteinProgress, closeTo(52.0 / 110.0, 0.01));
    });

    test('adds meals across all 4 categories and aggregates totals', () async {
      final pakhala = LocalFoodDatabase.getFoodById('food_pakhala')!;
      final dalma = LocalFoodDatabase.getFoodById('food_dalma')!;
      final chana = LocalFoodDatabase.getFoodById('food_chana')!;
      final roti = LocalFoodDatabase.getFoodById('food_roti')!;

      // Breakfast: Pakhala (1x = 210 kcal, 5.2g protein)
      await service.logFood(
        food: pakhala,
        category: MealCategory.breakfast,
        servings: 1.0,
      );

      // Lunch: Dalma (1x = 175 kcal, 8.5g protein)
      await service.logFood(
        food: dalma,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      // Snacks: Chana (1x = 215 kcal, 13.5g protein)
      await service.logFood(
        food: chana,
        category: MealCategory.snacks,
        servings: 1.0,
      );

      // Dinner: Roti (2x = 320 kcal, 10.4g protein)
      await service.logFood(
        food: roti,
        category: MealCategory.dinner,
        servings: 2.0,
      );

      expect(service.todayMeals.length, 4);
      expect(service.mealsForCategory(MealCategory.breakfast).length, 1);
      expect(service.mealsForCategory(MealCategory.lunch).length, 1);
      expect(service.mealsForCategory(MealCategory.snacks).length, 1);
      expect(service.mealsForCategory(MealCategory.dinner).length, 1);

      // Expected totals:
      // Calories: 210 + 175 + 215 + 320 = 920 kcal
      // Protein: 5.2 + 8.5 + 13.5 + 10.4 = 37.6g
      expect(service.todayCalories, 920.0);
      expect(service.todayProtein, 37.6);
      expect(service.remainingCalories, 2100.0 - 920.0);
      expect(service.remainingProtein, 110.0 - 37.6);

      // Category subtotals
      expect(service.caloriesForCategory(MealCategory.breakfast), 210.0);
      expect(service.caloriesForCategory(MealCategory.dinner), 320.0);
      expect(service.proteinForCategory(MealCategory.snacks), 13.5);
    });

    test('removing a meal decrements totals appropriately', () async {
      final eggs = LocalFoodDatabase.getFoodById('food_eggs')!;
      final meal = await service.logFood(
        food: eggs,
        category: MealCategory.breakfast,
        servings: 1.0,
      );

      expect(service.todayMeals.length, 1);
      expect(service.todayCalories, 148.0);
      expect(service.todayProtein, 12.6);

      await service.removeMeal(meal.id);

      expect(service.todayMeals.length, 0);
      expect(service.todayCalories, 0.0);
      expect(service.todayProtein, 0.0);
    });

    test(
      'customizing targets updates progress and remaining amounts',
      () async {
        await service.setTargets(calorieTarget: 2500.0, proteinTarget: 140.0);
        expect(service.calorieTarget, 2500.0);
        expect(service.proteinTarget, 140.0);
        expect(service.remainingCalories, 2500.0);
        expect(service.remainingProtein, 140.0);
      },
    );
  });

  group('NutritionService Local Persistence Tests', () {
    late Directory tempDir;
    final service = NutritionService.instance;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nutrition_persist_');
      service.setCustomStoragePath(tempDir.path);
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test(
      'meals and targets persist to disk and reload on re-initialization',
      () async {
        await service.resetToDefaults();
        await service.setTargets(calorieTarget: 2300.0, proteinTarget: 125.0);

        final soya = LocalFoodDatabase.getFoodById('food_soya')!;
        final pakhala = LocalFoodDatabase.getFoodById('food_pakhala')!;

        await service.logFood(
          food: soya,
          category: MealCategory.lunch,
          servings: 1.5, // 255 kcal, 39g protein
        );

        await service.logFood(
          food: pakhala,
          category: MealCategory.breakfast,
          servings: 1.0, // 210 kcal, 5.2g protein
        );

        expect(service.todayMeals.length, 2);
        expect(service.todayCalories, 465.0);
        expect(service.todayProtein, 44.2);

        // Verify JSON file exists on disk
        final file = File('${tempDir.path}/genfit_nutrition.json');
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), contains('food_soya'));
        expect(file.readAsStringSync(), contains('food_pakhala'));

        // Simulate app restart: re-initialize service from disk
        await service.init();

        expect(service.calorieTarget, 2300.0);
        expect(service.proteinTarget, 125.0);
        expect(service.todayMeals.length, 2);
        expect(service.todayCalories, 465.0);
        expect(service.todayProtein, 44.2);
        expect(service.mealsForCategory(MealCategory.lunch).length, 1);
        expect(service.mealsForCategory(MealCategory.breakfast).length, 1);
      },
    );

    test('LoggedMeal JSON serialization roundtrip works accurately', () {
      final food = LocalFoodDatabase.getFoodById('food_chicken')!;
      final meal = LoggedMeal.fromFoodItem(
        food: food,
        category: MealCategory.dinner,
        servings: 1.5,
        isBudgetAlternativeUsed: true,
      );

      final json = meal.toJson();
      final roundtrip = LoggedMeal.fromJson(json);

      expect(roundtrip.id, meal.id);
      expect(roundtrip.foodId, meal.foodId);
      expect(roundtrip.name, meal.name);
      expect(roundtrip.category, MealCategory.dinner);
      expect(roundtrip.servings, 1.5);
      expect(roundtrip.calories, meal.calories);
      expect(roundtrip.protein, meal.protein);
      expect(roundtrip.carbohydrates, meal.carbohydrates);
      expect(roundtrip.fats, meal.fats);
      expect(roundtrip.isVegetarian, isFalse);
      expect(roundtrip.isBudgetAlternativeUsed, isTrue);
    });
  });
}
