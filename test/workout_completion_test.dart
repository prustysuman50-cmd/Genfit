import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/pose_detection_service.dart';
import 'package:genfit/core/services/push_up_analysis_service.dart';
import 'package:genfit/screens/workout/models/exercise.dart';
import 'package:genfit/screens/workout/workout_session_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('workout_completion_test_');
    DailyStatsService.instance.setCustomStoragePath(tempDir.path);
    GamificationService.instance.setCustomStoragePath(tempDir.path);
    await DailyStatsService.instance.resetToDefaults();
    await GamificationService.instance.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets(
    'Test 6: The actual workout completion flow calls DailyStatsService exactly once per completed session',
    (WidgetTester tester) async {
      final mockPoseService = PoseDetectionService();
      final pushUpService = PushUpAnalysisService(
        minRepCooldown: Duration.zero,
        smoothingFactor: 1.0,
      );

      final pushUpExercise = Exercise.sampleExercises.firstWhere(
        (e) => e.id == 'ex_pushups',
      );

      // Verify clean initial state
      expect(DailyStatsService.instance.todayStats.workoutsCompleted, 0);
      expect(DailyStatsService.instance.todayStats.totalReps, 0);
      expect(GamificationService.instance.totalWorkoutsCompleted, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutSessionScreen(
            initialExercise: pushUpExercise,
            poseDetectionService: mockPoseService,
            pushUpAnalysisService: pushUpService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start workout
      final startBtn = find.widgetWithText(ElevatedButton, 'Start AI Workout');
      expect(startBtn, findsOneWidget);
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Simulate 2 reps
      final simulateBtn = find.widgetWithText(
        OutlinedButton,
        'Simulate AI Counted Rep (+1)',
      );
      expect(simulateBtn, findsOneWidget);
      await tester.ensureVisible(simulateBtn);
      await tester.pumpAndSettle();
      await tester.tap(simulateBtn);
      await tester.pumpAndSettle();
      await tester.tap(simulateBtn);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      // Stop workout (triggers completion)
      final stopBtn = find.widgetWithText(ElevatedButton, 'Stop Workout');
      expect(stopBtn, findsOneWidget);
      await tester.ensureVisible(stopBtn);
      await tester.pumpAndSettle();
      await tester.tap(stopBtn);
      await tester.pumpAndSettle();

      // Verify DailyStats updated exactly once
      expect(DailyStatsService.instance.todayStats.workoutsCompleted, 1);
      expect(DailyStatsService.instance.todayStats.totalReps, 2);
      expect(DailyStatsService.instance.todayStats.caloriesBurned, 0);
      expect(GamificationService.instance.totalWorkoutsCompleted, 1);
      expect(GamificationService.instance.totalReps, 2);

      // Tap Exit Session (back button) - duplicate completion must NOT happen
      final exitBtn = find.byTooltip('Exit Session');
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // Still exactly 1 workout completed!
      expect(DailyStatsService.instance.todayStats.workoutsCompleted, 1);
      expect(DailyStatsService.instance.todayStats.totalReps, 2);
      expect(GamificationService.instance.totalWorkoutsCompleted, 1);
    },
  );

  testWidgets(
    'Exiting workout session with 0 reps and 0 elapsed seconds does not record workout',
    (WidgetTester tester) async {
      final mockPoseService = PoseDetectionService();
      final pushUpService = PushUpAnalysisService(
        minRepCooldown: Duration.zero,
        smoothingFactor: 1.0,
      );

      final pushUpExercise = Exercise.sampleExercises.firstWhere(
        (e) => e.id == 'ex_pushups',
      );

      expect(DailyStatsService.instance.todayStats.workoutsCompleted, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutSessionScreen(
            initialExercise: pushUpExercise,
            poseDetectionService: mockPoseService,
            pushUpAnalysisService: pushUpService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Immediately exit without starting or performing reps
      final exitBtn = find.byTooltip('Exit Session');
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // No fake workout recorded
      expect(DailyStatsService.instance.todayStats.workoutsCompleted, 0);
      expect(DailyStatsService.instance.todayStats.totalReps, 0);
    },
  );
}
