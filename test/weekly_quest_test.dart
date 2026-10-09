import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/weekly_quest_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/models/gamification/iso_week.dart';
import 'package:genfit/screens/gamification/widgets/weekly_quest_board_card.dart';
import 'package:genfit/screens/gamification/widgets/weekly_quest_board_sheet.dart';
import 'package:genfit/screens/home/widgets/daily_challenge_card.dart';

void main() {
  late Directory tempDir;
  final gamification = GamificationService.instance;
  final dailyStats = DailyStatsService.instance;
  final questService = WeeklyQuestService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('weekly_quest_test_');
    gamification.setCustomStoragePath(tempDir.path);
    dailyStats.setCustomStoragePath(tempDir.path);
    questService.setCustomStoragePath(tempDir.path);

    questService.setDailyStatsService(dailyStats);
    questService.setGamificationService(gamification);

    await gamification.resetToDefaults();
    await dailyStats.resetToDefaults();
    await questService.resetToDefaults();
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

  group('ISO-8601 Calendar Week Calculation Tests', () {
    test('calculates correct ISO week key and boundaries for standard dates', () {
      // 2026-10-09 is a Friday in Week 41
      final date = DateTime(2026, 10, 9);
      final week = IsoWeek.fromDateTime(date);

      expect(week.year, 2026);
      expect(week.weekNumber, 41);
      expect(week.weekKey, '2026-W41');
      expect(week.label, 'Week 41');
      expect(week.startOfWeek, DateTime(2026, 10, 5)); // Monday
      expect(week.endOfWeek, DateTime(2026, 10, 11)); // Sunday
      expect(week.dateRangeLabel, 'Oct 5 – 11, 2026');

      final keys = week.dayDateKeys;
      expect(keys.length, 7);
      expect(keys.first, '2026-10-05');
      expect(keys.last, '2026-10-11');
    });

    test('handles year crossover boundary: 2025-12-31 belongs to 2026-W01', () {
      // 2025-12-31 is Wednesday. The Thursday is 2026-01-01 -> ISO year 2026 Week 1
      final date = DateTime(2025, 12, 31);
      final week = IsoWeek.fromDateTime(date);

      expect(week.year, 2026);
      expect(week.weekNumber, 1);
      expect(week.weekKey, '2026-W01');
      expect(week.startOfWeek, DateTime(2025, 12, 29)); // Monday
      expect(week.endOfWeek, DateTime(2026, 1, 4)); // Sunday
      expect(week.dayDateKeys, contains('2025-12-31'));
      expect(week.dayDateKeys, contains('2026-01-01'));
    });

    test('handles year crossover boundary: 2027-01-01 belongs to 2026-W53', () {
      // 2027-01-01 is Friday. The Thursday is 2026-12-31 -> ISO year 2026 Week 53
      final date = DateTime(2027, 1, 1);
      final week = IsoWeek.fromDateTime(date);

      expect(week.year, 2026);
      expect(week.weekNumber, 53);
      expect(week.weekKey, '2026-W53');
      expect(week.startOfWeek, DateTime(2026, 12, 28));
      expect(week.endOfWeek, DateTime(2027, 1, 3));
    });

    test('containsDate accurately identifies week membership', () {
      final week = IsoWeek.fromDateTime(DateTime(2026, 10, 9));
      expect(week.containsDate(DateTime(2026, 10, 5)), isTrue);
      expect(week.containsDate(DateTime(2026, 10, 11)), isTrue);
      expect(week.containsDate(DateTime(2026, 10, 4)), isFalse);
      expect(week.containsDate(DateTime(2026, 10, 12)), isFalse);
    });
  });

  group('Weekly Telemetry Aggregation & Progress Tests', () {
    test('aggregates only records belonging strictly to current ISO week', () {
      // Set test week: 2026-W41 (Mon Oct 5 - Sun Oct 11)
      final testDate = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(testDate);

      // Record in PREVIOUS week (Sun Oct 4) - must NOT be aggregated
      final prevDateKey = '2026-10-04';
      dailyStats.updateActivityForDate(
        prevDateKey,
        steps: 10000,
        workoutsCompleted: 2,
        totalReps: 80,
      );

      // Record in CURRENT week: Monday Oct 5
      dailyStats.updateActivityForDate(
        '2026-10-05',
        steps: 8000,
        workoutsCompleted: 1,
        totalReps: 50,
        mealsLogged: 2,
        activeMinutes: 30,
      );

      // Record in CURRENT week: Wednesday Oct 7
      dailyStats.updateActivityForDate(
        '2026-10-07',
        steps: 7000,
        workoutsCompleted: 1,
        totalReps: 40,
        mealsLogged: 1,
        activeMinutes: 45,
      );

      // Record in NEXT week (Mon Oct 12) - must NOT be aggregated
      dailyStats.updateActivityForDate(
        '2026-10-12',
        steps: 15000,
        workoutsCompleted: 3,
        totalReps: 120,
      );

      final quests = questService.getQuestsForWeek(atDate: testDate);
      final workoutQuest = quests.firstWhere((q) => q.id == 'weekly_workouts');
      final stepQuest = quests.firstWhere((q) => q.id == 'weekly_steps');
      final repQuest = quests.firstWhere((q) => q.id == 'weekly_reps');
      final mealQuest = quests.firstWhere((q) => q.id == 'weekly_meal_days');
      final activeQuest = quests.firstWhere((q) => q.id == 'weekly_active_minutes');

      // Weekly workouts = 1 (Oct 5) + 1 (Oct 7) = 2 (previous week's 2 excluded!)
      expect(workoutQuest.current, 2);
      expect(workoutQuest.target, 3);
      expect(workoutQuest.isCompleted, isFalse);

      // Weekly steps = 8,000 + 7,000 = 15,000 (prev 10k and next 15k excluded!)
      expect(stepQuest.current, 15000);
      expect(stepQuest.target, 25000);
      expect(stepQuest.isCompleted, isFalse);

      // Weekly reps = 50 + 40 = 90
      expect(repQuest.current, 90);
      expect(repQuest.target, 150);

      // Distinct meal days = 2 (Oct 5 and Oct 7)
      expect(mealQuest.current, 2);
      expect(mealQuest.target, 4);

      // Active minutes = 30 + 45 = 75
      expect(activeQuest.current, 75);
      expect(activeQuest.target, 120);
    });

    test('progress caps at target and calculates accurate completion fraction', () {
      final testDate = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(testDate);

      // Inject 5 workouts (target is 3)
      dailyStats.updateActivityForDate('2026-10-05', workoutsCompleted: 5);

      final quests = questService.getQuestsForWeek(atDate: testDate);
      final workoutQuest = quests.firstWhere((q) => q.id == 'weekly_workouts');

      expect(workoutQuest.current, 3); // Clamped to target
      expect(workoutQuest.isCompleted, isTrue);
      expect(workoutQuest.fraction, 1.0);
      expect(workoutQuest.percent, 100);
    });
  });

  group('Duplicate Reward Protection & XP Payout Tests', () {
    test('awards XP exactly once when a quest is completed', () async {
      final testDate = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(testDate);

      final initialXp = gamification.xp;

      // Complete 3 workouts in current week
      dailyStats.updateActivityForDate('2026-10-05', workoutsCompleted: 2);
      dailyStats.updateActivityForDate('2026-10-06', workoutsCompleted: 1);

      await questService.recomputeAndClaimRewards(atDate: testDate);

      // 150 XP awarded
      expect(gamification.xp, initialXp + 150);
      expect(questService.isQuestClaimed('2026-W41', 'weekly_workouts'), isTrue);

      // Repeated invocations must NOT award duplicate XP
      await questService.recomputeAndClaimRewards(atDate: testDate);
      await questService.recomputeAndClaimRewards(atDate: testDate);
      expect(gamification.xp, initialXp + 150);
    });

    test('reloading service from persistence preserves claim and prevents duplicate XP', () async {
      final testDate = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(testDate);

      dailyStats.updateActivityForDate('2026-10-05', workoutsCompleted: 3);
      await questService.recomputeAndClaimRewards(atDate: testDate);

      final xpAfterFirstClaim = gamification.xp;

      // Reinitialize service (simulate app restart)
      await questService.init();

      // Ensure claimed state is loaded from disk
      expect(questService.isQuestClaimed('2026-W41', 'weekly_workouts'), isTrue);

      // Recomputing again must not add XP
      await questService.recomputeAndClaimRewards(atDate: testDate);
      expect(gamification.xp, xpAfterFirstClaim);
    });

    test('new week creates fresh quests and allows earning reward in the new week', () async {
      final week41Date = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(week41Date);

      // Complete workout quest in Week 41
      dailyStats.updateActivityForDate('2026-10-05', workoutsCompleted: 3);
      await questService.recomputeAndClaimRewards(atDate: week41Date);

      final xpWeek41 = gamification.xp;
      expect(questService.isQuestClaimed('2026-W41', 'weekly_workouts'), isTrue);

      // Advance to Week 42 (Monday Oct 12)
      final week42Date = DateTime(2026, 10, 13);
      questService.setMockCurrentDate(week42Date);

      // Week 42 starts with 0 progress
      final w42QuestsBefore = questService.getQuestsForWeek(atDate: week42Date);
      final w42WorkoutBefore = w42QuestsBefore.firstWhere((q) => q.id == 'weekly_workouts');
      expect(w42WorkoutBefore.current, 0);
      expect(w42WorkoutBefore.isClaimed, isFalse);
      expect(questService.isQuestClaimed('2026-W42', 'weekly_workouts'), isFalse);

      // Complete workout quest in Week 42
      dailyStats.updateActivityForDate('2026-10-12', workoutsCompleted: 3);
      await questService.recomputeAndClaimRewards(atDate: week42Date);

      // Another 150 XP awarded for Week 42
      expect(gamification.xp, xpWeek41 + 150);
      expect(questService.isQuestClaimed('2026-W42', 'weekly_workouts'), isTrue);
    });

    test('handles missing or malformed JSON storage safely without crashing', () async {
      // Write corrupted JSON
      final file = File('${tempDir.path}/genfit_weekly_quests.json');
      file.writeAsStringSync('{ invalid json content %%% ');

      // Init should safely recover and not throw
      await questService.init();
      expect(questService.claimedRewardKeys.isEmpty, isTrue);
    });
  });

  group('Weekly Quest Board UI & Entry Point Tests', () {
    testWidgets('WeeklyQuestBoardCard renders week info, summary, and all 5 quests', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testDate = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(testDate);

      await tester.pumpWidget(
        buildTestWidget(
          WeeklyQuestBoardCard(questService: questService),
        ),
      );
      await tester.pumpAndSettle();

      // Header info
      expect(find.text('Weekly Quest Board'), findsOneWidget);
      expect(find.text('Week 41'), findsOneWidget);
      expect(find.text('0 of 5 Quests Completed'), findsOneWidget);

      // All 5 Quests
      expect(find.text('Campus Iron'), findsOneWidget);
      expect(find.text('Campus Trekker'), findsOneWidget);
      expect(find.text('Rep Centurion'), findsOneWidget);
      expect(find.text('Nutrient Discipline'), findsOneWidget);
      expect(find.text('Active Rush'), findsOneWidget);

      // XP badges
      expect(find.text('+150 XP'), findsNWidgets(5));
    });

    testWidgets('WeeklyQuestBoardSheet displays correctly and dismissal is read-only', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testDate = DateTime(2026, 10, 9);
      questService.setMockCurrentDate(testDate);

      final initialXp = gamification.xp;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => WeeklyQuestBoardSheet.show(
                  context,
                  questService: questService,
                ),
                child: const Text('Open Board'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Board'));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Quests'), findsOneWidget);
      expect(find.text('Campus Iron'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Quests'), findsNothing);

      // State and XP must be unchanged
      expect(gamification.xp, initialXp);
    });

    testWidgets('DailyChallengeCard opens WeeklyQuestBoardSheet when button tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final challenge = gamification.activeChallenge;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => DailyChallengeCard(
                challenge: challenge,
                onComplete: () {},
                onWeeklyQuestsTap: () => WeeklyQuestBoardSheet.show(
                  context,
                  questService: questService,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly Quest Board'), findsOneWidget);

      // Tap Weekly Quest Board button
      await tester.tap(find.text('Weekly Quest Board'));
      await tester.pumpAndSettle();

      // Sheet opens
      expect(find.text('Weekly Quests'), findsOneWidget);
      expect(find.text('Campus Iron'), findsOneWidget);
    });

    test('existing daily challenges, badges, and rank systems remain unaffected', () async {
      final initialChallenges = gamification.challenges.length;
      final initialBadges = gamification.badges.length;
      final initialRanks = gamification.allTiers.length;

      expect(initialChallenges, 6);
      expect(initialBadges, 7);
      expect(initialRanks, 8);

      // Daily challenge progress
      await gamification.progressChallenge('c_campus_steps', delta: 500);
      expect(gamification.getChallengeById('c_campus_steps')?.progress, 500);

      // Weekly quest service operation does not alter challenge counts
      expect(gamification.challenges.length, initialChallenges);
      expect(gamification.badges.length, initialBadges);
      expect(gamification.allTiers.length, initialRanks);
    });
  });
}
