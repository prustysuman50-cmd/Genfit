import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/heritage_service.dart';
import 'package:genfit/models/heritage/heritage_journey.dart';
import 'package:genfit/models/heritage/heritage_milestone.dart';

void main() {
  group('Heritage Models Tests', () {
    test('HeritageMilestone creation, isReached, copyWith, and JSON serialization', () {
      const milestone = HeritageMilestone(
        id: 'dhauli_stupa',
        name: 'Dhauli Shanti Stupa',
        landmark: 'Dhauli Hills',
        shortDescription: 'Peace Pagoda',
        requiredDistanceKm: 8.5,
        requiredSteps: 8500,
        rewardXp: 50,
        badgeId: 'dhauli_badge',
        badgeName: 'Peace of Dhauli',
      );

      expect(milestone.id, equals('dhauli_stupa'));
      expect(milestone.isReached(5.0), isFalse);
      expect(milestone.isReached(8.5), isTrue);
      expect(milestone.isReached(10.0), isTrue);

      final updated = milestone.copyWith(isCompleted: true, isUnlocked: true);
      expect(updated.isCompleted, isTrue);
      expect(updated.isUnlocked, isTrue);
      expect(milestone.isCompleted, isFalse);

      final json = milestone.toJson();
      expect(json['id'], equals('dhauli_stupa'));
      expect(json['requiredDistanceKm'], equals(8.5));
      expect(json['rewardXp'], equals(50));

      final restored = HeritageMilestone.fromJson(json);
      expect(restored.id, equals(milestone.id));
      expect(restored.name, equals(milestone.name));
      expect(restored.requiredDistanceKm, equals(milestone.requiredDistanceKm));
      expect(restored.badgeName, equals(milestone.badgeName));
    });

    test('HeritageJourney creation, copyWith, and JSON serialization', () {
      final journey = HeritageJourney.showcaseLingarajToKonark;

      expect(journey.id, equals('heritage_lingaraj_konark'));
      expect(journey.totalDistanceKm, equals(65.0));
      expect(journey.milestones.length, equals(5));
      expect(journey.completionRewardXp, equals(250));

      final modified = journey.copyWith(title: 'Custom Title');
      expect(modified.title, equals('Custom Title'));
      expect(journey.title, equals('Lingaraj Temple → Konark Sun Temple'));

      final json = journey.toJson();
      expect(json['id'], equals('heritage_lingaraj_konark'));
      expect(json['totalDistanceKm'], equals(65.0));

      final restored = HeritageJourney.fromJson(json);
      expect(restored.id, equals(journey.id));
      expect(restored.title, equals(journey.title));
      expect(restored.milestones.length, equals(5));
    });
  });

  group('HeritageService Core Logic & DailyStats Integration Tests', () {
    late Directory tempDir;
    late HeritageService heritageService;
    late DailyStatsService statsService;
    late GamificationService gamificationService;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('heritage_test_');

      statsService = DailyStatsService.instance;
      statsService.setCustomStoragePath(tempDir.path);
      await statsService.init();

      gamificationService = GamificationService.instance;
      gamificationService.setCustomStoragePath(tempDir.path);
      await gamificationService.resetToDefaults();

      heritageService = HeritageService.instance;
      heritageService.setCustomStoragePath(tempDir.path);
      await heritageService.resetToDefaults();
      heritageService.attachDailyStatsListener(statsService);
    });

    tearDown(() {
      heritageService.setCustomStoragePath(null);
      heritageService.detachDailyStatsListener();
      statsService.setCustomStoragePath(null);
      gamificationService.setCustomStoragePath(null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Initial showcase route state with zero steps', () {
      expect(heritageService.activeJourneyId, equals('heritage_lingaraj_konark'));
      expect(heritageService.totalRouteDistanceKm, equals(65.0));
      expect(heritageService.currentDistanceKm, equals(0.0));
      expect(heritageService.progressPercent, equals(0.0));
      expect(heritageService.isCompleted, isFalse);

      final milestones = heritageService.activeJourney.milestones;
      expect(milestones[0].isCompleted, isTrue); // Start point
      expect(milestones[1].isCompleted, isFalse); // Dhauli
      expect(milestones[1].isUnlocked, isTrue); // Target unlocked
      expect(milestones[2].isUnlocked, isFalse); // Pipili locked

      expect(heritageService.currentTargetMilestone?.id, equals('dhauli_stupa'));
      expect(heritageService.remainingDistanceTo(milestones[1]), equals(8.5));
      expect(heritageService.remainingStepsTo(milestones[1]), equals(8500));
    });

    test('DailyStats steps reactively advance virtual distance and unlock milestone', () async {
      final initialXp = gamificationService.xp;

      // User walks 8,500 steps (8.5 km)
      await statsService.updateActivity(steps: 8500);
      await heritageService.syncMilestonesAndRewards();

      expect(heritageService.totalSteps, equals(8500));
      expect(heritageService.currentDistanceKm, equals(8.5));
      expect(heritageService.todayContributionKm, equals(8.5));

      final milestones = heritageService.activeJourney.milestones;
      // Dhauli Shanti Stupa is reached!
      expect(milestones[1].isCompleted, isTrue);
      // Next target Pipili is now unlocked
      expect(milestones[2].isUnlocked, isTrue);
      expect(heritageService.currentTargetMilestone?.id, equals('pipili_village'));

      // Awarded +100 XP and Journey Starter badge via GamificationService
      expect(gamificationService.xp, equals(initialXp + 100));
      expect(
        gamificationService.badges.any(
          (b) => b.id == 'journey_starter' && b.isUnlocked,
        ),
        isTrue,
      );
    });

    test('Idempotency: Repeated steps updates or syncs DO NOT award duplicate XP', () async {
      await statsService.updateActivity(steps: 8500);
      await heritageService.syncMilestonesAndRewards();
      final xpAfterFirstSync = gamificationService.xp;

      // Update with the same steps count again
      await statsService.updateActivity(steps: 8500);
      await heritageService.syncMilestonesAndRewards();
      expect(gamificationService.xp, equals(xpAfterFirstSync));

      // Re-init heritage service
      await heritageService.init();
      expect(gamificationService.xp, equals(xpAfterFirstSync));
    });

    test('Route completion clamps at total distance and awards completion reward once', () async {
      final initialXp = gamificationService.xp;

      // User walks 70,000 steps (exceeds 65,000 steps / 65.0 km)
      await statsService.updateActivity(steps: 70000);
      await heritageService.syncMilestonesAndRewards();

      expect(heritageService.currentDistanceKm, equals(65.0)); // Clamped
      expect(heritageService.progressPercent, equals(1.0));
      expect(heritageService.isCompleted, isTrue);

      final milestones = heritageService.activeJourney.milestones;
      for (final m in milestones) {
        expect(m.isCompleted, isTrue);
      }

      // Check cumulative milestone XP + completion XP
      // Milestones: Dhauli(100) + Pipili(100) + Nimapada(100) + Konark(100) = 400 XP
      // Journey completion = 250 XP
      // Total added XP = 400 + 250 = 650 XP
      expect(gamificationService.xp, equals(initialXp + 650));

      // Re-running does not duplicate
      await statsService.updateActivity(steps: 75000);
      await heritageService.syncMilestonesAndRewards();
      expect(gamificationService.xp, equals(initialXp + 650));
    });

    test('Switching active journeys updates active route and persists selection', () async {
      await heritageService.setActiveJourney('heritage_puri_chilika');

      expect(heritageService.activeJourneyId, equals('heritage_puri_chilika'));
      expect(heritageService.activeJourney.title, equals('Puri Jagannath → Chilika Lake'));
      expect(heritageService.totalRouteDistanceKm, equals(50.0));

      // Re-init restores the selected journey
      await heritageService.init();
      expect(heritageService.activeJourneyId, equals('heritage_puri_chilika'));
    });

    test('Persistence: Awarded rewards survive reload and prevent re-awarding', () async {
      await statsService.updateActivity(steps: 20000); // Reaches Dhauli (8.5 km) and Pipili (20.0 km)
      await heritageService.syncMilestonesAndRewards();
      final xp = gamificationService.xp;

      expect(heritageService.awardedMilestoneIds.contains('dhauli_stupa'), isTrue);
      expect(heritageService.awardedMilestoneIds.contains('pipili_village'), isTrue);

      // Create a fresh service instance pointing to the same file
      await heritageService.init();
      expect(heritageService.awardedMilestoneIds.contains('dhauli_stupa'), isTrue);
      expect(heritageService.awardedMilestoneIds.contains('pipili_village'), isTrue);
      expect(gamificationService.xp, equals(xp));
    });
  });
}
