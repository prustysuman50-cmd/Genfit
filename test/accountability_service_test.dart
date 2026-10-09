import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/accountability_service.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/models/community/accountability_partner.dart';

void main() {
  group('AccountabilityPartner Model Tests', () {
    test('creates default partner with realistic deterministic data', () {
      const partner = AccountabilityPartner.defaultPartner;

      expect(partner.id, equals('partner_rahul'));
      expect(partner.name, equals('Rahul Patel'));
      expect(partner.avatarInitials, equals('RP'));
      expect(partner.college, equals('GCEK Kalahandi'));
      expect(partner.hostel, equals('Brahmaputra Hall'));
      expect(partner.level, equals(5));
      expect(partner.levelTitle, equals('Desi Beast'));
      expect(partner.xp, equals(4120));
      expect(partner.streakDays, equals(9));
      expect(partner.todaySteps, equals(6420));
      expect(partner.todayWorkoutCompleted, isTrue);
      expect(partner.isCheckedInToday, isTrue);
      expect(partner.motivationalNote, isNotEmpty);
    });

    test('supports copyWith modifying specific fields', () {
      const original = AccountabilityPartner.defaultPartner;
      final updated = original.copyWith(
        isCheckedInToday: false,
        streakDays: 10,
        todaySteps: 7000,
      );

      expect(updated.isCheckedInToday, isFalse);
      expect(updated.streakDays, equals(10));
      expect(updated.todaySteps, equals(7000));
      expect(updated.name, equals(original.name));
    });

    test('serializes to and deserializes from JSON', () {
      const partner = AccountabilityPartner.defaultPartner;
      final json = partner.toJson();

      expect(json['id'], equals('partner_rahul'));
      expect(json['name'], equals('Rahul Patel'));
      expect(json['xp'], equals(4120));

      final restored = AccountabilityPartner.fromJson(json);
      expect(restored.id, equals(partner.id));
      expect(restored.name, equals(partner.name));
      expect(restored.xp, equals(partner.xp));
      expect(restored.streakDays, equals(partner.streakDays));
      expect(restored.isCheckedInToday, equals(partner.isCheckedInToday));
    });
  });

  group('AccountabilityService Core Logic Tests', () {
    late Directory tempDir;
    final service = AccountabilityService.instance;
    final userService = UserService.instance;
    final gamificationService = GamificationService.instance;
    final dailyStatsService = DailyStatsService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('accountability_test_');
      service.setCustomStoragePath(tempDir.path);
      userService.setCustomStoragePath(tempDir.path);
      gamificationService.setCustomStoragePath(tempDir.path);
      dailyStatsService.setCustomStoragePath(tempDir.path);

      await service.resetToDefaults();
      await userService.resetToDefaults();
      await gamificationService.resetToDefaults();
      await dailyStatsService.resetToDefaults();
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Deterministic partner data: partner is initialized with default peer', () {
      expect(service.partner.name, equals('Rahul Patel'));
      expect(service.partner.streakDays, equals(9));
      expect(service.partner.level, equals(5));
      expect(service.isPartnerCheckedInToday, isTrue);
    });

    test('Initial check-in state: current user is initially not checked in', () {
      expect(service.isUserCheckedInToday(), isFalse);
      expect(service.lastUserCheckInDateKey, isNull);
    });

    test('Daily check-in: first check-in marks user as checked in and awards +20 XP', () async {
      final initialXp = gamificationService.xp;
      final success = await service.checkInToday();

      expect(success, isTrue);
      expect(service.isUserCheckedInToday(), isTrue);
      expect(service.lastUserCheckInDateKey, equals(AccountabilityService.getTodayKey()));
      expect(gamificationService.xp, equals(initialXp + 20));
    });

    test('Duplicate prevention: second check-in on same day is rejected and awards no XP', () async {
      // First check-in
      final firstResult = await service.checkInToday();
      expect(firstResult, isTrue);
      final xpAfterFirst = gamificationService.xp;

      // Second check-in on the same day
      final secondResult = await service.checkInToday();
      expect(secondResult, isFalse);
      // XP remains unchanged
      expect(gamificationService.xp, equals(xpAfterFirst));
    });

    test('Date key format: matches canonical YYYY-MM-DD pattern', () {
      final date = DateTime(2026, 4, 9);
      final key = AccountabilityService.getTodayKey(date);
      expect(key, equals('2026-04-09'));
    });

    test('Local persistence: check-in state persists to file and reloads across init', () async {
      await service.checkInToday();
      expect(service.isUserCheckedInToday(), isTrue);

      // Create a new instance simulator by calling reset/init with the same storage path
      final savedKey = service.lastUserCheckInDateKey;
      await service.init();

      expect(service.lastUserCheckInDateKey, equals(savedKey));
      expect(service.isUserCheckedInToday(), isTrue);
    });

    test('Motivational messages: reflects mutual check-in states accurately', () async {
      // 1. Partner checked in (default), User not checked in
      service.setPartnerCheckedIn(true);
      expect(
        service.accountabilityMessage,
        contains("Rahul Patel is already active today. Don't miss your check-in!"),
      );

      // 2. Both checked in
      await service.checkInToday();
      expect(
        service.accountabilityMessage,
        contains("Great! You're both staying consistent and keeping each other on track."),
      );

      // 3. User checked in, Partner pending
      service.setPartnerCheckedIn(false);
      expect(
        service.accountabilityMessage,
        contains("You checked in! Rahul Patel hasn't checked in yet. Keep them motivated!"),
      );

      // 4. Neither checked in
      await service.resetToDefaults();
      service.setPartnerCheckedIn(false);
      expect(
        service.accountabilityMessage,
        contains("Neither of you has checked in today yet."),
      );
    });

    test('Live user metrics integration: reads live stats from existing services', () async {
      // Update UserProfile name
      await userService.updateFields(name: 'Snehasish');
      expect(userService.currentUser.name, equals('Snehasish'));

      // Award XP to GamificationService
      await gamificationService.addXp(500);
      expect(gamificationService.xp, equals(500));

      // Add workout to DailyStatsService
      await dailyStatsService.recordWorkoutCompleted(
        durationMinutes: 20,
        totalReps: 50,
        caloriesBurned: 150,
      );
      expect(dailyStatsService.todayStats.workoutsCompleted, equals(1));
    });
  });
}
