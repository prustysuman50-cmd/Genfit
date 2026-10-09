import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/leaderboard_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/models/leaderboard/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry Model Tests', () {
    test('creates entry with defaults and explicit parameters', () {
      const entry = LeaderboardEntry(
        id: 'user_test',
        name: 'Soumya Ranjan',
        college: 'VSSUT Burla',
        campus: 'Burla Campus',
        hostel: 'Brahmaputra Hall',
        avatarInitials: 'SR',
        xp: 2500,
        weeklyXp: 450,
        level: 4,
        levelTitle: 'Campus Warrior',
        streakDays: 8,
        rank: 2,
        isCurrentUser: true,
        isConnected: true,
      );

      expect(entry.id, equals('user_test'));
      expect(entry.name, equals('Soumya Ranjan'));
      expect(entry.college, equals('VSSUT Burla'));
      expect(entry.campus, equals('Burla Campus'));
      expect(entry.hostel, equals('Brahmaputra Hall'));
      expect(entry.avatarInitials, equals('SR'));
      expect(entry.xp, equals(2500));
      expect(entry.weeklyXp, equals(450));
      expect(entry.level, equals(4));
      expect(entry.levelTitle, equals('Campus Warrior'));
      expect(entry.streakDays, equals(8));
      expect(entry.rank, equals(2));
      expect(entry.isCurrentUser, isTrue);
      expect(entry.isConnected, isTrue);
    });

    test('supports copyWith modifying specific fields', () {
      const original = LeaderboardEntry(
        id: 'entry_1',
        name: 'Aman',
        avatarInitials: 'AM',
        hostel: 'APJ Kalam Block',
        xp: 1800,
        level: 3,
        levelTitle: 'Fitness Seeker',
        streakDays: 4,
      );

      final updated = original.copyWith(
        rank: 1,
        xp: 2000,
        weeklyXp: 300,
        hostel: 'Mahanadi Hostel',
      );

      expect(updated.rank, equals(1));
      expect(updated.xp, equals(2000));
      expect(updated.weeklyXp, equals(300));
      expect(updated.hostel, equals('Mahanadi Hostel'));
      expect(updated.id, equals('entry_1'));
      expect(original.rank, equals(0));
    });

    test('serializes to and deserializes from JSON', () {
      const entry = LeaderboardEntry(
        id: 'student_rahul',
        name: 'Rahul Patel',
        college: 'GCEK',
        campus: 'GCEK Kalahandi',
        hostel: 'Brahmaputra Hall',
        avatarInitials: 'RP',
        xp: 4120,
        weeklyXp: 780,
        level: 5,
        levelTitle: 'Desi Beast',
        streakDays: 9,
        rank: 2,
        isCurrentUser: false,
        isConnected: true,
      );

      final json = entry.toJson();
      expect(json['id'], equals('student_rahul'));
      expect(json['hostel'], equals('Brahmaputra Hall'));
      expect(json['xp'], equals(4120));
      expect(json['weeklyXp'], equals(780));

      final restored = LeaderboardEntry.fromJson(json);
      expect(restored.id, equals(entry.id));
      expect(restored.name, equals(entry.name));
      expect(restored.hostel, equals(entry.hostel));
      expect(restored.xp, equals(entry.xp));
      expect(restored.weeklyXp, equals(entry.weeklyXp));
      expect(restored.rank, equals(entry.rank));
      expect(restored.isCurrentUser, isFalse);
    });
  });

  group('LeaderboardService Core Logic Tests', () {
    late Directory tempDir;
    final leaderboardService = LeaderboardService.instance;
    final userService = UserService.instance;
    final gamificationService = GamificationService.instance;
    final communityService = CommunityService.instance;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('leaderboard_test_');
      userService.setCustomStoragePath(tempDir.path);
      gamificationService.setCustomStoragePath(tempDir.path);
      communityService.setCustomStoragePath(tempDir.path);

      await userService.resetToDefaults();
      await gamificationService.resetToDefaults();
      await communityService.resetToDefaults();

      leaderboardService.resetFilters();
      leaderboardService.setFilter(LeaderboardFilter.campus);
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('XP sorting: campus entries are strictly sorted descending by XP', () {
      final entries = leaderboardService.getEntries(
        filter: LeaderboardFilter.campus,
      );

      expect(entries.length, greaterThan(1));
      for (int i = 0; i < entries.length - 1; i++) {
        expect(
          entries[i].xp >= entries[i + 1].xp,
          isTrue,
          reason:
              'Entry at $i (${entries[i].name}: ${entries[i].xp}) must be >= entry at ${i + 1} (${entries[i + 1].name}: ${entries[i + 1].xp})',
        );
      }
    });

    test('Rank calculation: ranks are sequential 1, 2, 3... corresponding to position', () {
      final entries = leaderboardService.getEntries(
        filter: LeaderboardFilter.campus,
      );

      for (int i = 0; i < entries.length; i++) {
        expect(entries[i].rank, equals(i + 1));
      }
    });

    test('Current user identification: accurately identifies current user and rank', () {
      final userEntry = leaderboardService.getCurrentUserEntry(
        filter: LeaderboardFilter.campus,
      );

      expect(userEntry.isCurrentUser, isTrue);
      expect(userEntry.name, equals(userService.currentUser.name));
      expect(userEntry.xp, equals(gamificationService.xp));
      expect(userEntry.level, equals(gamificationService.currentLevel));
      expect(userEntry.levelTitle, equals(gamificationService.levelTitle));
      expect(userEntry.streakDays, equals(gamificationService.streakDays));

      final calculatedRank = leaderboardService.getCurrentUserRank(
        filter: LeaderboardFilter.campus,
      );
      expect(userEntry.rank, equals(calculatedRank));
      expect(calculatedRank, greaterThan(0));
    });

    test(
      'Filter behavior: Campus filter includes all students plus current user',
      () {
        final entries = leaderboardService.getEntries(
          filter: LeaderboardFilter.campus,
        );

        final hasCurrentUser = entries.any((e) => e.isCurrentUser);
        expect(hasCurrentUser, isTrue);
        // 8 mock students + 1 current user = 9 entries
        expect(entries.length, equals(9));
      },
    );

    test('Filter behavior: Friends filter includes only connected peers and current user', () {
      final entries = leaderboardService.getEntries(
        filter: LeaderboardFilter.friends,
      );

      final hasCurrentUser = entries.any((e) => e.isCurrentUser);
      expect(hasCurrentUser, isTrue);

      // In default mock data, Rahul, Priya, Sneha are connected (3 friends + current user = 4 entries)
      for (final entry in entries) {
        if (!entry.isCurrentUser) {
          expect(entry.isConnected, isTrue);
        }
      }
      expect(entries.length, equals(4));

      // Check ranks are re-indexed 1..4
      for (int i = 0; i < entries.length; i++) {
        expect(entries[i].rank, equals(i + 1));
      }
    });

    test(
      'Filter behavior: Weekly filter sorts students by weekly XP descending',
      () {
        final entries = leaderboardService.getEntries(
          filter: LeaderboardFilter.weekly,
        );

        expect(entries.length, equals(9));
        for (int i = 0; i < entries.length - 1; i++) {
          expect(
            entries[i].weeklyXp >= entries[i + 1].weeklyXp,
            isTrue,
            reason: 'Weekly XP must sort descending',
          );
        }
      },
    );

    test('Podium helpers: getTopThree returns exactly 3 entries with ranks 1, 2, 3', () {
      final topThree = leaderboardService.getTopThree(
        filter: LeaderboardFilter.campus,
      );

      expect(topThree.length, equals(3));
      expect(topThree[0].rank, equals(1));
      expect(topThree[1].rank, equals(2));
      expect(topThree[2].rank, equals(3));
    });

    test('Remaining helpers: getRemainingEntries returns entries from rank 4 onwards', () {
      final remaining = leaderboardService.getRemainingEntries(
        filter: LeaderboardFilter.campus,
      );

      expect(remaining.length, equals(6)); // 9 total - 3 top
      expect(remaining.first.rank, equals(4));
      expect(remaining.last.rank, equals(9));
    });

    test('Dynamic integration: when current user gains XP, leaderboard updates rank', () async {
      final initialRank = leaderboardService.getCurrentUserRank(
        filter: LeaderboardFilter.campus,
      );

      // Award massive XP to make user rank #1 (surpassing Ananya's 4800 XP)
      await gamificationService.addXp(6000);

      final newRank = leaderboardService.getCurrentUserRank(
        filter: LeaderboardFilter.campus,
      );
      final updatedUserEntry = leaderboardService.getCurrentUserEntry(
        filter: LeaderboardFilter.campus,
      );

      expect(updatedUserEntry.xp, equals(gamificationService.xp));
      expect(newRank, lessThanOrEqualTo(initialRank));
      expect(newRank, equals(1)); // With 6000 XP, user is #1
    });

    test('Dynamic integration: when current user edits profile name/college, leaderboard reflects changes', () async {
      await userService.updateFields(
        name: 'Pragyan Nayak',
        college: 'NIT Rourkela',
        campus: 'Rourkela Campus',
        avatarInitials: 'PN',
      );

      final entry = leaderboardService.getCurrentUserEntry(
        filter: LeaderboardFilter.campus,
      );

      expect(entry.name, equals('Pragyan Nayak'));
      expect(entry.college, equals('NIT Rourkela'));
      expect(entry.avatarInitials, equals('PN'));
    });

    // -------------------------------------------------------------
    // PHASE A STEP A1: SOCIAL LEADERBOARD (HOSTEL & COLLEGE) TESTS
    // -------------------------------------------------------------
    test('Inter-Hostel mode: assigns realistic hostels and sorts participants', () {
      leaderboardService.setMode(LeaderboardMode.interHostel);
      expect(leaderboardService.currentMode, equals(LeaderboardMode.interHostel));

      final entries = leaderboardService.getEntries(
        mode: LeaderboardMode.interHostel,
      );

      expect(entries.length, equals(9));
      for (final entry in entries) {
        expect(entry.hostel.isNotEmpty, isTrue);
      }

      // Check top student has highest XP
      expect(entries.first.xp, greaterThanOrEqualTo(entries[1].xp));
      // Ranks are sequential
      for (int i = 0; i < entries.length; i++) {
        expect(entries[i].rank, equals(i + 1));
      }
    });

    test('Inter-College mode: assigns realistic colleges and sorts participants', () {
      leaderboardService.setMode(LeaderboardMode.interCollege);
      expect(leaderboardService.currentMode, equals(LeaderboardMode.interCollege));

      final entries = leaderboardService.getEntries(
        mode: LeaderboardMode.interCollege,
      );

      expect(entries.length, equals(9));
      for (final entry in entries) {
        expect(entry.college.isNotEmpty, isTrue);
      }

      // Check current user is included
      final userEntry = entries.firstWhere((e) => e.isCurrentUser);
      expect(userEntry.college, equals(userService.currentUser.college));
    });

    test('Inter-Hostel filtering: filters by specific hostel accurately', () {
      // Filter strictly by 'Mahanadi Hostel'
      // Priya Sharma (3250 XP) and current user Ayush (3850 XP) belong to Mahanadi Hostel
      final entries = leaderboardService.getEntries(
        mode: LeaderboardMode.interHostel,
        hostelFilter: 'Mahanadi Hostel',
      );

      expect(entries.length, equals(2));
      for (final entry in entries) {
        expect(entry.hostel, equals('Mahanadi Hostel'));
      }

      // Priya Sharma has 3250 XP, current user has 0 XP after reset -> Priya is #1, current user is #2
      expect(entries[0].name, equals('Priya Sharma'));
      expect(entries[0].rank, equals(1));
      expect(entries[1].isCurrentUser, isTrue);
      expect(entries[1].rank, equals(2));
    });

    test('Inter-College filtering: filters by specific college accurately', () {
      // Filter strictly by 'NIT Rourkela' (Ananya Nayak, 4800 XP)
      final entries = leaderboardService.getEntries(
        mode: LeaderboardMode.interCollege,
        collegeFilter: 'NIT Rourkela',
      );

      expect(entries.length, equals(1));
      expect(entries.first.name, equals('Ananya Nayak'));
      expect(entries.first.college, equals('NIT Rourkela'));
      expect(entries.first.rank, equals(1));
    });

    test('Deterministic demo data: repeated calls produce identical ranking and data', () {
      final run1 = leaderboardService.getEntries(mode: LeaderboardMode.interHostel);
      final run2 = leaderboardService.getEntries(mode: LeaderboardMode.interHostel);

      expect(run1.length, equals(run2.length));
      for (int i = 0; i < run1.length; i++) {
        expect(run1[i].id, equals(run2[i].id));
        expect(run1[i].name, equals(run2[i].name));
        expect(run1[i].xp, equals(run2[i].xp));
        expect(run1[i].hostel, equals(run2[i].hostel));
        expect(run1[i].college, equals(run2[i].college));
        expect(run1[i].rank, equals(run2[i].rank));
      }
    });

    test('Dynamic user hostel integration: reflects user profile hostel updates', () async {
      await userService.updateFields(hostel: 'Brahmaputra Hall');

      final userEntry = leaderboardService.getCurrentUserEntry(
        mode: LeaderboardMode.interHostel,
      );

      expect(userEntry.hostel, equals('Brahmaputra Hall'));
    });

    test('Available hostel and college lists contain distinct options including All', () {
      final hostels = leaderboardService.getAvailableHostels();
      expect(hostels, contains('All'));
      expect(hostels, contains('Mahanadi Hostel'));
      expect(hostels, contains('Brahmaputra Hall'));
      expect(hostels, contains('Sarojini Naidu Hall'));

      final colleges = leaderboardService.getAvailableColleges();
      expect(colleges, contains('All'));
      expect(colleges, contains('NIT Rourkela'));
      expect(colleges, contains('GCEK Kalahandi'));
    });
  });
}
