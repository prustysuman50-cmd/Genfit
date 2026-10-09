import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/food_recognition_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/food_item.dart';

void main() {
  group('FoodRecognitionService Tests', () {
    late FoodRecognitionService offlineService;

    setUp(() {
      offlineService = const FoodRecognitionService(
        simulatedDelay: Duration.zero,
      );
    });

    test(
      'default offline mode returns honest unselected result with NO hardcoded Chicken Curry',
      () async {
        final result = await offlineService.analyzeImage('/path/to/mock_plate.jpg');

        expect(result, isNotNull);
        expect(result.detectedLabel, isNot(equals('Chicken Curry')));
        expect(result.detectedLabel, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.confidencePercentage, equals('0%'));
        expect(result.matchedFoodItem, isNull);
        expect(result.hasMatchedFoodItem, isFalse);
        expect(result.isLiveAi, isFalse);
        expect(result.isOfflineFallback, isTrue);
        expect(result.imagePath, equals('/path/to/mock_plate.jpg'));
      },
    );

    test(
      'two different selected images do not produce hardcoded Chicken Curry results',
      () async {
        final appleScan = await offlineService.analyzeImage('/test/apple.jpg');
        final riceScan = await offlineService.analyzeImage('/test/rice.jpg');

        // Neither image should be silently forced to Chicken Curry
        expect(appleScan.detectedLabel, isNot(equals('Chicken Curry')));
        expect(riceScan.detectedLabel, isNot(equals('Chicken Curry')));
        expect(appleScan.matchedFoodItem, isNull);
        expect(riceScan.matchedFoodItem, isNull);
        expect(appleScan.hasMatchedFoodItem, isFalse);
        expect(riceScan.hasMatchedFoodItem, isFalse);
      },
    );

    test('explicit mock fallback mode produces simulated thali for tests', () async {
      const mockService = FoodRecognitionService(
        simulatedDelay: Duration.zero,
        enableMockFallback: true,
      );

      final result = await mockService.analyzeImage('/test/image.jpg');

      expect(result.hasMatchedFoodItem, isTrue);
      expect(result.matchedFoodItem, isNotNull);

      final FoodItem item = result.matchedFoodItem!;
      expect(item.id, equals('food_chicken'));

      final databaseItem = LocalFoodDatabase.getFoodById('food_chicken')!;
      expect(item.calories, equals(databaseItem.calories));
      expect(item.protein, equals(databaseItem.protein));
      expect(item.carbohydrates, equals(databaseItem.carbohydrates));
      expect(item.fats, equals(databaseItem.fats));
    });

    test(
      'supports custom mock configurations for testing and simulation',
      () async {
        const customService = FoodRecognitionService(
          defaultMockFoodId: 'food_dalma',
          defaultMockLabel: 'Dalma',
          defaultMockConfidence: 0.88,
          simulatedDelay: Duration.zero,
        );

        final result = await customService.analyzeImage('/test/dalma.jpg');

        expect(result.detectedLabel, equals('Dalma'));
        expect(result.confidence, equals(0.88));
        expect(result.confidencePercentage, equals('88%'));
        expect(result.matchedFoodItem?.id, equals('food_dalma'));
        expect(
          result.matchedFoodItem?.name,
          equals('Dalma (Odia Lentil & Veggie Stew)'),
        );
      },
    );
  });
}
