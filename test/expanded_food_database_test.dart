import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/food_item.dart';
import 'package:genfit/models/nutrition/hostel_mess_menu.dart';
import 'package:genfit/models/nutrition/meal_category.dart';

void main() {
  group('Expanded Food Database Tests', () {
    test(
      'contains comprehensive individual food items without locked combos',
      () {
        final allFoods = LocalFoodDatabase.getAllFoods();
        expect(allFoods.length, 101);

        // Verify each food has valid macros and metadata
        for (final food in allFoods) {
          expect(food.id, isNotEmpty);
          expect(food.name, isNotEmpty);
          expect(food.servingSize, isNotEmpty);
          expect(food.servingUnit, isNotEmpty);
          expect(
            food.calories,
            greaterThan(0),
            reason: '${food.id} calories invalid',
          );
          expect(
            food.protein,
            greaterThan(0),
            reason: '${food.id} protein invalid',
          );
          expect(
            food.carbohydrates,
            greaterThanOrEqualTo(0),
            reason: '${food.id} carbs invalid',
          );
          expect(
            food.fats,
            greaterThanOrEqualTo(0),
            reason: '${food.id} fats invalid',
          );
          expect(food.budgetCategory, isNotEmpty);
          expect(
            food.regionalTags,
            isNotEmpty,
            reason: '${food.id} tags missing',
          );
          expect(
            food.mealCategories,
            isNotEmpty,
            reason: '${food.id} categories missing',
          );
        }
      },
    );

    test('includes all requested Indian and Odia hostel mess staples', () {
      final requestedFoodIds = [
        'food_rice', // Rice
        'food_dal', // Dal
        'food_dalma', // Dalma
        'food_pakhala', // Pakhala
        'food_roti', // Roti
        'food_vegetables', // Vegetables
        'food_potato_curry', // Potato curry / Alu Dum
        'food_chana', // Chana
        'food_soya', // Soya
        'food_eggs', // Eggs
        'food_chicken', // Chicken
        'food_fish', // Fish
        'food_paneer', // Paneer
        'food_milk', // Milk
        'food_curd', // Curd
        'food_banana', // Banana
        'food_peanuts', // Peanuts
        'food_poha', // Poha
        'food_upma', // Upma
        'food_sattu', // Sattu/Chhatua
        'food_santula', // Odia Santula
        'food_khichdi', // Khechudi/Khichdi
        'food_single_egg', // Single egg
        'food_single_roti', // Single roti
        'food_egg_curry', // Egg curry
        'food_sprouts', // Moong sprouts
        'food_idli_sambar', // Idli sambar
        'food_maggi', // Maggi
        'food_mudhi_mixture', // Mudhi mixture
        'food_besan_chilla', // Besan chilla
        // New Phase 2 specific foods:
        'food_bara', // Bara
        'food_dahibara', // Dahibara
        'food_chakuli_pitha', // Chakuli Pitha
        'food_alu_chop', // Alu Chop
        'food_paratha', // Paratha
        'food_chutney', // Chutney
        'food_biryani', // Biryani
        'food_raita', // Raita
        'food_egg_bhurji', // Egg Bhurji
        'food_mixed_tadka', // Mixed Tadka
        'food_mushroom_curry', // Mushroom Curry
        'food_ice_cream', // Ice Cream
        // Phase 3 Expanded Foods (Indian Staples & Curries)
        'food_puri',
        'food_naan',
        'food_idli',
        'food_dosa',
        'food_sambar',
        'food_rasam',
        'food_rajma',
        'food_chole',
        'food_kadhi',
        'food_aloo_gobi',
        'food_veg_biryani',
        // Hostel & College Foods
        'food_egg_maggi',
        'food_bread_omelette',
        'food_omelette',
        'food_tea',
        'food_coffee',
        'food_banana_shake',
        'food_bread',
        'food_jam',
        'food_butter',
        'food_biscuits',
        // Western / Fast Foods
        'food_pizza',
        'food_burger',
        'food_sandwich',
        'food_pasta',
        'food_french_fries',
        'food_noodles',
        'food_fried_rice',
        'food_momos',
        'food_wrap',
        'food_pancakes',
        'food_oatmeal',
        'food_cereal',
        // Fruits
        'food_apple',
        'food_orange',
        'food_mango',
        'food_papaya',
        'food_guava',
        'food_watermelon',
        'food_pineapple',
        'food_grapes',
        'food_pomegranate',
        'food_coconut',
        'food_pear',
        // Snacks
        'food_roasted_chana',
        'food_cashews',
        'food_almonds',
        'food_walnuts',
        'food_protein_bar',
        'food_chips',
        'food_samosa',
        'food_pakora',
        'food_namkeen',
        'food_popcorn',
        // Protein / Fitness
        'food_tofu',
        'food_peanut_butter',
        'food_whey_protein',
      ];

      for (final id in requestedFoodIds) {
        final food = LocalFoodDatabase.getFoodById(id);
        expect(food, isNotNull, reason: 'Food ID $id must be present');
      }
    });

    test('supports all standard realistic serving units', () {
      final units = LocalFoodDatabase.getAllServingUnits();

      expect(units, contains('katori')); // 1 katori
      expect(units, contains('bowl')); // 1 bowl
      expect(units, contains('plate')); // 1 plate
      expect(units, contains('cup')); // 1 cup
      expect(units, contains('roti')); // 1 roti
      expect(units, contains('egg')); // 1 egg
      expect(units, contains('100g')); // 100g
      expect(units, contains('glass')); // 1 glass
      expect(units, contains('piece')); // 1 piece

      // Check specific foods with these units
      final dal = LocalFoodDatabase.getFoodById('food_dal')!;
      expect(dal.servingUnit, 'katori');
      expect(dal.servingSize, contains('150g'));

      final potatoCurry = LocalFoodDatabase.getFoodById('food_potato_curry')!;
      expect(potatoCurry.servingUnit, 'katori');
      expect(potatoCurry.servingSize, '1 katori (150g)');

      final rice = LocalFoodDatabase.getFoodById('food_rice')!;
      expect(rice.servingUnit, 'bowl');
      expect(rice.servingSize, '1 bowl (150g)');

      final singleRoti = LocalFoodDatabase.getFoodById('food_single_roti')!;
      expect(singleRoti.servingUnit, 'roti');
      expect(singleRoti.servingSize, '1 roti (30g)');

      final singleEgg = LocalFoodDatabase.getFoodById('food_single_egg')!;
      expect(singleEgg.servingUnit, 'egg');
      expect(singleEgg.servingSize, '1 egg (50g)');

      final rawPaneer = LocalFoodDatabase.getFoodById('food_paneer_raw')!;
      expect(rawPaneer.servingUnit, '100g');
      expect(rawPaneer.servingSize, '100g');

      final paneerCurry = LocalFoodDatabase.getFoodById('food_paneer')!;
      expect(paneerCurry.servingUnit, 'plate');
      expect(paneerCurry.servingSize, '1 plate (150g)');

      final biryani = LocalFoodDatabase.getFoodById('food_biryani')!;
      expect(biryani.servingUnit, 'plate');
      expect(biryani.servingSize, '1 plate (250g)');

      final raita = LocalFoodDatabase.getFoodById('food_raita')!;
      expect(raita.servingUnit, 'katori');
      expect(raita.servingSize, '1 katori (120g)');

      final iceCream = LocalFoodDatabase.getFoodById('food_ice_cream')!;
      expect(iceCream.servingUnit, 'cup');
    });
  });

  group('Hostel Individual Food Items Coverage Tests', () {
    test('verifies all Breakfast individual items', () {
      // Upma, Poha, Bara, Dahibara, Chakuli Pitha, Alu Chop, Paratha, Chutney
      final breakfastIds = [
        'food_upma',
        'food_poha',
        'food_bara',
        'food_dahibara',
        'food_chakuli_pitha',
        'food_alu_chop',
        'food_paratha',
        'food_chutney',
      ];

      for (final id in breakfastIds) {
        final food = LocalFoodDatabase.getFoodById(id);
        expect(food, isNotNull);
        expect(
          food!.matchesCategory(MealCategory.breakfast),
          isTrue,
          reason: '$id must match Breakfast category',
        );
      }
    });

    test('verifies all Lunch individual items', () {
      // Rice, Dal, Fish Curry, Chicken, Soya Bean, Mixed Vegetable, Biryani, Raita
      final lunchIds = [
        'food_rice',
        'food_dal',
        'food_fish',
        'food_chicken',
        'food_soya',
        'food_vegetables',
        'food_biryani',
        'food_raita',
      ];

      for (final id in lunchIds) {
        final food = LocalFoodDatabase.getFoodById(id);
        expect(food, isNotNull);
        expect(
          food!.matchesCategory(MealCategory.lunch),
          isTrue,
          reason: '$id must match Lunch category',
        );
      }
    });

    test('verifies all Dinner individual items', () {
      // Roti, Egg Curry, Egg Bhurji, Mixed Tadka, Paneer, Mushroom Curry, Paratha, Alu Dum, Ice Cream
      final dinnerIds = [
        'food_roti',
        'food_egg_curry',
        'food_egg_bhurji',
        'food_mixed_tadka',
        'food_paneer',
        'food_mushroom_curry',
        'food_paratha',
        'food_potato_curry',
        'food_ice_cream',
      ];

      for (final id in dinnerIds) {
        final food = LocalFoodDatabase.getFoodById(id);
        expect(food, isNotNull);
        expect(
          food!.matchesCategory(MealCategory.dinner),
          isTrue,
          reason: '$id must match Dinner category',
        );
      }
    });

    test('enforces menu philosophy: meals are independent foods, NOT locked combos', () {
      // Chicken Meal is NOT one locked food; it consists of independent items
      final rice = LocalFoodDatabase.getFoodById('food_rice')!;
      final dal = LocalFoodDatabase.getFoodById('food_dal')!;
      final raita = LocalFoodDatabase.getFoodById('food_raita')!;
      final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;

      expect(rice.id, isNot(equals(dal.id)));
      expect(dal.id, isNot(equals(raita.id)));
      expect(raita.id, isNot(equals(chicken.id)));

      // User can independently calculate each portion
      final riceNutr = rice.calculateForServings(1.0);
      final dalNutr = dal.calculateForServings(1.0);
      final raitaNutr = raita.calculateForServings(1.0);
      final chickenNutr = chicken.calculateForServings(1.0);

      final totalCalories =
          riceNutr.calories +
          dalNutr.calories +
          raitaNutr.calories +
          chickenNutr.calories;
      // 195 + 160 + 85 + 245 = 685 kcal
      expect(totalCalories, 685.0);

      // Fish meal components are independent
      final fish = LocalFoodDatabase.getFoodById('food_fish')!;
      expect(fish.id, 'food_fish');
      expect(fish.protein, 24.0);

      // Confirm no combo meal items exist in database
      final allFoods = LocalFoodDatabase.getAllFoods();
      for (final food in allFoods) {
        expect(
          food.name.toLowerCase().contains('combo meal'),
          isFalse,
          reason: '${food.name} should not be a combo meal',
        );
        expect(
          food.name.toLowerCase().contains('thali meal'),
          isFalse,
          reason: '${food.name} should not be a locked thali',
        );
      }
    });
  });

  group('Regional Tags & Search Filtering Tests', () {
    test('extracts all unique regional and contextual tags', () {
      final tags = LocalFoodDatabase.getAllTags();
      expect(tags, isNotEmpty);
      expect(tags, contains('Odia Heritage'));
      expect(tags, contains('Hostel Lunch'));
      expect(tags, contains('Hostel Dinner'));
      expect(tags, contains('Evening Snack'));
      expect(tags, contains('High Protein'));
      expect(tags, contains('Mess Essential'));
    });

    test('filters foods by specific regional tags', () {
      final odiaHeritageFoods = LocalFoodDatabase.getFoodsByTag(
        'Odia Heritage',
      );
      expect(odiaHeritageFoods.length, greaterThanOrEqualTo(5));

      final odiaFoodIds = odiaHeritageFoods.map((f) => f.id).toList();
      expect(odiaFoodIds, contains('food_dalma'));
      expect(odiaFoodIds, contains('food_pakhala'));
      expect(odiaFoodIds, contains('food_santula'));
      expect(odiaFoodIds, contains('food_mudhi_mixture'));
      expect(odiaFoodIds, contains('food_sattu'));
      expect(odiaFoodIds, contains('food_bara'));
      expect(odiaFoodIds, contains('food_dahibara'));
    });

    test('searchFoods filters by category, tag, and query', () {
      // Search by query
      final potatoSearch = LocalFoodDatabase.searchFoods('Potato');
      expect(potatoSearch.length, greaterThanOrEqualTo(2));
      expect(potatoSearch.any((f) => f.id == 'food_potato_curry'), isTrue);
      expect(potatoSearch.any((f) => f.id == 'food_alu_chop'), isTrue);

      // Search specifically by Alu Dum
      final aluDumSearch = LocalFoodDatabase.searchFoods('Alu Dum');
      expect(aluDumSearch.length, 1);
      expect(aluDumSearch.first.id, 'food_potato_curry');

      // Search for Biryani (matches Chicken Biryani, Veg Biryani, and companion Raita)
      final biryaniSearch = LocalFoodDatabase.searchFoods('Biryani');
      expect(biryaniSearch.length, 3);
      expect(biryaniSearch.any((f) => f.id == 'food_biryani'), isTrue);
      expect(biryaniSearch.any((f) => f.id == 'food_veg_biryani'), isTrue);
      expect(biryaniSearch.any((f) => f.id == 'food_raita'), isTrue);

      // Search for Dahibara
      final dahibaraSearch = LocalFoodDatabase.searchFoods('Dahibara');
      expect(dahibaraSearch.length, 1);
      expect(dahibaraSearch.first.id, 'food_dahibara');

      // Search for Mushroom
      final mushroomSearch = LocalFoodDatabase.searchFoods('Mushroom');
      expect(mushroomSearch.length, 1);
      expect(mushroomSearch.first.id, 'food_mushroom_curry');

      // Search by serving unit keyword
      final katoriFoods = LocalFoodDatabase.searchFoods('katori');
      expect(katoriFoods.length, greaterThanOrEqualTo(3));

      // Filter by category
      final breakfastSearch = LocalFoodDatabase.searchFoods(
        '',
        category: MealCategory.breakfast,
      );
      for (final f in breakfastSearch) {
        expect(f.matchesCategory(MealCategory.breakfast), isTrue);
      }

      // Filter by regionalTag
      final snackTagFoods = LocalFoodDatabase.searchFoods(
        '',
        regionalTag: 'Evening Snack',
      );
      for (final f in snackTagFoods) {
        expect(f.matchesRegionalTag('Evening Snack'), isTrue);
      }
    });
  });

  group('Budget Alternatives Rule-based Swaps Tests', () {
    test('preserves existing swaps and supports new paneer & sattu swaps', () {
      final alternatives = LocalFoodDatabase.alternatives;
      expect(alternatives.length, 5);

      // Existing
      expect(
        LocalFoodDatabase.getAlternativeForFood('food_chicken')
            ?.alternativeFoodId,
        'food_soya',
      );
      expect(
        LocalFoodDatabase.getAlternativeForFood('food_fish')?.alternativeFoodId,
        'food_eggs',
      );
      expect(
        LocalFoodDatabase.getAlternativeForFood('food_rice')?.alternativeFoodId,
        'food_ragi',
      );

      // New
      final paneerSwap = LocalFoodDatabase.getAlternativeForFood('food_paneer');
      expect(paneerSwap, isNotNull);
      expect(paneerSwap!.alternativeFoodId, 'food_soya');
      expect(paneerSwap.estimatedSavings, contains('Save ₹65'));

      final sattuSwap = LocalFoodDatabase.getAlternativeForFood(
        'food_paneer_raw',
      );
      expect(sattuSwap, isNotNull);
      expect(sattuSwap!.alternativeFoodId, 'food_sattu');
      expect(sattuSwap.estimatedSavings, contains('Save ₹35'));
    });
  });

  group('Modular College Hostel Mess Menus Tests', () {
    test('supports GCEK and ITER hostel mess menus', () {
      final gcekMenu = LocalFoodDatabase.getHostelMenuForCollege(
        'GCEK Kalahandi',
      );
      expect(gcekMenu, isNotNull);
      expect(gcekMenu!.college, 'GCEK Kalahandi');
      expect(gcekMenu.campus, 'Bhawanipatna Campus');

      final iterMenu = LocalFoodDatabase.getHostelMenuForCollege('ITER');
      expect(iterMenu, isNotNull);
      expect(iterMenu!.college, contains('ITER'));
    });

    test(
      'retrieves college-specific mess foods for requested meal category',
      () {
        final gcekLunch = LocalFoodDatabase.getFoodsForHostelMenu(
          'GCEK Kalahandi',
          MealCategory.lunch,
        );
        expect(gcekLunch, isNotEmpty);
        final gcekLunchIds = gcekLunch.map((f) => f.id).toList();
        expect(gcekLunchIds, contains('food_rice'));
        expect(gcekLunchIds, contains('food_dalma'));
        expect(gcekLunchIds, contains('food_santula'));

        final iterDinner = LocalFoodDatabase.getFoodsForHostelMenu(
          'ITER',
          MealCategory.dinner,
        );
        expect(iterDinner, isNotEmpty);
        final iterDinnerIds = iterDinner.map((f) => f.id).toList();
        expect(iterDinnerIds, contains('food_roti'));
        expect(iterDinnerIds, contains('food_chicken'));
        expect(iterDinnerIds, contains('food_paneer'));
      },
    );

    test('HostelMessMenu serializes and deserializes accurately', () {
      final menu = HostelMessMenu(
        id: 'menu_test',
        college: 'VSSUT Burla',
        campus: 'Sambalpur',
        messName: 'Marichi Hall Mess',
        dailyFoodIds: {
          MealCategory.breakfast: ['food_upma', 'food_banana'],
          MealCategory.lunch: ['food_rice', 'food_dal'],
        },
      );

      final json = menu.toJson();
      final restored = HostelMessMenu.fromJson(json);

      expect(restored.id, menu.id);
      expect(restored.college, 'VSSUT Burla');
      expect(restored.campus, 'Sambalpur');
      expect(restored.dailyFoodIds[MealCategory.breakfast], [
        'food_upma',
        'food_banana',
      ]);
      expect(restored.dailyFoodIds[MealCategory.lunch], [
        'food_rice',
        'food_dal',
      ]);
    });
  });

  group('FoodItem Model Enhancements Tests', () {
    test(
      'FoodItem serialization roundtrip preserves mealCategories and tags',
      () {
        const item = FoodItem(
          id: 'food_test',
          name: 'Test Food',
          servingSize: '1 bowl (150g)',
          servingUnit: 'bowl',
          calories: 120.0,
          protein: 5.0,
          carbohydrates: 20.0,
          fats: 2.0,
          isVegetarian: true,
          budgetCategory: 'Pocket Friendly (₹)',
          regionalTags: ['Odia Heritage', 'Hostel Lunch'],
          mealCategories: [MealCategory.lunch, MealCategory.dinner],
        );

        expect(item.matchesCategory(MealCategory.lunch), isTrue);
        expect(item.matchesCategory(MealCategory.breakfast), isFalse);
        expect(item.matchesRegionalTag('Odia Heritage'), isTrue);
        expect(item.matchesRegionalTag('Hostel Lunch'), isTrue);
        expect(item.matchesRegionalTag('Unknown'), isFalse);

        final json = item.toJson();
        final restored = FoodItem.fromJson(json);

        expect(restored.id, item.id);
        expect(restored.name, item.name);
        expect(restored.servingUnit, 'bowl');
        expect(restored.mealCategories, [
          MealCategory.lunch,
          MealCategory.dinner,
        ]);
        expect(restored.regionalTags, ['Odia Heritage', 'Hostel Lunch']);
      },
    );
  });
}
