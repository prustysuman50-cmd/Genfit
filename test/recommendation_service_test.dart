import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/journey_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/recommendation_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/meal_category.dart';

void main() {
  group('RecommendationService Adaptive Rules Tests', () {
    late Directory tempDir;
    final recommendationService = RecommendationService.instance;
    final userService = UserService.instance;
    final gamificationService = GamificationService.instance;
    final nutritionService = NutritionService.instance;
    final journeyService = JourneyService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('rec_test_');
      userService.setCustomStoragePath(tempDir.path);
      gamificationService.setCustomStoragePath(tempDir.path);
      nutritionService.setCustomStoragePath(tempDir.path);
      journeyService.setCustomStoragePath(tempDir.path);

      await userService.resetToDefaults();
      await gamificationService.resetToDefaults();
      await nutritionService.resetToDefaults();
      await journeyService.resetToDefaults();
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test(
      'Rule 1: Recommends short workout when consistency is low or streak is 0',
      () {
        final recs = recommendationService.getRecommendations();

        final consistencyRec = recs
            .where((r) => r.category == 'Consistency')
            .toList();
        expect(consistencyRec, isNotEmpty);
        expect(consistencyRec.first.message, contains('10-minute workout'));
        expect(consistencyRec.first.actionLabel, equals('Start Workout'));
      },
    );

    test(
      'Rule 2: Recommends streak continuation when streak is high',
      () async {
        // Advance streak to 5 days
        for (int i = 0; i < 5; i++) {
          final day = DateTime.now().subtract(Duration(days: 4 - i));
          gamificationService.recordActivity(atDate: day);
        }
        expect(gamificationService.streakDays, greaterThanOrEqualTo(5));

        final recs = recommendationService.getRecommendations();
        final streakRec = recs.where((r) => r.category == 'Streak').toList();

        expect(streakRec, isNotEmpty);
        expect(streakRec.first.title, contains('Streak'));
        expect(streakRec.first.message, contains('streak going'));
      },
    );

    test(
      'Rule 3: Recommends mess meal logging when no meals have been tracked',
      () {
        final recs = recommendationService.getRecommendations();
        final nutritionRec = recs
            .where((r) => r.category == 'Nutrition')
            .toList();

        expect(nutritionRec, isNotEmpty);
        expect(
          nutritionRec.first.message,
          contains('Log your next hostel/mess meal'),
        );
      },
    );

    test('Rule 4: Recommends veg protein sources for vegetarian users below protein target', () async {
      await userService.updateFields(dietPreference: 'Vegetarian');

      // Log a low protein meal (e.g. white rice only)
      final rice = LocalFoodDatabase.getFoodById('food_rice');
      expect(rice, isNotNull);
      await nutritionService.logFood(
        food: rice!,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      final recs = recommendationService.getRecommendations();
      final proteinRec = recs
          .where((r) => r.id == 'rec_protein_target')
          .toList();

      expect(proteinRec, isNotEmpty);
      expect(proteinRec.first.message, contains('dalma'));
      expect(proteinRec.first.message, contains('paneer'));
      expect(
        proteinRec.first.message,
        isNot(contains('eggs')),
      ); // No eggs for veg
    });

    test('Rule 4: Recommends general protein sources for non-vegetarian users below protein target', () async {
      await userService.updateFields(dietPreference: 'Non-Vegetarian');

      // Log a low protein meal (e.g. white rice only)
      final rice = LocalFoodDatabase.getFoodById('food_rice');
      expect(rice, isNotNull);
      await nutritionService.logFood(
        food: rice!,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      final recs = recommendationService.getRecommendations();
      final proteinRec = recs
          .where((r) => r.id == 'rec_protein_target')
          .toList();

      expect(proteinRec, isNotEmpty);
      expect(proteinRec.first.message, contains('eggs'));
    });

    test(
      'Rule 5: Tailors recommendations to user fitness goal (Build Muscle)',
      () async {
        await userService.updateFields(fitnessGoal: 'Build Muscle');
        await gamificationService.recordWorkoutCompleted(reps: 15);

        final recs = recommendationService.getRecommendations();
        final workoutRec = recs.where((r) => r.category == 'Workout').toList();

        expect(workoutRec, isNotEmpty);
        expect(workoutRec.any((r) => r.message.contains('muscle')), isTrue);
      },
    );

    test(
      'Rule 6: Encourages Odisha Journey advancement when progress is early',
      () {
        final recs = recommendationService.getRecommendations();
        final journeyRec = recs.where((r) => r.category == 'Journey').toList();

        expect(journeyRec, isNotEmpty);
        expect(journeyRec.first.message, contains('Odisha Journey'));
        expect(journeyRec.first.actionLabel, equals('View Odisha Trail'));
      },
    );

    test('Recommendations are explainable and include required fields', () {
      final rec = recommendationService.getPrimaryRecommendation();

      expect(rec.title, isNotEmpty);
      expect(rec.message, isNotEmpty);
      expect(rec.category, isNotEmpty);
      expect(rec.priority, greaterThan(0));
    });
  });
}
