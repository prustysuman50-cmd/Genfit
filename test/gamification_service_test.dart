import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/models/gamification/gamification_rewards.dart';

void main() {
  late Directory tempDir;
  final service = GamificationService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gamification_test_');
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

  group('XP Rewards System Tests', () {
    test('constants are centralized with specified values', () {
      expect(GamificationRewards.workoutCompleted, 100);
      expect(GamificationRewards.mealLogged, 20);
      expect(GamificationRewards.dailyChallengeCompleted, 50);
      expect(GamificationRewards.journeyMilestone, 100);
    });

    test('completed workout awards +100 XP', () async {
      expect(service.xp, 0);
      await service.recordWorkoutCompleted();
      expect(service.xp, 100);
    });

    test('logged meal awards +20 XP', () async {
      expect(service.xp, 0);
      await service.recordMealLogged();
      expect(service.xp, 20);
    });

    test('completed journey milestone awards +100 XP', () async {
      expect(service.xp, 0);
      await service.recordJourneyMilestone('puri_beach_run');
      expect(service.xp, 100);
    });

    test('addXp increments total accurately', () async {
      await service.addXp(250);
      expect(service.xp, 250);
      await service.addXp(50);
      expect(service.xp, 300);
    });
  });

  group('Level System Tests', () {
    test(
      'calculates levels and titles based on prototype thresholds',
      () async {
        // Level 1: 0 - 499 (Campus Rookie)
        expect(service.currentLevel, 1);
        expect(service.levelTitle, 'Campus Rookie');
        expect(service.nextLevelXp, 500);

        // Level 2: 500 - 1199 (Hostel Hustler)
        await service.addXp(500);
        expect(service.currentLevel, 2);
        expect(service.levelTitle, 'Hostel Hustler');
        expect(service.nextLevelXp, 1200);

        // Level 3: 1200 - 2199 (Fitness Seeker)
        await service.addXp(700);
        expect(service.currentLevel, 3);
        expect(service.levelTitle, 'Fitness Seeker');
        expect(service.nextLevelXp, 2200);

        // Level 4: 2200 - 3499 (Campus Warrior)
        await service.addXp(1000);
        expect(service.currentLevel, 4);
        expect(service.levelTitle, 'Campus Warrior');
        expect(service.nextLevelXp, 3500);

        // Level 5: 3500 - 4999 (Desi Beast)
        await service.addXp(1300);
        expect(service.currentLevel, 5);
        expect(service.levelTitle, 'Desi Beast');
        expect(service.nextLevelXp, 5000);

        // Level 6: 5000+ (Odisha Titan)
        await service.addXp(1500);
        expect(service.currentLevel, 6);
        expect(service.levelTitle, 'Odisha Titan');
      },
    );

    test('calculates XP required for next level', () async {
      // At 0 XP, Level 1 requires 500 XP
      expect(service.xpRequiredForNextLevel, 500);

      await service.addXp(200);
      expect(service.xpRequiredForNextLevel, 300);

      await service.addXp(300); // Now 500 XP (Level 2: 500-1200)
      expect(service.xpRequiredForNextLevel, 700);
    });

    test('calculates level progress from 0.0 to 1.0', () async {
      expect(service.levelProgress, 0.0);

      // Halfway through Level 1 (250 / 500)
      await service.addXp(250);
      expect(service.levelProgress, closeTo(0.5, 0.01));

      // Reaching Level 2 (500 XP) -> resets progress in Level 2 to 0.0
      await service.addXp(250);
      expect(service.levelProgress, 0.0);

      // Halfway through Level 2 (500 + 350 = 850 XP in span 500-1200)
      await service.addXp(350);
      expect(service.levelProgress, closeTo(0.5, 0.01));
    });
  });

  group('Streak System Tests', () {
    test('first active day starts a 1-day streak', () {
      expect(service.streakDays, 0);
      service.recordActivity(atDate: DateTime(2026, 9, 1));
      expect(service.streakDays, 1);
      expect(service.lastActiveDate, DateTime(2026, 9, 1));
    });

    test('consecutive active days increase the streak', () {
      service.recordActivity(atDate: DateTime(2026, 9, 1));
      expect(service.streakDays, 1);

      service.recordActivity(atDate: DateTime(2026, 9, 2));
      expect(service.streakDays, 2);

      service.recordActivity(atDate: DateTime(2026, 9, 3));
      expect(service.streakDays, 3);
    });

    test('multiple actions on the same day do not increase streak', () {
      service.recordActivity(atDate: DateTime(2026, 9, 1));
      expect(service.streakDays, 1);

      // Second and third activity on same calendar date
      service.recordActivity(atDate: DateTime(2026, 9, 1));
      expect(service.streakDays, 1);

      service.recordActivity(atDate: DateTime(2026, 9, 1));
      expect(service.streakDays, 1);
    });

    test('missing a calendar day resets the streak', () {
      // Day 1 & Day 2 active -> streak = 2
      service.recordActivity(atDate: DateTime(2026, 9, 1));
      service.recordActivity(atDate: DateTime(2026, 9, 2));
      expect(service.streakDays, 2);

      // Missed Sept 3rd! Activity happens on Sept 4th
      service.recordActivity(atDate: DateTime(2026, 9, 4));
      expect(service.streakDays, 1);
    });

    test('checkStreakReset flags inactive streak if day was missed', () {
      service.recordActivity(atDate: DateTime(2026, 9, 1));
      expect(service.streakDays, 1);

      // Checking on Sept 3 (gap of 2 days without activity)
      service.checkStreakReset(currentDate: DateTime(2026, 9, 3));
      expect(service.streakDays, 0);
    });
  });

  group('Badges System Tests', () {
    test('contains all 7 required badges', () {
      final badges = service.badges;
      expect(badges.length, 7);

      final expectedIds = [
        'first_workout',
        'seven_day_streak',
        'hundred_reps',
        'first_meal_logged',
        'campus_challenger',
        'journey_starter',
        'odisha_explorer',
      ];

      for (final id in expectedIds) {
        final b = service.getBadgeById(id);
        expect(b, isNotNull, reason: 'Missing badge: $id');
        expect(b!.isUnlocked, isFalse);
      }
    });

    test('unlocks First Workout badge on completing first workout', () async {
      await service.recordWorkoutCompleted();
      final badge = service.getBadgeById('first_workout');
      expect(badge?.isUnlocked, isTrue);
      expect(badge?.unlockedAt, isNotNull);
    });

    test('unlocks First Meal Logged badge on logging a meal', () async {
      await service.recordMealLogged();
      final badge = service.getBadgeById('first_meal_logged');
      expect(badge?.isUnlocked, isTrue);
    });

    test('unlocks 100 Reps badge after accumulating 100 reps', () async {
      await service.recordWorkoutCompleted(reps: 60);
      expect(service.getBadgeById('hundred_reps')?.isUnlocked, isFalse);

      await service.recordWorkoutCompleted(reps: 45);
      expect(service.getBadgeById('hundred_reps')?.isUnlocked, isTrue);
    });

    test('unlocks 7 Day Streak badge when streak reaches 7', () {
      for (int i = 1; i <= 7; i++) {
        service.recordActivity(atDate: DateTime(2026, 9, i));
      }
      expect(service.streakDays, 7);
      expect(service.getBadgeById('seven_day_streak')?.isUnlocked, isTrue);
    });

    test('unlocks Journey Starter and Odisha Explorer badges', () async {
      await service.recordJourneyMilestone('milestone_1');
      expect(service.getBadgeById('journey_starter')?.isUnlocked, isTrue);
      expect(service.getBadgeById('odisha_explorer')?.isUnlocked, isFalse);

      await service.recordJourneyMilestone('milestone_2');
      await service.recordJourneyMilestone('milestone_3');
      expect(service.getBadgeById('odisha_explorer')?.isUnlocked, isTrue);
    });
  });

  group('Daily Challenges Tests', () {
    test('contains required challenges', () {
      final challenges = service.challenges;
      expect(challenges.isNotEmpty, isTrue);

      final titles = challenges.map((c) => c.title).toList();
      expect(titles, contains('7 Day Streak'));
      expect(titles, contains('100 Squats'));
      expect(titles, contains('10K Steps'));
      expect(titles, contains('Weekend Workout'));
      expect(titles, contains('Campus Champion'));
    });

    test(
      'progressChallenge updates progress and does not exceed target',
      () async {
        final challenge = service.getChallengeById('c_weekend_workout')!;
        expect(challenge.progress, 0);

        await service.progressChallenge('c_weekend_workout', delta: 1);
        final updated = service.getChallengeById('c_weekend_workout')!;
        expect(updated.progress, 1);
        expect(updated.isCompleted, isTrue);
      },
    );

    test('completing a challenge awards reward XP and unlocks badge', () async {
      expect(service.xp, 0);
      expect(service.getBadgeById('campus_challenger')?.isUnlocked, isFalse);

      await service.completeChallenge('c_weekend_workout');

      final updated = service.getChallengeById('c_weekend_workout')!;
      expect(updated.isCompleted, isTrue);
      expect(service.xp, 75); // Reward XP for weekend workout
      expect(service.getBadgeById('campus_challenger')?.isUnlocked, isTrue);
    });
  });

  group('Persistence Roundtrip Tests', () {
    test(
      'persists XP, streak, badges, and challenges to disk and restores',
      () async {
        // Perform various actions
        await service.addXp(120);
        service.recordActivity(atDate: DateTime(2026, 9, 1));
        service.recordActivity(atDate: DateTime(2026, 9, 2));
        await service.recordWorkoutCompleted(reps: 110);
        await service.recordMealLogged();
        await service.completeChallenge('c_weekend_workout');

        final savedXp = service.xp;
        final savedStreak = service.streakDays;
        expect(service.getBadgeById('first_workout')?.isUnlocked, isTrue);
        expect(service.getBadgeById('hundred_reps')?.isUnlocked, isTrue);
        expect(service.getBadgeById('first_meal_logged')?.isUnlocked, isTrue);
        expect(
          service.getChallengeById('c_weekend_workout')?.isCompleted,
          isTrue,
        );

        // Verify file exists on disk
        final file = File('${tempDir.path}/genfit_gamification.json');
        expect(file.existsSync(), isTrue);
        final jsonContent = file.readAsStringSync();
        expect(jsonContent, contains('first_workout'));
        expect(jsonContent, contains('c_weekend_workout'));

        // Simulate app restart by re-initializing service
        await service.init();

        expect(service.xp, savedXp);
        expect(service.streakDays, savedStreak);
        expect(service.getBadgeById('first_workout')?.isUnlocked, isTrue);
        expect(service.getBadgeById('hundred_reps')?.isUnlocked, isTrue);
        expect(service.getBadgeById('first_meal_logged')?.isUnlocked, isTrue);
        expect(
          service.getChallengeById('c_weekend_workout')?.isCompleted,
          isTrue,
        );
      },
    );
  });
}
