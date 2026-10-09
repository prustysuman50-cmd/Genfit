import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/adaptive_difficulty_service.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/models/workout/adaptive_difficulty.dart';
import 'package:genfit/screens/workout/workout_screen.dart';

void main() {
  group('AdaptiveDifficultyService Core Logic & Progression Tests', () {
    late Directory tempDir;
    final userService = UserService.instance;
    final dailyStatsService = DailyStatsService.instance;
    final gamificationService = GamificationService.instance;
    final adaptiveService = AdaptiveDifficultyService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('adaptive_diff_test_');
      userService.setCustomStoragePath(tempDir.path);
      dailyStatsService.setCustomStoragePath(tempDir.path);
      gamificationService.setCustomStoragePath(tempDir.path);
      adaptiveService.setCustomStoragePath(tempDir.path);

      await userService.resetToDefaults();
      await dailyStatsService.resetToDefaults();
      await gamificationService.resetToDefaults();
      await adaptiveService.resetOverrides();
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('1. Insufficient history (0 workouts) defaults to user profile baseline', () async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      final rec = adaptiveService.evaluateRecommendation();

      expect(rec.currentLevel, equals(WorkoutDifficultyLevel.beginner));
      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.beginner));
      expect(rec.status, equals(ProgressionStatus.baseline));
      expect(rec.hasSufficientHistory, isFalse);
      expect(rec.completedWorkoutsCount, equals(0));
      expect(rec.totalRepsCompleted, equals(0));
      expect(rec.explanation, contains('Profile baseline'));
      expect(rec.explanation, contains('Complete at least 3 workouts'));
    });

    test('2. Single workout does NOT trigger automatic promotion (incomplete data rule)', () async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      // Complete 1 workout session with high reps (e.g. 30 reps)
      await dailyStatsService.recordWorkoutCompleted(
        durationMinutes: 15,
        totalReps: 30,
      );
      await gamificationService.recordWorkoutCompleted(reps: 30);

      final rec = adaptiveService.evaluateRecommendation();

      // Must remain at Beginner baseline because 1 workout < 3 required threshold
      expect(rec.currentLevel, equals(WorkoutDifficultyLevel.beginner));
      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.beginner));
      expect(rec.status, equals(ProgressionStatus.baseline));
      expect(rec.hasSufficientHistory, isFalse);
      expect(rec.completedWorkoutsCount, equals(1));
      expect(rec.totalRepsCompleted, equals(30));
      expect(rec.explanation, contains('1/3 completed sessions'));
      expect(rec.explanation, contains('Complete at least 3 workouts'));
    });

    test('3. Safe ramp-up rule: Unverified Advanced profile with 0 workouts recommends Intermediate', () async {
      await userService.updateFields(fitnessLevel: 'Advanced');

      final rec = adaptiveService.evaluateRecommendation();

      expect(rec.currentLevel, equals(WorkoutDifficultyLevel.advanced));
      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.intermediate));
      expect(rec.status, equals(ProgressionStatus.safeRampUp));
      expect(rec.hasSufficientHistory, isFalse);
      expect(rec.differsFromCurrent, isTrue);
      expect(rec.explanation, contains('Safe Ramp-Up'));
      expect(rec.explanation, contains('Intermediate is recommended'));
    });

    test('4. Beginner progresses to Intermediate upon verified volume (4+ workouts & 60+ reps)', () async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      // Complete 4 workouts with 15 reps each = 60 reps
      for (int i = 0; i < 4; i++) {
        final date = DateTime.now().subtract(Duration(days: 3 - i));
        await dailyStatsService.recordWorkoutCompleted(
          durationMinutes: 15,
          totalReps: 15,
          date: date,
        );
        await gamificationService.recordWorkoutCompleted(reps: 15, atDate: date);
      }

      final rec = adaptiveService.evaluateRecommendation();

      expect(rec.currentLevel, equals(WorkoutDifficultyLevel.beginner));
      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.intermediate));
      expect(rec.status, equals(ProgressionStatus.promoted));
      expect(rec.isPromotion, isTrue);
      expect(rec.hasSufficientHistory, isTrue);
      expect(rec.completedWorkoutsCount, equals(4));
      expect(rec.totalRepsCompleted, equals(60));
      expect(rec.explanation, contains('Ready for promotion'));
      expect(rec.explanation, contains('Intermediate intensity'));
    });

    test('5. Beginner with 3 workouts but insufficient reps (< 60 reps) maintains Beginner', () async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      // Complete 3 workouts with only 5 reps each = 15 reps
      for (int i = 0; i < 3; i++) {
        final date = DateTime.now().subtract(Duration(days: 2 - i));
        await dailyStatsService.recordWorkoutCompleted(
          durationMinutes: 10,
          totalReps: 5,
          date: date,
        );
        await gamificationService.recordWorkoutCompleted(reps: 5, atDate: date);
      }

      final rec = adaptiveService.evaluateRecommendation();

      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.beginner));
      expect(rec.status, equals(ProgressionStatus.maintained));
      expect(rec.explanation, contains('Maintaining Beginner'));
      expect(rec.explanation, contains('Intermediate unlocks at 4 workouts & 60 reps'));
    });

    test('6. Intermediate progresses to Advanced with high volume (8+ workouts, 150+ reps, streak >= 4)', () async {
      await userService.updateFields(fitnessLevel: 'Intermediate');

      // Build 5-day streak and 8 completed workouts with 20 reps each = 160 reps
      for (int i = 0; i < 8; i++) {
        final date = DateTime.now().subtract(Duration(days: 7 - i));
        await dailyStatsService.recordWorkoutCompleted(
          durationMinutes: 20,
          totalReps: 20,
          date: date,
        );
        await gamificationService.recordWorkoutCompleted(reps: 20, atDate: date);
      }

      final rec = adaptiveService.evaluateRecommendation();

      expect(rec.currentLevel, equals(WorkoutDifficultyLevel.intermediate));
      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.advanced));
      expect(rec.status, equals(ProgressionStatus.promoted));
      expect(rec.isPromotion, isTrue);
      expect(rec.completedWorkoutsCount, equals(8));
      expect(rec.totalRepsCompleted, equals(160));
      expect(rec.explanation, contains('Outstanding volume'));
      expect(rec.explanation, contains('Ready for Advanced intensity'));
    });

    test('7. Adaptive Today\'s Workout reflects difficulty tiers', () {
      final beginnerWorkout = adaptiveService.getAdaptiveTodaysWorkout(
        WorkoutDifficultyLevel.beginner,
      );
      expect(beginnerWorkout.intensity, equals('Beginner'));
      expect(beginnerWorkout.durationMinutes, equals(15));
      expect(beginnerWorkout.calories, equals(150));
      expect(beginnerWorkout.exercisesCount, equals(3));

      final intermediateWorkout = adaptiveService.getAdaptiveTodaysWorkout(
        WorkoutDifficultyLevel.intermediate,
      );
      expect(intermediateWorkout.intensity, equals('Intermediate'));
      expect(intermediateWorkout.durationMinutes, equals(20));
      expect(intermediateWorkout.calories, equals(220));
      expect(intermediateWorkout.exercisesCount, equals(5));

      final advancedWorkout = adaptiveService.getAdaptiveTodaysWorkout(
        WorkoutDifficultyLevel.advanced,
      );
      expect(advancedWorkout.intensity, equals('Advanced'));
      expect(advancedWorkout.durationMinutes, equals(28));
      expect(advancedWorkout.calories, equals(310));
      expect(advancedWorkout.exercisesCount, equals(7));
    });

    test('8. Manual preference override updates user profile and persists across restart', () async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      // User chooses Advanced tier manually
      await adaptiveService.setUserPreferredDifficulty(
        WorkoutDifficultyLevel.advanced,
      );

      expect(adaptiveService.userPreferredLevel, equals(WorkoutDifficultyLevel.advanced));
      expect(userService.currentUser.fitnessLevel, equals('Advanced'));

      // Re-initialize a new service instance from disk
      final restartedService = AdaptiveDifficultyService.forTesting(
        userService: userService,
        dailyStatsService: dailyStatsService,
        gamificationService: gamificationService,
        customStoragePath: tempDir.path,
      );
      await restartedService.init();

      expect(
        restartedService.userPreferredLevel,
        equals(WorkoutDifficultyLevel.advanced),
      );
    });

    test('9. Accepting recommendation applies recommended level to profile', () async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      // Qualify for Intermediate promotion
      for (int i = 0; i < 4; i++) {
        final date = DateTime.now().subtract(Duration(days: 3 - i));
        await dailyStatsService.recordWorkoutCompleted(
          durationMinutes: 15,
          totalReps: 20,
          date: date,
        );
        await gamificationService.recordWorkoutCompleted(reps: 20, atDate: date);
      }

      final rec = adaptiveService.evaluateRecommendation();
      expect(rec.recommendedLevel, equals(WorkoutDifficultyLevel.intermediate));

      // Accept recommendation
      await adaptiveService.acceptRecommendation();

      expect(adaptiveService.userPreferredLevel, equals(WorkoutDifficultyLevel.intermediate));
      expect(userService.currentUser.fitnessLevel, equals('Intermediate'));
    });
  });

  group('WorkoutScreen Adaptive Difficulty Widget Tests', () {
    late Directory tempDir;
    final userService = UserService.instance;
    final dailyStatsService = DailyStatsService.instance;
    final gamificationService = GamificationService.instance;
    final adaptiveService = AdaptiveDifficultyService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('workout_ui_test_');
      userService.setCustomStoragePath(tempDir.path);
      dailyStatsService.setCustomStoragePath(tempDir.path);
      gamificationService.setCustomStoragePath(tempDir.path);
      adaptiveService.setCustomStoragePath(tempDir.path);

      await userService.resetToDefaults();
      await dailyStatsService.resetToDefaults();
      await gamificationService.resetToDefaults();
      await adaptiveService.resetOverrides();
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('Renders Adaptive Difficulty Card with baseline explainability and chips', (
      WidgetTester tester,
    ) async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      await tester.pumpWidget(
        const MaterialApp(home: WorkoutScreen()),
      );
      await tester.pumpAndSettle();

      // Card Header & Badge
      expect(find.text('ADAPTIVE DIFFICULTY'), findsOneWidget);
      expect(find.text('BEGINNER'), findsAtLeastNWidgets(1));

      // Target specs & explainable reason
      expect(find.textContaining('Suggested Pace: 8–12 reps'), findsOneWidget);
      expect(find.textContaining('Profile baseline'), findsOneWidget);

      // Active Tier chips
      expect(find.text('Beginner'), findsAtLeastNWidgets(1));
      expect(find.text('Intermediate'), findsAtLeastNWidgets(1));
      expect(find.text('Advanced'), findsAtLeastNWidgets(1));

      // Today's workout adapted to Beginner
      expect(find.text('Hostel Room High-Burn HIIT'), findsOneWidget);
      expect(find.text('15 mins'), findsOneWidget);
      expect(find.text('150 kcal'), findsOneWidget);
      expect(find.text('3 exercises'), findsOneWidget);
    });

    testWidgets('Tapping tier chip switches difficulty and updates Today\'s Workout dynamically', (
      WidgetTester tester,
    ) async {
      await userService.updateFields(fitnessLevel: 'Beginner');

      await tester.pumpWidget(
        const MaterialApp(home: WorkoutScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hostel Room High-Burn HIIT'), findsOneWidget);
      expect(find.text('15 mins'), findsOneWidget);
      expect(find.text('150 kcal'), findsOneWidget);
      expect(find.text('3 exercises'), findsOneWidget);

      // Tap 'Intermediate' chip
      final intermediateChip = find.text('Intermediate').first;
      await tester.ensureVisible(intermediateChip);
      await tester.tap(intermediateChip);
      await tester.pumpAndSettle();

      // Adaptive service updates
      expect(adaptiveService.userPreferredLevel, equals(WorkoutDifficultyLevel.intermediate));

      // Today's workout switches to Intermediate plan specs
      expect(find.text('Hostel Room High-Burn HIIT'), findsOneWidget);
      expect(find.text('20 mins'), findsOneWidget);
      expect(find.text('220 kcal'), findsOneWidget);
      expect(find.text('5 exercises'), findsOneWidget);
    });
  });
}
