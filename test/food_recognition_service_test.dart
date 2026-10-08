import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/food_recognition_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/food_item.dart';

void main() {
  group('FoodRecognitionService Tests', () {
    late FoodRecognitionService service;

    setUp(() {
      service = const FoodRecognitionService(simulatedDelay: Duration.zero);
    });

    test('mock recognition returns a valid FoodRecognitionResult', () async {
      final result = await service.analyzeImage('/path/to/mock_plate.jpg');

      expect(result, isNotNull);
      expect(result.detectedLabel, equals('Chicken Curry'));
      expect(result.confidence, equals(0.91));
      expect(result.confidencePercentage, equals('91%'));
      expect(result.imagePath, equals('/path/to/mock_plate.jpg'));
      expect(result.candidateLabels, contains('Chicken Curry'));
      expect(result.analyzedAt, isNotNull);
    });

    test('returned FoodItem exists in LocalFoodDatabase', () async {
      final result = await service.analyzeImage('/test/image.jpg');

      // 1. Result must have a matched local FoodItem
      expect(result.hasMatchedFoodItem, isTrue);
      expect(result.matchedFoodItem, isNotNull);

      final FoodItem item = result.matchedFoodItem!;

      // 2. ID must match the verified local database entry
      expect(item.id, equals('food_chicken'));

      // 3. Must be identical to what LocalFoodDatabase returns
      final databaseItem = LocalFoodDatabase.getFoodById('food_chicken');
      expect(databaseItem, isNotNull);
      expect(item.id, equals(databaseItem!.id));
      expect(item.name, equals(databaseItem.name));
      expect(item.servingSize, equals(databaseItem.servingSize));
    });

    test(
      'no nutrition values are invented by the recognition service',
      () async {
        final result = await service.analyzeImage('/test/image.jpg');
        final databaseItem = LocalFoodDatabase.getFoodById('food_chicken')!;

        // Nutrition values must come strictly from the verified database entry
        expect(result.matchedFoodItem!.calories, equals(databaseItem.calories));
        expect(result.matchedFoodItem!.protein, equals(databaseItem.protein));
        expect(
          result.matchedFoodItem!.carbohydrates,
          equals(databaseItem.carbohydrates),
        );
        expect(result.matchedFoodItem!.fats, equals(databaseItem.fats));

        // Exact verified values in LocalFoodDatabase: 245.0 kcal, 31.0g protein, 4.0g carbs, 11.5g fats
        expect(result.matchedFoodItem!.calories, equals(245.0));
        expect(result.matchedFoodItem!.protein, equals(31.0));
        expect(result.matchedFoodItem!.carbohydrates, equals(4.0));
        expect(result.matchedFoodItem!.fats, equals(11.5));
      },
    );

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
