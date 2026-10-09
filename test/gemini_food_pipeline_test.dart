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

    test('2b. LocalFoodMatcher never defaults generic words like curry to Chicken Curry', () {
      // Generic descriptors must return null, NOT food_chicken
      expect(LocalFoodMatcher.match('curry'), isNull);
      expect(LocalFoodMatcher.match('Curry'), isNull);
      expect(LocalFoodMatcher.match('gravy'), isNull);
      expect(LocalFoodMatcher.match('dish'), isNull);
      expect(LocalFoodMatcher.match('Indian Curry'), isNull);

      // Legitimate curries must resolve to their correct specific foods
      expect(LocalFoodMatcher.match('Chicken Curry')?.id, equals('food_chicken'));
      expect(LocalFoodMatcher.match('Veg Curry')?.id, equals('food_vegetables'));
      expect(LocalFoodMatcher.match('Vegetable Curry')?.id, equals('food_vegetables'));
      expect(LocalFoodMatcher.match('Egg Curry')?.id, equals('food_egg_curry'));
      expect(LocalFoodMatcher.match('Paneer Curry')?.id, equals('food_paneer'));
      expect(LocalFoodMatcher.match('Fish Curry')?.id, equals('food_fish'));
      expect(LocalFoodMatcher.match('Potato Curry')?.id, equals('food_potato_curry'));
      expect(LocalFoodMatcher.match('Mushroom Curry')?.id, equals('food_mushroom_curry'));
    });

    test('3. FoodRecognitionService produces multi-item meal detection (Rice, Dal, Chicken Curry) in mock mode', () async {
      const recognitionService = FoodRecognitionService(
        simulatedDelay: Duration.zero,
        enableMockFallback: true,
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

    test('3b. FoodRecognitionService default offline mode does not hallucinate Chicken Curry', () async {
      const recognitionService = FoodRecognitionService(
        simulatedDelay: Duration.zero,
      );

      final result = await recognitionService.analyzeImage('/test/unrecognized.jpg');

      expect(result.detectedLabel, isNot(equals('Chicken Curry')));
      expect(result.detectedLabel, isEmpty);
      expect(result.matchedFoodItem, isNull);
      expect(result.hasMatchedFoodItem, isFalse);
      expect(result.isLiveAi, isFalse);
      expect(result.isOfflineFallback, isTrue);
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

    test('5. GeminiVisionService key configuration, precedence, and sanitization', () {
      // Strips accidental quotes and whitespace
      expect(GeminiVisionService.sanitizeApiKey('  "mock_test_key_123"  '), equals('mock_test_key_123'));
      expect(GeminiVisionService.sanitizeApiKey("  'mock_test_key_456'  "), equals('mock_test_key_456'));
      expect(GeminiVisionService.sanitizeApiKey('mock_plain_key'), equals('mock_plain_key'));

      // Runtime key precedence over compile-time define
      const service = GeminiVisionService(apiKey: 'base_key');
      expect(service.effectiveApiKey, equals('base_key'));
      expect(service.isConfigured, isTrue);

      GeminiVisionService.runtimeApiKey = 'runtime_override_key';
      expect(service.effectiveApiKey, equals('runtime_override_key'));

      // Reset
      GeminiVisionService.runtimeApiKey = null;
      expect(service.effectiveApiKey, equals('base_key'));
    });

    test('6. GeminiVisionService error categorization and secret masking', () {
      const model = 'gemini-3.5-flash-lite';
      const key = 'test_mock_secret_key_999';

      // 401 / 403 Invalid API key
      final err401 = GeminiVisionService.categorizeError(
        'GenerativeAIException: [403 Forbidden] API_KEY_INVALID: key is not valid',
        model,
        key,
      );
      expect(err401, contains('HTTP 401/403'));
      expect(err401, isNot(contains(key)));

      // 404 Model Not Found
      final err404 = GeminiVisionService.categorizeError(
        'GenerativeAIException: [404 Not Found] models/gemini-1.5-flash not found',
        'gemini-1.5-flash',
        key,
      );
      expect(err404, contains('HTTP 404'));
      expect(err404, contains('gemini-1.5-flash'));

      // 429 Rate Limit / Quota
      final err429 = GeminiVisionService.categorizeError(
        'GenerativeAIException: [429 Too Many Requests] RESOURCE_EXHAUSTED',
        model,
        key,
      );
      expect(err429, contains('HTTP 429'));

      // 400 Bad Request
      final err400 = GeminiVisionService.categorizeError(
        'GenerativeAIException: [400 Bad Request] INVALID_ARGUMENT',
        model,
        key,
      );
      expect(err400, contains('HTTP 400'));

      // Network / Connectivity
      final netErr = GeminiVisionService.categorizeError(
        'SocketException: Failed host lookup: generativelanguage.googleapis.com',
        model,
        key,
      );
      expect(netErr, contains('Network error'));

      // Timeout
      final timeoutErr = GeminiVisionService.categorizeError(
        'TimeoutException after 0:00:18.000000: Future not completed',
        model,
        key,
      );
      expect(timeoutErr, contains('Network timeout'));
      expect(timeoutErr, contains('select manually'));

      // General error with sensitive token redacted
      final genErr = GeminiVisionService.categorizeError(
        'Something broke with key $key and key=test_mock_secret_key_999',
        model,
        key,
      );
      expect(genErr, isNot(contains(key)));
      expect(genErr, contains('[REDACTED_KEY]'));
    });

    test('7. GeminiVisionService response parsing (strict JSON, markdown blocks, conversational preambles)', () {
      const service = GeminiVisionService();

      // Markdown fenced JSON
      const markdownJson = '''
```json
{
  "items": [
    {
      "name": "Dalma",
      "confidence": 0.94
    },
    {
      "name": "Steamed Rice",
      "confidence": 0.92
    }
  ]
}
```
''';
      final parsed = service.parseGeminiResponse(markdownJson, '/test/photo.jpg');
      expect(parsed, isNotNull);
      expect(parsed!.detectedLabel, equals('Dalma'));
      expect(parsed.matchedFoodItem?.id, equals('food_dalma'));
      expect(parsed.detectedItems.length, equals(2));
      expect(parsed.detectedItems[1].matchedFoodItem?.id, equals('food_rice'));

      // Conversational preamble and postamble around raw JSON
      const conversationalJson = '''
Here is the nutrition analysis for your hostel plate:
{
  "items": [
    {
      "name": "Pakhala",
      "confidence": 0.96
    }
  ]
}
Enjoy your meal!
''';
      final parsedConv = service.parseGeminiResponse(conversationalJson, '/test/photo.jpg');
      expect(parsedConv, isNotNull);
      expect(parsedConv!.detectedLabel, equals('Pakhala'));
      expect(parsedConv.matchedFoodItem?.id, equals('food_pakhala'));

      // Single item object without "items" key
      const singleItemJson = '{"name": "Roti", "confidence": 0.91}';
      final parsedSingle = service.parseGeminiResponse(singleItemJson, '/test/photo.jpg');
      expect(parsedSingle, isNotNull);
      expect(parsedSingle!.detectedLabel, equals('Roti'));
      expect(parsedSingle.matchedFoodItem?.id, equals('food_roti'));

      // Multi-item where 1st is unrecognised, but 2nd matches verified database
      const mixedItemsJson = '''
{
  "items": [
    {
      "name": "Exotic Garnish Salad Bowl",
      "confidence": 0.99
    },
    {
      "name": "Chicken Curry",
      "confidence": 0.88
    }
  ]
}
''';
      final parsedMixed = service.parseGeminiResponse(mixedItemsJson, '/test/photo.jpg');
      expect(parsedMixed, isNotNull);
      // Prefers the verified local database match as primary
      expect(parsedMixed!.detectedLabel, equals('Chicken Curry'));
      expect(parsedMixed.matchedFoodItem?.id, equals('food_chicken'));
      expect(parsedMixed.detectedItems.length, equals(2));

      // Empty items list produces informative diagnostic error
      expect(service.parseGeminiResponse('{"items": []}', '/test/photo.jpg'), isNull);
      expect(
        GeminiVisionService.lastApiError,
        contains('No food items detected in the image'),
      );

      // Empty or invalid JSON returns null safely
      expect(service.parseGeminiResponse('', '/test/photo.jpg'), isNull);
      expect(service.parseGeminiResponse('not a json', '/test/photo.jpg'), isNull);
    });

    test('8. FoodRecognitionResult copyWithManualFood cleanly switches food item', () {
      final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;
      final dalma = LocalFoodDatabase.getFoodById('food_dalma')!;

      final initial = FoodRecognitionResult(
        detectedLabel: 'Chicken Curry',
        confidence: 0.95,
        matchedFoodItem: chicken,
        analyzedAt: DateTime.now(),
        isLiveAi: true,
      );

      final manualUpdated = initial.copyWithManualFood(dalma);
      expect(manualUpdated.detectedLabel, equals(dalma.name));
      expect(manualUpdated.matchedFoodItem?.id, equals('food_dalma'));
      expect(manualUpdated.confidence, equals(1.0));
      expect(manualUpdated.isLiveAi, isTrue);
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

    testWidgets(
      'FoodScanReviewScreen opens change dish sheet and updates selected food',
      (WidgetTester tester) async {
        final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;

        final scanResult = FoodRecognitionResult(
          detectedLabel: 'Chicken Curry',
          confidence: 0.94,
          matchedFoodItem: chicken,
          analyzedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(home: FoodScanReviewScreen(scanResult: scanResult)),
        );
        await tester.pumpAndSettle();

        // Initially shows 245 kcal
        expect(find.text('245 kcal'), findsOneWidget);

        // Tap 'Change dish'
        final changeDishBtn = find.text('Change dish');
        expect(changeDishBtn, findsOneWidget);
        await tester.tap(changeDishBtn);
        await tester.pumpAndSettle();

        // Sheet opens
        expect(find.text('Select Dish from 101 Foods'), findsOneWidget);

        // Tap 'Pakhala' ListTile in the sheet list
        final pakhalaTile =
            find.widgetWithText(ListTile, 'Pakhala (Fermented Curd Rice)');
        expect(pakhalaTile, findsOneWidget);
        await tester.ensureVisible(pakhalaTile);
        await tester.tap(pakhalaTile);
        await tester.pumpAndSettle();

        // Sheet closed and preview is updated to Pakhala (210 kcal)
        expect(find.text('Select Dish from 101 Foods'), findsNothing);
        expect(find.text('210 kcal'), findsOneWidget);
      },
    );
  });
}
