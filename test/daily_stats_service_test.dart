import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/models/daily_stats.dart';

void main() {
  late Directory tempDir;
  final service = DailyStatsService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('daily_stats_test_');
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

  group('DailyStats Model Tests', () {
    test(
      'JSON serialization/deserialization preserves the DailyStats values',
      () {
        const original = DailyStats(
          date: '2026-10-08',
          steps: 8500,
          stepsGoal: 12000,
          activeMinutes: 40,
          activeMinutesGoal: 50,
          caloriesBurned: 520,
          caloriesBurnedGoal: 700,
          waterMl: 1750,
          waterGoalMl: 3500,
          caloriesConsumed: 1850.5,
          caloriesConsumedGoal: 2200.0,
          proteinGrams: 95.0,
          proteinGoalGrams: 120.0,
          carbsGrams: 210.0,
          fatsGrams: 55.0,
          mealsLogged: 3,
          workoutsCompleted: 2,
          workoutMinutes: 45,
          totalReps: 60,
        );

        final json = original.toJson();
        final restored = DailyStats.fromJson(json);

        expect(restored.date, original.date);
        expect(restored.steps, original.steps);
        expect(restored.stepsGoal, original.stepsGoal);
        expect(restored.activeMinutes, original.activeMinutes);
        expect(restored.activeMinutesGoal, original.activeMinutesGoal);
        expect(restored.caloriesBurned, original.caloriesBurned);
        expect(restored.caloriesBurnedGoal, original.caloriesBurnedGoal);
        expect(restored.waterMl, original.waterMl);
        expect(restored.waterGoalMl, original.waterGoalMl);
        expect(restored.caloriesConsumed, original.caloriesConsumed);
        expect(restored.caloriesConsumedGoal, original.caloriesConsumedGoal);
        expect(restored.proteinGrams, original.proteinGrams);
        expect(restored.proteinGoalGrams, original.proteinGoalGrams);
        expect(restored.carbsGrams, original.carbsGrams);
        expect(restored.fatsGrams, original.fatsGrams);
        expect(restored.mealsLogged, original.mealsLogged);
        expect(restored.workoutsCompleted, original.workoutsCompleted);
        expect(restored.workoutMinutes, original.workoutMinutes);
        expect(restored.totalReps, original.totalReps);
      },
    );

    test('formatDate produces canonical YYYY-MM-DD format', () {
      final date = DateTime(2026, 4, 9);
      expect(DailyStats.formatDate(date), '2026-04-09');

      final dateTwo = DateTime(2026, 12, 25);
      expect(DailyStats.formatDate(dateTwo), '2026-12-25');
    });

    test('computed progress getters work as expected', () {
      const stats = DailyStats(
        date: '2026-10-08',
        waterMl: 1500,
        waterGoalMl: 3000,
        steps: 5000,
        stepsGoal: 10000,
      );

      expect(stats.waterLiters, 1.5);
      expect(stats.waterGoalLiters, 3.0);
      expect(stats.waterProgress, 0.5);
      expect(stats.stepsProgress, 0.5);
    });
  });

  group('DailyStatsService Core Tests', () {
    test(
      'Test 1: Fresh service creates today record with zero activity and water',
      () {
        final today = service.todayStats;
        final expectedDate = DailyStats.formatDate(DateTime.now());

        expect(today.date, expectedDate);
        expect(today.waterMl, 0);
        expect(today.steps, 0);
        expect(today.activeMinutes, 0);
        expect(today.caloriesBurned, 0);
        expect(today.mealsLogged, 0);
        expect(today.workoutsCompleted, 0);
        expect(today.totalReps, 0);
      },
    );

    test('Test 2: addWater(250) changes today water from 0 to 250', () async {
      expect(service.todayStats.waterMl, 0);
      await service.addWater(250);

      expect(service.todayStats.waterMl, 250);
      expect(service.todayStats.waterLiters, 0.25);
    });

    test('Test 3: Adding water twice gives 500 ml', () async {
      await service.addWater(250);
      await service.addWater(250);

      expect(service.todayStats.waterMl, 500);
      expect(service.todayStats.waterLiters, 0.5);
    });

    test(
      'Test 4: Water persists after service reload/reinitialization',
      () async {
        await service.addWater(750);
        expect(service.todayStats.waterMl, 750);

        // Re-initialize service from the saved file in tempDir
        await service.init();
        expect(service.todayStats.waterMl, 750);
        expect(service.todayStats.waterLiters, 0.75);
      },
    );

    test(
      'Test 5: Yesterday record remains when today record is created',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayKey = DailyStats.formatDate(yesterday);
        final todayKey = DailyStats.formatDate(DateTime.now());

        await service.addWater(500, date: yesterday);

        // Access today's record
        final today = service.todayStats;

        expect(today.date, todayKey);
        expect(today.waterMl, 0); // Today is 0

        // Yesterday still retains 500 ml
        final yesterdayRecord = service.getStatsForDate(yesterday);
        expect(yesterdayRecord.date, yesterdayKey);
        expect(yesterdayRecord.waterMl, 500);

        expect(service.allRecords.containsKey(yesterdayKey), isTrue);
        expect(service.allRecords.containsKey(todayKey), isTrue);
      },
    );

    test('Test 6: Today date key uses canonical YYYY-MM-DD format', () {
      final now = DateTime.now();
      final expectedKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      expect(service.todayStats.date, expectedKey);
      expect(
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(service.todayStats.date),
        isTrue,
      );
    });

    test('notifies listeners when water is added', () async {
      int notifyCount = 0;
      service.addListener(() {
        notifyCount++;
      });

      await service.addWater(250);
      expect(notifyCount, 1);

      await service.addWater(250);
      expect(notifyCount, 2);
    });
  });

  group('DailyStatsService Workout Recording Tests', () {
    test(
      'Test 1: Fresh DailyStats has 0 workouts, minutes, reps, and calories',
      () {
        final today = service.todayStats;
        expect(today.workoutsCompleted, 0);
        expect(today.workoutMinutes, 0);
        expect(today.totalReps, 0);
        expect(today.caloriesBurned, 0);
      },
    );

    test('Test 2: Recording one workout results in exact values', () async {
      await service.recordWorkoutCompleted(
        durationMinutes: 20,
        totalReps: 30,
        caloriesBurned: 150,
      );

      final today = service.todayStats;
      expect(today.workoutsCompleted, 1);
      expect(today.workoutMinutes, 20);
      expect(today.totalReps, 30);
      expect(today.caloriesBurned, 150);
    });

    test('Test 3: Recording a second workout accumulates', () async {
      await service.recordWorkoutCompleted(
        durationMinutes: 20,
        totalReps: 30,
        caloriesBurned: 150,
      );

      await service.recordWorkoutCompleted(
        durationMinutes: 15,
        totalReps: 20,
        caloriesBurned: 100,
      );

      final today = service.todayStats;
      expect(today.workoutsCompleted, 2);
      expect(today.workoutMinutes, 35);
      expect(today.totalReps, 50);
      expect(today.caloriesBurned, 250);
    });

    test(
      'Test 4: Workout telemetry persists after service reinitialization',
      () async {
        await service.recordWorkoutCompleted(
          durationMinutes: 25,
          totalReps: 40,
          caloriesBurned: 180,
        );

        await service.init();
        final today = service.todayStats;
        expect(today.workoutsCompleted, 1);
        expect(today.workoutMinutes, 25);
        expect(today.totalReps, 40);
        expect(today.caloriesBurned, 180);
      },
    );

    test(
      'Test 5: Yesterday workout data remains separate from today',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayKey = DailyStats.formatDate(yesterday);
        final todayKey = DailyStats.formatDate(DateTime.now());

        await service.recordWorkoutCompleted(
          durationMinutes: 30,
          totalReps: 45,
          caloriesBurned: 200,
          date: yesterday,
        );

        final today = service.todayStats;
        expect(today.date, todayKey);
        expect(today.workoutsCompleted, 0);
        expect(today.workoutMinutes, 0);
        expect(today.totalReps, 0);
        expect(today.caloriesBurned, 0);

        final yesterdayStats = service.getStatsForDate(yesterday);
        expect(yesterdayStats.date, yesterdayKey);
        expect(yesterdayStats.workoutsCompleted, 1);
        expect(yesterdayStats.workoutMinutes, 30);
        expect(yesterdayStats.totalReps, 45);
        expect(yesterdayStats.caloriesBurned, 200);
      },
    );

    test(
      'Test 7: A workout with zero calories does not fabricate calories',
      () async {
        await service.recordWorkoutCompleted(
          durationMinutes: 10,
          totalReps: 15,
          caloriesBurned: 0,
        );

        final today = service.todayStats;
        expect(today.workoutsCompleted, 1);
        expect(today.workoutMinutes, 10);
        expect(today.totalReps, 15);
        expect(today.caloriesBurned, 0);
      },
    );

    test('notifies listeners when workout is recorded', () async {
      int notifyCount = 0;
      service.addListener(() {
        notifyCount++;
      });

      await service.recordWorkoutCompleted(
        durationMinutes: 15,
        totalReps: 25,
        caloriesBurned: 100,
      );

      expect(notifyCount, 1);
    });
  });
}
