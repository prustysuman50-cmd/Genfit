import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/heritage_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/models/gamification/achievement_progress.dart';
import 'package:genfit/models/gamification/badge_item.dart';
import 'package:genfit/screens/gamification/widgets/achievement_gallery_card.dart';

void main() {
  late Directory tempDir;
  final gamification = GamificationService.instance;
  final dailyStats = DailyStatsService.instance;
  final heritage = HeritageService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('achievement_gallery_test_');
    gamification.setCustomStoragePath(tempDir.path);
    dailyStats.setCustomStoragePath(tempDir.path);
    heritage.setCustomStoragePath(tempDir.path);
    await gamification.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('Achievement Progress Model & Helper Unit Tests', () {
    test('computes correct initial progress from service telemetry', () {
      final badge = gamification.getBadgeById('hundred_reps')!;
      final progress = AchievementProgress.compute(badge, gamification);

      expect(progress.current, 0);
      expect(progress.target, 100);
      expect(progress.rawCurrent, 0);
      expect(progress.unit, 'reps');
      expect(progress.fraction, 0.0);
      expect(progress.percent, 0);
      expect(progress.displayText, '0 / 100 reps');
      expect(progress.isAchieved, isFalse);
    });

    test('accurately computes honest progress for all 7 badges', () async {
      // Record 60 reps and 1 workout
      await gamification.recordWorkoutCompleted(reps: 60);

      // 1. first_workout (unlocked)
      final bWorkout = gamification.getBadgeById('first_workout')!;
      final pWorkout = AchievementProgress.compute(bWorkout, gamification);
      expect(pWorkout.current, 1);
      expect(pWorkout.target, 1);
      expect(pWorkout.displayText, '1 / 1 workout');
      expect(pWorkout.isAchieved, isTrue);

      // 2. hundred_reps (in progress)
      final bReps = gamification.getBadgeById('hundred_reps')!;
      final pReps = AchievementProgress.compute(bReps, gamification);
      expect(pReps.current, 60);
      expect(pReps.target, 100);
      expect(pReps.displayText, '60 / 100 reps');
      expect(pReps.percent, 60);
      expect(pReps.isAchieved, isFalse);

      // 3. seven_day_streak (in progress)
      final bStreak = gamification.getBadgeById('seven_day_streak')!;
      final pStreak = AchievementProgress.compute(bStreak, gamification);
      expect(pStreak.target, 7);
      expect(pStreak.unit, 'days');

      // 4. first_meal_logged (locked)
      final bMeal = gamification.getBadgeById('first_meal_logged')!;
      final pMeal = AchievementProgress.compute(bMeal, gamification);
      expect(pMeal.current, 0);
      expect(pMeal.target, 1);
      expect(pMeal.unit, 'meal');

      // 5. campus_challenger (locked)
      final bChal = gamification.getBadgeById('campus_challenger')!;
      final pChal = AchievementProgress.compute(bChal, gamification);
      expect(pChal.current, 0);
      expect(pChal.target, 1);
      expect(pChal.unit, 'challenge');

      // 6. journey_starter (locked)
      final bJourney = gamification.getBadgeById('journey_starter')!;
      final pJourney = AchievementProgress.compute(bJourney, gamification);
      expect(pJourney.current, 0);
      expect(pJourney.target, 1);
      expect(pJourney.unit, 'milestone');

      // 7. odisha_explorer (locked)
      final bExplorer = gamification.getBadgeById('odisha_explorer')!;
      final pExplorer = AchievementProgress.compute(bExplorer, gamification);
      expect(pExplorer.current, 0);
      expect(pExplorer.target, 3);
      expect(pExplorer.unit, 'milestones');
    });

    test('unlocked badge progress never contradicts unlocked status', () {
      // Manually unlocked badge without service counter
      final customBadge = const BadgeItem(
        id: 'hundred_reps',
        name: '100 Reps',
        description: 'Test',
        icon: Icons.star,
        isUnlocked: true,
      );

      final p = AchievementProgress.compute(customBadge, gamification);
      expect(p.current, 100);
      expect(p.isAchieved, isTrue);
      expect(p.fraction, 1.0);
    });

    test('formatUnlockDate generates clean readable date without external package', () {
      final dt = DateTime(2026, 10, 9, 14, 30);
      final formatted = AchievementProgress.formatUnlockDate(dt);
      expect(formatted, contains('Oct 9, 2026'));
      expect(formatted, contains('2:30 PM'));
    });
  });

  group('Achievement Gallery Widget Tests', () {
    testWidgets('renders all 7 badges and summary header', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // Summary Header
      expect(find.text('Achievement Collection'), findsOneWidget);
      expect(find.text('0 of 7 Badges Unlocked'), findsOneWidget);

      // All 7 badge names
      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('7 Day Streak'), findsOneWidget);
      expect(find.text('100 Reps'), findsOneWidget);
      expect(find.text('First Meal Logged'), findsOneWidget);
      expect(find.text('Campus Challenger'), findsOneWidget);
      expect(find.text('Journey Starter'), findsOneWidget);
      expect(find.text('Odisha Explorer'), findsOneWidget);

      // Categories displayed on badge cards
      expect(find.text('WORKOUTS'), findsWidgets);
      expect(find.text('CONSISTENCY'), findsWidgets);
      expect(find.text('NUTRITION'), findsWidgets);
      expect(find.text('CHALLENGES'), findsWidgets);
      expect(find.text('ODISHA HERITAGE'), findsWidgets);
    });

    testWidgets('status filters (All, Unlocked, Locked) work correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Initially 0 unlocked
      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Unlocked (0)' filter chip
      await tester.tap(find.text('Unlocked (0)'));
      await tester.pumpAndSettle();

      // Displays empty state
      expect(find.text('No achievements in this filter'), findsOneWidget);
      expect(find.text('First Workout'), findsNothing);

      // Tap 'Locked (7)' filter chip
      await tester.tap(find.text('Locked (7)'));
      await tester.pumpAndSettle();

      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('100 Reps'), findsOneWidget);

      // Unlock a badge
      await gamification.recordWorkoutCompleted();

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // Summary updated
      expect(find.text('1 of 7 Badges Unlocked'), findsOneWidget);

      // Tap 'Unlocked (1)'
      await tester.tap(find.text('Unlocked (1)'));
      await tester.pumpAndSettle();

      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('100 Reps'), findsNothing);

      // Tap 'All (7)'
      await tester.tap(find.text('All (7)'));
      await tester.pumpAndSettle();

      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('100 Reps'), findsOneWidget);
    });

    testWidgets('category filtering works correctly for all categories', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Filter: Workouts (First Workout, 100 Reps)
      await tester.tap(find.text('Workouts'));
      await tester.pumpAndSettle();

      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('100 Reps'), findsOneWidget);
      expect(find.text('First Meal Logged'), findsNothing);

      // 2. Filter: Nutrition (First Meal Logged)
      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();

      expect(find.text('First Meal Logged'), findsOneWidget);
      expect(find.text('First Workout'), findsNothing);

      // 3. Filter: Consistency (7 Day Streak)
      await tester.tap(find.text('Consistency'));
      await tester.pumpAndSettle();

      expect(find.text('7 Day Streak'), findsOneWidget);
      expect(find.text('100 Reps'), findsNothing);

      // 4. Filter: Challenges (Campus Challenger)
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();

      expect(find.text('Campus Challenger'), findsOneWidget);

      // 5. Filter: Odisha Heritage (Journey Starter, Odisha Explorer)
      await tester.tap(find.text('Odisha Heritage'));
      await tester.pumpAndSettle();

      expect(find.text('Journey Starter'), findsOneWidget);
      expect(find.text('Odisha Explorer'), findsOneWidget);
      expect(find.text('100 Reps'), findsNothing);

      // 6. Reset to 'All'
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('First Workout'), findsOneWidget);
      expect(find.text('Odisha Explorer'), findsOneWidget);
    });

    testWidgets('progress indicators reflect actual service data', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Record 45 reps
      await gamification.recordWorkoutCompleted(reps: 45);

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // 100 Reps shows honest progress
      expect(find.text('45 / 100 reps'), findsOneWidget);
      expect(find.text('(45%)'), findsOneWidget);

      // First Workout is unlocked (1 / 1 workout)
      expect(find.text('1 / 1 workout'), findsOneWidget);
      expect(find.text('(100%)'), findsOneWidget);
    });

    testWidgets('tapping locked badge opens detail sheet with motivation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // Tap '100 Reps' badge card
      await tester.tap(find.text('100 Reps'));
      await tester.pumpAndSettle();

      // Detail sheet is presented
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('How to Unlock'), findsOneWidget);
      expect(
        find.text(
          'Every rep counts toward greatness. Complete 100 cumulative exercise repetitions across your workouts!',
        ),
        findsOneWidget,
      );

      // Close button dismisses sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('How to Unlock'), findsNothing);
    });

    testWidgets('tapping unlocked badge opens detail sheet with unlock timestamp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedDate = DateTime(2026, 10, 9, 10, 15);
      await gamification.recordWorkoutCompleted(atDate: fixedDate);

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'First Workout' badge card
      await tester.tap(find.text('First Workout'));
      await tester.pumpAndSettle();

      // Detail sheet shows UNLOCKED and timestamp
      expect(find.text('UNLOCKED'), findsOneWidget);
      expect(find.text('Achievement Unlocked'), findsOneWidget);
      expect(find.textContaining('Unlocked on Oct 9, 2026 at 10:15 AM'), findsOneWidget);

      // Dismiss via top close button
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Achievement Unlocked'), findsNothing);
    });

    testWidgets('opening and dismissing detail sheet is strictly read-only', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialXp = gamification.xp;
      final initialWorkouts = gamification.totalWorkoutsCompleted;
      final initialStreak = gamification.streakDays;
      final initialUnlocked = gamification.badges.where((b) => b.isUnlocked).length;

      await tester.pumpWidget(
        buildTestWidget(
          AchievementGalleryCard(gamification: gamification),
        ),
      );
      await tester.pumpAndSettle();

      // Open detail sheet
      await tester.tap(find.text('7 Day Streak'));
      await tester.pumpAndSettle();

      // Dismiss
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify no state changed
      expect(gamification.xp, initialXp);
      expect(gamification.totalWorkoutsCompleted, initialWorkouts);
      expect(gamification.streakDays, initialStreak);
      expect(
        gamification.badges.where((b) => b.isUnlocked).length,
        initialUnlocked,
      );
    });

    test('badge unlocking never awards XP (unlockBadge invariant)', () async {
      final initialXp = gamification.xp;

      // Directly unlock badge
      gamification.unlockBadge('seven_day_streak');

      expect(gamification.getBadgeById('seven_day_streak')?.isUnlocked, isTrue);
      // XP must remain unchanged
      expect(gamification.xp, initialXp);
    });
  });
}
