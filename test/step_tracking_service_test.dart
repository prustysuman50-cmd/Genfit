import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/heritage_service.dart';
import 'package:genfit/core/services/step_tracking_service.dart';

void main() {
  group('StepTrackingService Core Logic & Sensor Math Tests', () {
    late Directory tempDir;
    late StepTrackingService stepService;
    late DailyStatsService statsService;
    late GamificationService gamificationService;
    late HeritageService heritageService;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('step_tracking_test_');

      statsService = DailyStatsService.instance;
      statsService.setCustomStoragePath(tempDir.path);
      await statsService.resetToDefaults();

      gamificationService = GamificationService.instance;
      gamificationService.setCustomStoragePath(tempDir.path);
      await gamificationService.resetToDefaults();

      heritageService = HeritageService.instance;
      heritageService.setCustomStoragePath(tempDir.path);
      await heritageService.resetToDefaults();
      heritageService.attachDailyStatsListener(statsService);

      stepService = StepTrackingService.instance;
      stepService.setPlatformSensorEnabled(false);
      stepService.setCustomStoragePath(tempDir.path);
      await stepService.resetToDefaults();
      await stepService.init();
    });

    tearDown(() {
      stepService.setCustomStoragePath(null);
      statsService.setCustomStoragePath(null);
      gamificationService.setCustomStoragePath(null);
      heritageService.setCustomStoragePath(null);
      heritageService.detachDailyStatsListener();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. Initial service state & Live mode default', () {
      expect(stepService.isInitialized, isTrue);
      expect(stepService.currentMode, equals(StepTrackingMode.liveSensor));
      expect(stepService.todayTrackedSteps, equals(0));
      expect(stepService.dayStartBaseline, isNull);
      expect(stepService.lastRawSensorValue, isNull);
      expect(stepService.rebootPreservedSteps, equals(0));
    });

    test('2. Mode switching between Live Sensor and Demo Simulation', () async {
      expect(stepService.currentMode, equals(StepTrackingMode.liveSensor));

      await stepService.setMode(StepTrackingMode.demoSimulation);
      expect(stepService.currentMode, equals(StepTrackingMode.demoSimulation));
      expect(stepService.statusMessage, contains('Demo Simulation Mode'));

      await stepService.setMode(StepTrackingMode.liveSensor);
      expect(stepService.currentMode, equals(StepTrackingMode.liveSensor));
      expect(stepService.statusMessage, contains('Live Sensor Mode'));
    });

    test('3. First baseline capture establishes day-start baseline', () async {
      final now = DateTime(2026, 10, 9, 8, 0);
      final steps = await stepService.processRawSensorReading(15000, now: now);

      expect(steps, equals(0));
      expect(stepService.dayStartBaseline, equals(15000));
      expect(stepService.lastRawSensorValue, equals(15000));
      expect(stepService.todayTrackedSteps, equals(0));
      expect(statsService.todayStats.steps, equals(0));
    });

    test('4. Normal cumulative sensor delta advances today steps', () async {
      final t0 = DateTime(2026, 10, 9, 8, 0);
      await stepService.processRawSensorReading(15000, now: t0);

      // User walks 1,250 steps
      final t1 = DateTime(2026, 10, 9, 9, 30);
      final steps = await stepService.processRawSensorReading(16250, now: t1);

      expect(steps, equals(1250));
      expect(stepService.todayTrackedSteps, equals(1250));
      expect(stepService.dayStartBaseline, equals(15000));
      expect(stepService.lastRawSensorValue, equals(16250));
      expect(statsService.todayStats.steps, equals(1250));

      // User walks an additional 2,000 steps
      final t2 = DateTime(2026, 10, 9, 11, 0);
      final steps2 = await stepService.processRawSensorReading(18250, now: t2);

      expect(steps2, equals(3250));
      expect(stepService.todayTrackedSteps, equals(3250));
      expect(statsService.todayStats.steps, equals(3250));
    });

    test('5. Repeated sensor readings do not double-count (idempotency)', () async {
      final now = DateTime(2026, 10, 9, 8, 0);
      await stepService.processRawSensorReading(10000, now: now);

      await stepService.processRawSensorReading(12000, now: now);
      expect(statsService.todayStats.steps, equals(2000));

      // Sensor emits same reading again (e.g. idle device event)
      await stepService.processRawSensorReading(12000, now: now);
      expect(statsService.todayStats.steps, equals(2000));
      expect(stepService.todayTrackedSteps, equals(2000));
    });

    test('6. App restart recovery from persisted baseline', () async {
      final now = DateTime(2026, 10, 9, 8, 0);
      await stepService.processRawSensorReading(20000, now: now);
      await stepService.processRawSensorReading(23500, now: now);
      expect(statsService.todayStats.steps, equals(3500));

      // Simulate app kill & relaunch (re-init service from storage)
      await stepService.init();

      expect(stepService.dayStartBaseline, equals(20000));
      expect(stepService.lastRawSensorValue, equals(23500));
      expect(stepService.todayTrackedSteps, equals(3500));

      // New reading arrives while phone stayed on
      await stepService.processRawSensorReading(25000, now: now);
      expect(statsService.todayStats.steps, equals(5000));
      expect(stepService.todayTrackedSteps, equals(5000));
    });

    test('7. Calendar-day rollover resets today steps without altering history', () async {
      final day1 = DateTime(2026, 10, 9, 18, 0);
      await stepService.processRawSensorReading(10000, now: day1);
      await stepService.processRawSensorReading(14000, now: day1);
      expect(statsService.todayStats.steps, equals(4000));

      // Day changes to next day (2026-10-10)
      final day2 = DateTime(2026, 10, 10, 7, 0);
      final stepsDay2 = await stepService.processRawSensorReading(14500, now: day2);

      expect(stepsDay2, equals(0)); // Start of new day
      expect(stepService.dayStartBaseline, equals(14500));
      expect(stepService.rebootPreservedSteps, equals(0));
      expect(stepService.trackingDate, equals('2026-10-10'));

      // Later on day 2
      final stepsDay2Mid = await stepService.processRawSensorReading(16500, now: day2);
      expect(stepsDay2Mid, equals(2000));

      // Verify day 1 record remained 4000
      final day1Stats = statsService.getStatsForDate(day1);
      expect(day1Stats.steps, equals(4000));
    });

    test('8. Device reboot detection & preserved steps calculation', () async {
      final day = DateTime(2026, 10, 9, 9, 0);
      // Start of day
      await stepService.processRawSensorReading(30000, now: day);
      // Walk 2,500 steps
      await stepService.processRawSensorReading(32500, now: day);
      expect(statsService.todayStats.steps, equals(2500));

      // Phone is rebooted! Sensor resets to 50
      final rebootReading = 50;
      final stepsAfterReboot = await stepService.processRawSensorReading(rebootReading, now: day);

      expect(stepService.rebootPreservedSteps, equals(2500));
      expect(stepService.dayStartBaseline, equals(50));
      expect(stepService.lastRawSensorValue, equals(50));
      expect(stepsAfterReboot, equals(2500));
      expect(statsService.todayStats.steps, equals(2500));

      // User continues walking after reboot: takes 800 more steps
      final subsequentReading = 850;
      final totalSteps = await stepService.processRawSensorReading(subsequentReading, now: day);

      // Total = 2,500 (preserved) + (850 - 50) = 3,300
      expect(totalSteps, equals(3300));
      expect(statsService.todayStats.steps, equals(3300));
    });

    test('9. Live mode rejects manual/demo step injection', () async {
      expect(stepService.currentMode, equals(StepTrackingMode.liveSensor));

      final success = await stepService.injectDemoSteps(500);
      expect(success, isFalse);
      expect(statsService.todayStats.steps, equals(0));
    });

    test('10. Demo mode accepts simulated steps and pushes to DailyStatsService', () async {
      await stepService.setMode(StepTrackingMode.demoSimulation);

      final success = await stepService.injectDemoSteps(250);
      expect(success, isTrue);
      expect(stepService.todayTrackedSteps, equals(250));
      expect(statsService.todayStats.steps, equals(250));

      await stepService.injectDemoSteps(1000);
      expect(stepService.todayTrackedSteps, equals(1250));
      expect(statsService.todayStats.steps, equals(1250));
    });

    test('11. HeritageService reactively advances distance from step tracking', () async {
      final initialKm = heritageService.currentDistanceKm;
      expect(initialKm, equals(0.0));

      final now = DateTime(2026, 10, 9, 8, 0);
      await stepService.processRawSensorReading(10000, now: now);

      // Walk 8,500 steps (reaches Dhauli Shanti Stupa at 8.5 km)
      await stepService.processRawSensorReading(18500, now: now);

      expect(statsService.todayStats.steps, equals(8500));
      expect(heritageService.todaySteps, equals(8500));
      expect(heritageService.currentDistanceKm, equals(8.5));

      final milestones = heritageService.activeJourney.milestones;
      expect(milestones[1].isCompleted, isTrue); // Dhauli reached
    });

    test('12. GamificationService challenge reacts to step tracking', () async {
      final now = DateTime(2026, 10, 9, 8, 0);
      await stepService.processRawSensorReading(5000, now: now);

      // Walk 10,000 steps
      await stepService.processRawSensorReading(15000, now: now);
      await gamificationService.syncChallengesFromDailyStats(statsService.todayStats);

      final campusChallenge = gamificationService.getChallengeById('c_campus_steps');
      if (campusChallenge != null) {
        expect(campusChallenge.progress, greaterThan(0));
      }
    });

    test('13. StepTrackingService does NOT overwrite caloriesBurned or activeMinutes', () async {
      // User logged 45 active minutes and 320 calories from AI workout
      await statsService.updateActivity(activeMinutes: 45, caloriesBurned: 320);

      final now = DateTime(2026, 10, 9, 8, 0);
      await stepService.processRawSensorReading(10000, now: now);
      await stepService.processRawSensorReading(13000, now: now);

      expect(statsService.todayStats.steps, equals(3000));
      expect(statsService.todayStats.activeMinutes, equals(45));
      expect(statsService.todayStats.caloriesBurned, equals(320));
    });
  });
}
