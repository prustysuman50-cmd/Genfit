import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/journey_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/progress_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/meal_category.dart';

void main() {
  group('ProgressService & ProgressSummary Tests', () {
    late Directory tempDir;
    final progressService = ProgressService.instance;
    final dailyStatsService = DailyStatsService.instance;
    final gamificationService = GamificationService.instance;
    final nutritionService = NutritionService.instance;
    final journeyService = JourneyService.instance;
    final userService = UserService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('progress_service_test_');
      dailyStatsService.setCustomStoragePath(tempDir.path);
      progressService.setCustomStoragePath(tempDir.path);
      gamificationService.setCustomStoragePath(tempDir.path);
      nutritionService.setCustomStoragePath(tempDir.path);
      journeyService.setCustomStoragePath(tempDir.path);
      userService.setCustomStoragePath(tempDir.path);

      await dailyStatsService.resetToDefaults();
      await progressService.resetToDefaults();
      await gamificationService.resetToDefaults();
      await nutritionService.resetToDefaults();
      await journeyService.resetToDefaults();
      await userService.resetToDefaults();
    });

    tearDown(() {
      try {
        dailyStatsService.detachNutritionListener();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Empty / default state provides sensible initial metrics', () {
      final summary = progressService.getSummary();

      expect(summary.workoutsCompleted, equals(0));
      expect(summary.totalReps, equals(0));
      expect(summary.currentStreak, equals(0));
      expect(summary.xp, equals(0));
      expect(summary.level, equals(1));
      expect(summary.journeyProgressKm, equals(0.0));
      expect(summary.badgesUnlocked, equals(0));
      expect(summary.weeklyActivity.length, equals(7));
    });

    test('Weekly activity data: provides Mon-Sun without fabricated historical records', () {
      final weekly = progressService.getWeeklyActivity();

      expect(weekly.length, equals(7));
      expect(weekly[0].dayLabel, equals('Mon'));
      expect(weekly[1].dayLabel, equals('Tue'));
      expect(weekly[2].dayLabel, equals('Wed'));
      expect(weekly[3].dayLabel, equals('Thu'));
      expect(weekly[4].dayLabel, equals('Fri'));
      expect(weekly[5].dayLabel, equals('Sat'));
      expect(weekly[6].dayLabel, equals('Sun'));

      // Verify exactly one day is marked as today
      final todayDays = weekly.where((d) => d.isToday).toList();
      expect(todayDays.length, equals(1));

      // Check unrecorded past/future days do NOT fabricate artificial values
      final nonTodayDays = weekly.where((d) => !d.isToday).toList();
      for (final day in nonTodayDays) {
        expect(
          day.workouts,
          equals(0),
          reason: '${day.dayLabel} must not have fabricated workouts',
        );
        expect(
          day.steps,
          equals(0),
          reason: '${day.dayLabel} must not have fabricated steps',
        );
      }
    });

    test('Progress aggregation: aggregates data across workouts, nutrition, and journey', () async {
      // 1. Record workout in Gamification
      await gamificationService.recordWorkoutCompleted(reps: 25);

      // 2. Log meal in Nutrition
      final dalma = LocalFoodDatabase.getFoodById('food_dalma');
      expect(dalma, isNotNull);
      await nutritionService.logFood(
        food: dalma!,
        category: MealCategory.lunch,
        servings: 1.0,
      );

      // 3. Advance Odisha Journey
      await journeyService.addProgress(28.0);

      final summary = progressService.getSummary();

      expect(summary.workoutsCompleted, equals(1));
      expect(summary.totalReps, equals(25));
      expect(summary.nutritionMealsLogged, equals(1));
      expect(summary.journeyProgressKm, equals(28.0));
      expect(summary.xp, greaterThan(0));
      expect(summary.currentStreak, equals(1));
    });

    test(
      'Telemetry recording and persistence: records and reloads daily activity',
      () async {
        final now = DateTime.now();

        await progressService.recordDailyTelemetry(
          date: now,
          steps: 3200,
          activeMinutes: 28,
          calories: 140,
          workouts: 1,
        );

        final weekly = progressService.getWeeklyActivity();
        final today = weekly.firstWhere((d) => d.isToday);

        expect(today.steps, greaterThanOrEqualTo(3200));
        expect(today.activeMinutes, greaterThanOrEqualTo(28));
        expect(today.workouts, greaterThanOrEqualTo(1));

        // Reload service from file
        await progressService.init();
        final summaryAfterInit = progressService.getSummary();
        expect(summaryAfterInit.weeklyActivity.length, equals(7));
      },
    );

    test(
      'Recent activities: gathers chronological list of recent events',
      () async {
        await gamificationService.recordWorkoutCompleted(reps: 30);
        final rice = LocalFoodDatabase.getFoodById('food_rice');
        if (rice != null) {
          await nutritionService.logFood(
            food: rice,
            category: MealCategory.lunch,
            servings: 1.0,
          );
        }

        final recent = progressService.getRecentActivities();
        expect(recent.length, greaterThanOrEqualTo(2));
        expect(recent.any((a) => a['category'] == 'Workout'), isTrue);
        expect(recent.any((a) => a['category'] == 'Nutrition'), isTrue);
      },
    );
  });
}
