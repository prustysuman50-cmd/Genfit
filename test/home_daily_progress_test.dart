import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/step_tracking_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/daily_metric.dart';
import 'package:genfit/models/daily_stats.dart';
import 'package:genfit/models/nutrition/meal_category.dart';
import 'package:genfit/screens/home/home_screen.dart';
import 'package:genfit/screens/home/widgets/daily_progress_card.dart';

void main() {
  late Directory tempStatsDir;
  late Directory tempNutrDir;
  final statsService = DailyStatsService.instance;
  final nutritionService = NutritionService.instance;

  setUp(() async {
    tempStatsDir = Directory.systemTemp.createTempSync('home_stats_test_');
    tempNutrDir = Directory.systemTemp.createTempSync('home_nutr_test_');

    statsService.setCustomStoragePath(tempStatsDir.path);
    nutritionService.setCustomStoragePath(tempNutrDir.path);
    StepTrackingService.instance.setCustomStoragePath(tempStatsDir.path);
    StepTrackingService.instance.setPlatformSensorEnabled(false);

    await statsService.resetToDefaults();
    await nutritionService.resetToDefaults();
    await StepTrackingService.instance.resetToDefaults();
  });

  tearDown(() {
    statsService.detachNutritionListener();
    StepTrackingService.instance.setCustomStoragePath(null);
    try {
      if (tempStatsDir.existsSync()) {
        tempStatsDir.deleteSync(recursive: true);
      }
      if (tempNutrDir.existsSync()) {
        tempNutrDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Home Daily Progress -> DailyStats Integration Tests', () {
    testWidgets(
      '1. Fresh DailyStats values appear correctly in Home Daily Progress (0 steps, 0 ml water, 0 kcal, 0 min)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        final card = find.byType(DailyProgressCard);
        expect(card, findsOneWidget);

        // Must display real 0 values, NOT synthetic 7420 or 480 or 38
        expect(
          find.descendant(of: card, matching: find.text('0')),
          findsOneWidget,
        ); // 0 STEPS
        expect(
          find.descendant(of: card, matching: find.text('0 ml')),
          findsOneWidget,
        ); // 0 ml water
        expect(
          find.descendant(of: card, matching: find.text('0 kcal')),
          findsOneWidget,
        ); // 0 kcal burned
        expect(
          find.descendant(of: card, matching: find.text('0 min')),
          findsOneWidget,
        ); // 0 min active
        expect(
          find.descendant(of: card, matching: find.text('0% TARGET')),
          findsOneWidget,
        );

        // Explicitly verify old mock numbers do NOT appear in the UI
        expect(find.text('7420'), findsNothing);
        expect(find.text('480 kcal'), findsNothing);
        expect(find.text('38 min'), findsNothing);
      },
    );

    testWidgets('2. Water logging updates Home Daily Progress reactively', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      final card = find.byType(DailyProgressCard);
      expect(
        find.descendant(of: card, matching: find.text('0 ml')),
        findsOneWidget,
      );

      // Tap the + Log water button on the DailyProgressCard
      final waterLogButton = find.descendant(
        of: card,
        matching: find.text('+ Log'),
      );
      expect(waterLogButton, findsOneWidget);
      await tester.ensureVisible(waterLogButton);
      await tester.pumpAndSettle();
      await tester.tap(waterLogButton);
      await tester.pumpAndSettle();

      // 250ml reflected in UI and persisted in DailyStatsService
      expect(
        find.descendant(of: card, matching: find.text('250 ml')),
        findsOneWidget,
      );
      expect(statsService.todayStats.waterMl, 250);
    });

    testWidgets(
      '3. Step logging and sensor updates reflect on Home Daily Progress reactively',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        final card = find.byType(DailyProgressCard);
        expect(
          find.descendant(of: card, matching: find.text('0')),
          findsOneWidget,
        );

        // In Live mode, tapping the step action opens the Hardware Step Tracking dialog
        final stepAddButton = find.descendant(
          of: card,
          matching: find.byIcon(Icons.add),
        );
        expect(stepAddButton, findsOneWidget);
        await tester.ensureVisible(stepAddButton);
        await tester.pumpAndSettle();
        await tester.tap(stepAddButton);
        await tester.pumpAndSettle();

        expect(find.text('Hardware Step Tracking'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Hardware sensor processes 250 steps
        final now = DateTime.now();
        await StepTrackingService.instance.processRawSensorReading(
          10000,
          now: now,
        );
        await StepTrackingService.instance.processRawSensorReading(
          10250,
          now: now,
        );
        await tester.pumpAndSettle();

        // +250 steps reflected on card
        expect(
          find.descendant(of: card, matching: find.text('250')),
          findsOneWidget,
        );
        expect(statsService.todayStats.steps, 250);
      },
    );

    testWidgets(
      '4. Nutrition changes are reflected in DailyStats and available to Home',
      (tester) async {
        final dal = LocalFoodDatabase.getFoodById('food_dal')!;
        await nutritionService.logFood(
          food: dal,
          category: MealCategory.lunch,
          servings: 1.0,
        );
        await statsService.syncNutritionFromService(service: nutritionService);

        expect(statsService.todayStats.caloriesConsumed, 160.0);
        expect(statsService.todayStats.proteinGrams, 9.2);
        expect(statsService.todayStats.mealsLogged, 1);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        // Verify DailyProgressCard renders with healthy state
        expect(find.byType(DailyProgressCard), findsOneWidget);
      },
    );

    testWidgets(
      '5. Workout completion values update DailyStats and reflect on Home',
      (tester) async {
        await statsService.recordWorkoutCompleted(
          durationMinutes: 25,
          totalReps: 40,
          caloriesBurned: 180,
        );

        expect(statsService.todayStats.workoutsCompleted, 1);
        expect(statsService.todayStats.workoutMinutes, 25);
        expect(statsService.todayStats.totalReps, 40);
        expect(statsService.todayStats.caloriesBurned, 180);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        // 180 kcal burned reflected on DailyProgressCard
        expect(find.text('180 kcal'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Multiple telemetry categories appear together accurately without cross-contamination',
      (tester) async {
        // Hydration
        await statsService.addWater(1000);
        // Activity
        await statsService.updateActivity(
          steps: 5000,
          activeMinutes: 30,
          caloriesBurned: 220,
        );
        // Workout
        await statsService.recordWorkoutCompleted(
          durationMinutes: 15,
          totalReps: 25,
          caloriesBurned: 80,
        );

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('5000'), findsOneWidget); // 5000 steps
        expect(find.text('1000 ml'), findsOneWidget); // 1000 ml water
        expect(find.text('300 kcal'), findsOneWidget); // 220 + 80 = 300 kcal
        expect(find.text('30 min'), findsOneWidget); // 30 min active
      },
    );

    testWidgets(
      '7. Date isolation: Yesterday telemetry does not leak into today Home view',
      (tester) async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await statsService.updateActivity(
          steps: 9000,
          activeMinutes: 60,
          caloriesBurned: 500,
          date: yesterday,
        );
        await statsService.addWater(2000, date: yesterday);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        // Today must still be fresh zeros
        final card = find.byType(DailyProgressCard);
        expect(
          find.descendant(of: card, matching: find.text('0')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('0 ml')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('0 kcal')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('0 min')),
          findsOneWidget,
        );
      },
    );

    test('8. DailyMetrics.fromDailyStats produces exact matching metrics', () {
      const stats = DailyStats(
        date: '2026-10-08',
        steps: 4200,
        stepsGoal: 10000,
        waterMl: 1500,
        waterGoalMl: 3000,
        caloriesBurned: 310,
        caloriesBurnedGoal: 650,
        activeMinutes: 28,
        activeMinutesGoal: 45,
      );

      final metrics = DailyMetrics.fromDailyStats(stats);
      expect(metrics.steps, 4200);
      expect(metrics.stepsGoal, 10000);
      expect(metrics.waterLiters, 1.5);
      expect(metrics.waterGoalLiters, 3.0);
      expect(metrics.caloriesBurned, 310);
      expect(metrics.caloriesGoal, 650);
      expect(metrics.activeMinutes, 28);
      expect(metrics.activeMinutesGoal, 45);
      expect(metrics.stepsProgress, closeTo(4200 / 10000, 0.001));
      expect(metrics.waterProgress, closeTo(1500 / 3000, 0.001));
    });

    testWidgets(
      '9. DailyProgressCard backward compatibility when constructed with metrics only',
      (tester) async {
        const metrics = DailyMetrics(
          steps: 3000,
          stepsGoal: 10000,
          waterLiters: 1.0,
          waterGoalLiters: 3.0,
          caloriesBurned: 200,
          caloriesGoal: 650,
          activeMinutes: 20,
          activeMinutesGoal: 45,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(body: DailyProgressCard(metrics: metrics)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3000'), findsOneWidget);
        expect(find.text('1000 ml'), findsOneWidget);
        expect(find.text('200 kcal'), findsOneWidget);
        expect(find.text('20 min'), findsOneWidget);
      },
    );

    testWidgets('10. Pull to refresh does not restore mock numbers', (
      tester,
    ) async {
      await statsService.addWater(500);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('500 ml'), findsOneWidget);

      // Pull to refresh gesture
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      // 500 ml must remain, never overwritten by mock 2.2L or mock steps
      expect(find.text('500 ml'), findsOneWidget);
      expect(find.text('7420'), findsNothing);
    });
  });
}
