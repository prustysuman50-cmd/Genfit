import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/food_recognition_service.dart';
import 'package:genfit/core/services/gemini_vision_service.dart';
import 'package:genfit/core/services/local_food_matcher.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/food_recognition_result.dart';
import 'package:genfit/screens/nutrition/food_scan_review_screen.dart';

void main() {
  group('Gemini Vision & LocalFoodMatcher Pipeline Tests', () {
    test('1. LocalFoodMatcher accurately matches Indian mess dishes to LocalFoodDatabase', () {
      // Rice variants
      final rice = LocalFoodMatcher.match('Rice');
      expect(rice, isNotNull);
      expect(rice!.id, equals('food_rice'));

      final steamedRice = LocalFoodMatcher.match('Steamed White Rice');
      expect(steamedRice, isNotNull);
      expect(steamedRice!.id, equals('food_rice'));

      // Dal variants
      final dal = LocalFoodMatcher.match('Dal Fry');
      expect(dal, isNotNull);
      expect(dal!.id, equals('food_dal'));

      final toorDal = LocalFoodMatcher.match('Yellow Toor Dal');
      expect(toorDal, isNotNull);
      expect(toorDal!.id, equals('food_dal'));

      // Chicken Curry
      final chicken = LocalFoodMatcher.match('Chicken Curry');
      expect(chicken, isNotNull);
      expect(chicken!.id, equals('food_chicken'));

      // Roti / Chapati
      final roti = LocalFoodMatcher.match('Chapati');
      expect(roti, isNotNull);
      expect(roti!.id, equals('food_roti'));

      // Eggs
      final eggs = LocalFoodMatcher.match('Boiled Eggs');
      expect(eggs, isNotNull);
      expect(eggs!.id, equals('food_eggs'));

      // Paneer
      final paneer = LocalFoodMatcher.match('Paneer Bhurji');
      expect(paneer, isNotNull);
      expect(paneer!.id, equals('food_paneer'));

      // Soya Chunks
      final soya = LocalFoodMatcher.match('Soya Chunks Curry');
      expect(soya, isNotNull);
      expect(soya!.id, equals('food_soya'));

      // Empty or invalid input
      expect(LocalFoodMatcher.match(''), isNull);
    });

    test('1b. LocalFoodMatcher resolves newly expanded foods and aliases across all 7 categories', () {
      // 1. Indian staples
      expect(LocalFoodMatcher.match('Maggi')?.id, equals('food_maggi'));
      expect(LocalFoodMatcher.match('Maggi Noodles')?.id, equals('food_maggi'));
      expect(LocalFoodMatcher.match('Chapati')?.id, equals('food_roti'));
      expect(LocalFoodMatcher.match('Poori')?.id, equals('food_puri'));
      expect(LocalFoodMatcher.match('Butter Naan')?.id, equals('food_naan'));
      expect(LocalFoodMatcher.match('Idli')?.id, equals('food_idli'));
      expect(LocalFoodMatcher.match('Crispy Dosa')?.id, equals('food_dosa'));
      expect(LocalFoodMatcher.match('Rasam')?.id, equals('food_rasam'));
      expect(LocalFoodMatcher.match('Rajma Chawal')?.id, equals('food_rajma'));
      expect(LocalFoodMatcher.match('Chole')?.id, equals('food_chole'));
      expect(LocalFoodMatcher.match('Kadhi Pakora')?.id, equals('food_kadhi'));

      // 2. Curries & meals
      expect(LocalFoodMatcher.match('Aloo Gobi')?.id, equals('food_aloo_gobi'));
      expect(
        LocalFoodMatcher.match('Veg Biryani')?.id,
        equals('food_veg_biryani'),
      );
      expect(
        LocalFoodMatcher.match('Chicken Biryani')?.id,
        equals('food_biryani'),
      );

      // 3. Hostel & college foods
      expect(
        LocalFoodMatcher.match('Maggi with egg')?.id,
        equals('food_egg_maggi'),
      );
      expect(LocalFoodMatcher.match('Egg Maggi')?.id, equals('food_egg_maggi'));
      expect(
        LocalFoodMatcher.match('Bread Omelette')?.id,
        equals('food_bread_omelette'),
      );
      expect(
        LocalFoodMatcher.match('Egg Bhurji')?.id,
        equals('food_egg_bhurji'),
      );
      expect(LocalFoodMatcher.match('Chai')?.id, equals('food_tea'));
      expect(LocalFoodMatcher.match('Hot Coffee')?.id, equals('food_coffee'));
      expect(LocalFoodMatcher.match('Dahi')?.id, equals('food_curd'));
      expect(LocalFoodMatcher.match('Curd')?.id, equals('food_curd'));
      expect(LocalFoodMatcher.match('Sattu Drink')?.id, equals('food_sattu'));
      expect(
        LocalFoodMatcher.match('Banana Shake')?.id,
        equals('food_banana_shake'),
      );
      expect(LocalFoodMatcher.match('Bread')?.id, equals('food_bread'));
      expect(LocalFoodMatcher.match('Fruit Jam')?.id, equals('food_jam'));
      expect(LocalFoodMatcher.match('Amul Butter')?.id, equals('food_butter'));
      expect(LocalFoodMatcher.match('Biscuits')?.id, equals('food_biscuits'));

      // 4. Western / fast foods
      expect(LocalFoodMatcher.match('Pizza')?.id, equals('food_pizza'));
      expect(LocalFoodMatcher.match('Burger')?.id, equals('food_burger'));
      expect(
        LocalFoodMatcher.match('Grilled Sandwich')?.id,
        equals('food_sandwich'),
      );
      expect(LocalFoodMatcher.match('Pasta')?.id, equals('food_pasta'));
      expect(
        LocalFoodMatcher.match('French Fries')?.id,
        equals('food_french_fries'),
      );
      expect(
        LocalFoodMatcher.match('Hakka Noodles')?.id,
        equals('food_noodles'),
      );
      expect(
        LocalFoodMatcher.match('Fried Rice')?.id,
        equals('food_fried_rice'),
      );
      expect(LocalFoodMatcher.match('Steamed Momos')?.id, equals('food_momos'));
      expect(LocalFoodMatcher.match('Kathi Roll')?.id, equals('food_wrap'));
      expect(LocalFoodMatcher.match('Pancakes')?.id, equals('food_pancakes'));
      expect(LocalFoodMatcher.match('Oatmeal')?.id, equals('food_oatmeal'));
      expect(LocalFoodMatcher.match('Corn Flakes')?.id, equals('food_cereal'));

      // 5. Fruits
      expect(LocalFoodMatcher.match('Banana')?.id, equals('food_banana'));
      expect(LocalFoodMatcher.match('Apple')?.id, equals('food_apple'));
      expect(LocalFoodMatcher.match('Orange')?.id, equals('food_orange'));
      expect(LocalFoodMatcher.match('Mango')?.id, equals('food_mango'));
      expect(LocalFoodMatcher.match('Papaya')?.id, equals('food_papaya'));
      expect(LocalFoodMatcher.match('Guava')?.id, equals('food_guava'));
      expect(
        LocalFoodMatcher.match('Watermelon')?.id,
        equals('food_watermelon'),
      );
      expect(LocalFoodMatcher.match('Pineapple')?.id, equals('food_pineapple'));
      expect(LocalFoodMatcher.match('Grapes')?.id, equals('food_grapes'));
      expect(
        LocalFoodMatcher.match('Pomegranate')?.id,
        equals('food_pomegranate'),
      );
      expect(
        LocalFoodMatcher.match('Tender Coconut')?.id,
        equals('food_coconut'),
      );
      expect(LocalFoodMatcher.match('Pear')?.id, equals('food_pear'));

      // 6. Snacks
      expect(LocalFoodMatcher.match('Peanuts')?.id, equals('food_peanuts'));
      expect(
        LocalFoodMatcher.match('Roasted Chana')?.id,
        equals('food_roasted_chana'),
      );
      expect(LocalFoodMatcher.match('Cashews')?.id, equals('food_cashews'));
      expect(LocalFoodMatcher.match('Almonds')?.id, equals('food_almonds'));
      expect(LocalFoodMatcher.match('Walnuts')?.id, equals('food_walnuts'));
      expect(
        LocalFoodMatcher.match('Protein Bar')?.id,
        equals('food_protein_bar'),
      );
      expect(LocalFoodMatcher.match('Potato Chips')?.id, equals('food_chips'));
      expect(LocalFoodMatcher.match('Samosa')?.id, equals('food_samosa'));
      expect(LocalFoodMatcher.match('Singara')?.id, equals('food_samosa'));
      expect(LocalFoodMatcher.match('Pakora')?.id, equals('food_pakora'));
      expect(LocalFoodMatcher.match('Alu Chop')?.id, equals('food_alu_chop'));
      expect(LocalFoodMatcher.match('Namkeen')?.id, equals('food_namkeen'));
      expect(LocalFoodMatcher.match('Popcorn')?.id, equals('food_popcorn'));

      // 7. Protein & nutrition
      expect(LocalFoodMatcher.match('Tofu')?.id, equals('food_tofu'));
      expect(LocalFoodMatcher.match('Chickpeas')?.id, equals('food_chana'));
      expect(
        LocalFoodMatcher.match('Peanut Butter')?.id,
        equals('food_peanut_butter'),
      );
      expect(
        LocalFoodMatcher.match('Whey Protein Shake')?.id,
        equals('food_whey_protein'),
      );
    });

    test('2. GeminiVisionService unconfigured mode gracefully falls back', () {
      const service = GeminiVisionService(apiKey: '');
      expect(service.isConfigured, isFalse);
      expect(service.modelName, equals('gemini-3.5-flash-lite'));
    });

    test('3. FoodRecognitionService produces multi-item meal detection (Rice, Dal, Chicken Curry)', () async {
      const recognitionService = FoodRecognitionService(
        simulatedDelay: Duration.zero,
      );

      final result = await recognitionService.analyzeImage('/test/meal.jpg');

      expect(result.detectedLabel, equals('Chicken Curry'));
      expect(result.matchedFoodItem, isNotNull);
      expect(result.matchedFoodItem!.id, equals('food_chicken'));
      expect(result.hasMatchedFoodItem, isTrue);

      // Verify multi-item detection
      expect(result.detectedItems.length, equals(3));
      expect(result.detectedItems[0].label, equals('Chicken Curry'));
      expect(
        result.detectedItems[0].matchedFoodItem?.id,
        equals('food_chicken'),
      );

      expect(result.detectedItems[1].label, equals('Rice'));
      expect(result.detectedItems[1].matchedFoodItem?.id, equals('food_rice'));

      expect(result.detectedItems[2].label, equals('Dal'));
      expect(result.detectedItems[2].matchedFoodItem?.id, equals('food_dal'));
    });

    test('4. copyWithSelectedPrimary allows seamlessly switching active dish on plate', () {
      final chicken = LocalFoodDatabase.getFoodById('food_chicken');
      final rice = LocalFoodDatabase.getFoodById('food_rice');

      final initial = FoodRecognitionResult(
        detectedLabel: 'Chicken Curry',
        confidence: 0.94,
        matchedFoodItem: chicken,
        detectedItems: [
          DetectedPlateItem(
            label: 'Chicken Curry',
            confidence: 0.94,
            matchedFoodItem: chicken,
          ),
          DetectedPlateItem(
            label: 'Rice',
            confidence: 0.91,
            matchedFoodItem: rice,
          ),
        ],
        analyzedAt: DateTime.now(),
      );

      expect(initial.detectedLabel, equals('Chicken Curry'));
      expect(initial.matchedFoodItem?.id, equals('food_chicken'));

      // Switch to Rice
      final switched = initial.copyWithSelectedPrimary(
        initial.detectedItems[1],
      );
      expect(switched.detectedLabel, equals('Rice'));
      expect(switched.matchedFoodItem?.id, equals('food_rice'));
      expect(switched.confidence, equals(0.91));
    });
  });

  group('Multi-Item Meal Review UI Tests', () {
    testWidgets(
      'FoodScanReviewScreen displays plate dish switcher and updates active food',
      (WidgetTester tester) async {
        final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;
        final rice = LocalFoodDatabase.getFoodById('food_rice')!;

        final multiItemResult = FoodRecognitionResult(
          detectedLabel: 'Chicken Curry',
          confidence: 0.94,
          matchedFoodItem: chicken,
          detectedItems: [
            DetectedPlateItem(
              label: 'Chicken Curry',
              confidence: 0.94,
              matchedFoodItem: chicken,
            ),
            DetectedPlateItem(
              label: 'Rice',
              confidence: 0.91,
              matchedFoodItem: rice,
            ),
          ],
          analyzedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(home: FoodScanReviewScreen(scanResult: multiItemResult)),
        );
        await tester.pumpAndSettle();

        // Initially shows Chicken Curry base calories: 245 kcal
        expect(find.text('245 kcal'), findsOneWidget);

        // Tap 'Rice' chip in plate items switcher
        await tester.tap(find.text('Rice'));
        await tester.pumpAndSettle();

        // Active food updates to Rice (195 kcal baseline)
        expect(find.text('195 kcal'), findsOneWidget);
      },
    );
  });
}
