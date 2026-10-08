import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/journey_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/progress_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/meal_category.dart';
import 'package:genfit/screens/progress/progress_screen.dart';

void main() {
  group('GenFit Phase 1 Step 6: Progress Screen -> DailyStats Integration Tests', () {
    late Directory tempDir;
    final dailyStats = DailyStatsService.instance;
    final progressService = ProgressService.instance;
    final gamification = GamificationService.instance;
    final nutrition = NutritionService.instance;
    final journey = JourneyService.instance;
    final user = UserService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync(
        'progress_daily_stats_test_',
      );
      dailyStats.setCustomStoragePath(tempDir.path);
      progressService.setCustomStoragePath(tempDir.path);
      gamification.setCustomStoragePath(tempDir.path);
      nutrition.setCustomStoragePath(tempDir.path);
      journey.setCustomStoragePath(tempDir.path);
      user.setCustomStoragePath(tempDir.path);

      await dailyStats.resetToDefaults();
      await progressService.resetToDefaults();
      await gamification.resetToDefaults();
      await nutrition.resetToDefaults();
      await journey.resetToDefaults();
      await user.resetToDefaults();
    });

    tearDown(() {
      try {
        dailyStats.detachNutritionListener();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    Widget buildProgressApp() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ProgressScreen(),
      );
    }

    test('1. Empty/fresh state does NOT produce fake populated data', () {
      final summary = progressService.getSummary();

      expect(summary.workoutsCompleted, equals(0));
      expect(summary.totalReps, equals(0));
      expect(
        summary.steps,
        equals(0),
        reason: 'Must not use fake 6450 fallback',
      );
      expect(
        summary.activeCalories,
        equals(0),
        reason: 'Must not use synthetic calorie formula',
      );
      expect(
        summary.activeMinutes,
        equals(0),
        reason: 'Must not use synthetic 35 or 25 min fallback',
      );
      expect(summary.waterMl, equals(0));
      expect(summary.nutritionMealsLogged, equals(0));

      final weekly = progressService.getWeeklyActivity();
      expect(weekly.length, equals(7));
      for (final day in weekly) {
        expect(day.steps, equals(0));
        expect(day.calories, equals(0));
        expect(day.activeMinutes, equals(0));
        expect(day.workouts, equals(0));
        expect(day.waterMl, equals(0));
      }
    });

    test('2. Progress reads today DailyStats telemetry correctly', () async {
      await dailyStats.updateActivity(
        steps: 5400,
        activeMinutes: 40,
        caloriesBurned: 220,
      );
      await dailyStats.addWater(750);

      final summary = progressService.getSummary();
      expect(summary.steps, equals(5400));
      expect(summary.activeMinutes, equals(40));
      expect(summary.activeCalories, equals(220));
      expect(summary.waterMl, equals(750));

      final today = summary.weeklyActivity.firstWhere((d) => d.isToday);
      expect(today.steps, equals(5400));
      expect(today.activeMinutes, equals(40));
      expect(today.calories, equals(220));
      expect(today.waterMl, equals(750));
    });

    test('3. Steps are reflected correctly from DailyStatsService', () async {
      await dailyStats.addSteps(3200);

      var summary = progressService.getSummary();
      expect(summary.steps, equals(3200));

      await dailyStats.addSteps(1800);
      summary = progressService.getSummary();
      expect(summary.steps, equals(5000));
    });

    test('4. Water is reflected correctly in Progress metrics', () async {
      await dailyStats.addWater(500);

      var summary = progressService.getSummary();
      expect(summary.waterMl, equals(500));

      final todayDay = summary.weeklyActivity.firstWhere((d) => d.isToday);
      expect(todayDay.waterMl, equals(500));

      await dailyStats.addWater(250);
      summary = progressService.getSummary();
      expect(summary.waterMl, equals(750));
    });

    test(
      '5. Calories burned are reflected correctly without synthetic formulas',
      () async {
        await dailyStats.addCaloriesBurned(340);

        final summary = progressService.getSummary();
        expect(summary.activeCalories, equals(340));

        final today = summary.weeklyActivity.firstWhere((d) => d.isToday);
        expect(today.calories, equals(340));
      },
    );

    test(
      '6. Nutrition metrics are reflected where the Progress UI displays them',
      () async {
        final dalma = LocalFoodDatabase.getFoodById('food_dalma');
        expect(dalma, isNotNull);

        await nutrition.logFood(
          food: dalma!,
          category: MealCategory.lunch,
          servings: 1.0,
        );

        final summary = progressService.getSummary();
        expect(summary.nutritionMealsLogged, equals(1));
      },
    );

    test('7. Workout telemetry is reflected from DailyStatsService', () async {
      await dailyStats.recordWorkoutCompleted(
        durationMinutes: 25,
        totalReps: 40,
        caloriesBurned: 160,
      );

      final summary = progressService.getSummary();
      expect(summary.workoutsCompleted, equals(1));
      expect(summary.totalReps, equals(40));
      expect(summary.activeMinutes, equals(25));
      expect(summary.activeCalories, equals(160));

      final today = summary.weeklyActivity.firstWhere((d) => d.isToday);
      expect(today.workouts, equals(1));
      expect(today.activeMinutes, equals(25));
      expect(today.calories, equals(160));
    });

    test(
      '8. Persisted historical DailyStats can be read without synthetic data',
      () async {
        final now = DateTime.now();
        // Pick yesterday if today is not Monday; otherwise pick tomorrow's weekday or reference date
        final yesterday = now.subtract(const Duration(days: 1));

        // Record activity specifically for yesterday
        await dailyStats.updateActivity(
          steps: 6100,
          activeMinutes: 45,
          caloriesBurned: 275,
          date: yesterday,
        );

        final weekly = progressService.getWeeklyActivity(referenceDate: now);

        // Verify yesterday's slot if within the current calendar week
        if (now.weekday > 1) {
          final yesterdaySummary = weekly[now.weekday - 2];
          expect(yesterdaySummary.steps, equals(6100));
          expect(yesterdaySummary.activeMinutes, equals(45));
          expect(yesterdaySummary.calories, equals(275));
        }

        // Check that unrecorded days in the week remain 0
        final unrecorded = weekly.where((d) => !d.isToday && d.steps == 0);
        expect(unrecorded.isNotEmpty, isTrue);
        for (final day in unrecorded) {
          expect(day.steps, equals(0));
          expect(day.activeMinutes, equals(0));
          expect(day.calories, equals(0));
        }
      },
    );

    test('9. Date isolation is strictly preserved', () async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      await dailyStats.updateActivity(
        steps: 4000,
        activeMinutes: 30,
        caloriesBurned: 200,
        date: now,
      );

      final todayStats = dailyStats.getStatsForDate(now);
      final tomorrowStats = dailyStats.getStatsForDate(tomorrow);

      expect(todayStats.steps, equals(4000));
      expect(tomorrowStats.steps, equals(0));
      expect(tomorrowStats.activeMinutes, equals(0));
      expect(tomorrowStats.caloriesBurned, equals(0));
    });

    testWidgets(
      '10. ProgressScreen displays real empty data without fake 72% radial',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildProgressApp());
        await tester.pumpAndSettle();

        // Fresh state should display 0% COMPLETED (not fake 72%)
        expect(find.text('0%'), findsOneWidget);
        expect(find.text('72%'), findsNothing);
        expect(find.text('Keep pushing daily!'), findsOneWidget);

        // Weekly Overview cards should show 0 for fresh state
        expect(
          find.text('0'),
          findsWidgets,
        ); // Workouts, Active Calories, Active Minutes
      },
    );

    testWidgets(
      '11. ProgressScreen reactively updates when DailyStatsService changes',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildProgressApp());
        await tester.pumpAndSettle();

        expect(find.text('0%'), findsOneWidget);

        // Now add real activity to DailyStatsService
        await dailyStats.updateActivity(
          steps: 7500,
          activeMinutes: 50,
          caloriesBurned: 350,
        );

        // Pump to trigger ListenableBuilder
        await tester.pumpAndSettle();

        // Active days is now 1 of 7 = 14%
        expect(find.text('14%'), findsOneWidget);
        expect(find.text('7.5k'), findsOneWidget);
        expect(find.text('350'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
      },
    );

    test('12. ProgressService.recordDailyTelemetry delegates directly to DailyStatsService without duplicate storage', () async {
      final now = DateTime.now();
      await progressService.recordDailyTelemetry(
        date: now,
        steps: 4200,
        activeMinutes: 35,
        calories: 190,
        workouts: 1,
      );

      // Authoritative DailyStatsService should now hold the data
      final todayStats = dailyStats.getStatsForDate(now);
      expect(todayStats.steps, equals(4200));
      expect(todayStats.activeMinutes, equals(35));
      expect(todayStats.caloriesBurned, equals(190));
      expect(todayStats.workoutsCompleted, equals(1));

      // And ProgressService reflects it via DailyStatsService
      final summary = progressService.getSummary();
      expect(summary.steps, equals(4200));
      expect(summary.activeMinutes, equals(35));
      expect(summary.activeCalories, equals(190));
      expect(summary.workoutsCompleted, equals(1));
    });

    test('13. DailyStatsService remains the authoritative sole source across reload', () async {
      final now = DateTime.now();
      await dailyStats.updateActivity(
        steps: 8000,
        activeMinutes: 60,
        caloriesBurned: 400,
        date: now,
      );

      // Re-initialize ProgressService
      await progressService.init();

      final summary = progressService.getSummary();
      expect(summary.steps, equals(8000));
      expect(summary.activeMinutes, equals(60));
      expect(summary.activeCalories, equals(400));
    });
  });
}
