import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/models/user_profile.dart';
import 'package:genfit/screens/gamification/widgets/campus_rank_roadmap_sheet.dart';
import 'package:genfit/screens/home/widgets/streak_xp_banner.dart';
import 'package:genfit/screens/profile/profile_screen.dart';

void main() {
  late Directory tempDir;
  final gamification = GamificationService.instance;
  final userService = UserService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('campus_rank_test_');
    gamification.setCustomStoragePath(tempDir.path);
    userService.setCustomStoragePath(tempDir.path);
    await gamification.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Campus Rank Roadmap Unit & Progression Tests', () {
    test('1. All eight ranks are exposed with canonical titles and thresholds in order', () {
      final tiers = gamification.allTiers;
      expect(tiers.length, 8);

      expect(tiers[0].level, 1);
      expect(tiers[0].title, 'Campus Rookie');
      expect(tiers[0].minXp, 0);
      expect(tiers[0].maxXp, 499);
      expect(tiers[0].xpRangeLabel, '0 – 499 XP');

      expect(tiers[1].level, 2);
      expect(tiers[1].title, 'Hostel Hustler');
      expect(tiers[1].minXp, 500);
      expect(tiers[1].maxXp, 1199);
      expect(tiers[1].xpRangeLabel, '500 – 1199 XP');

      expect(tiers[2].level, 3);
      expect(tiers[2].title, 'Fitness Seeker');
      expect(tiers[2].minXp, 1200);
      expect(tiers[2].maxXp, 2199);
      expect(tiers[2].xpRangeLabel, '1200 – 2199 XP');

      expect(tiers[3].level, 4);
      expect(tiers[3].title, 'Campus Warrior');
      expect(tiers[3].minXp, 2200);
      expect(tiers[3].maxXp, 3499);
      expect(tiers[3].xpRangeLabel, '2200 – 3499 XP');

      expect(tiers[4].level, 5);
      expect(tiers[4].title, 'Desi Beast');
      expect(tiers[4].minXp, 3500);
      expect(tiers[4].maxXp, 4999);
      expect(tiers[4].xpRangeLabel, '3500 – 4999 XP');

      expect(tiers[5].level, 6);
      expect(tiers[5].title, 'Odisha Titan');
      expect(tiers[5].minXp, 5000);
      expect(tiers[5].maxXp, 6999);
      expect(tiers[5].xpRangeLabel, '5000 – 6999 XP');

      expect(tiers[6].level, 7);
      expect(tiers[6].title, 'Campus Legend');
      expect(tiers[6].minXp, 7000);
      expect(tiers[6].maxXp, 9999);
      expect(tiers[6].xpRangeLabel, '7000 – 9999 XP');

      expect(tiers[7].level, 8);
      expect(tiers[7].title, 'Grandmaster');
      expect(tiers[7].minXp, 10000);
      expect(tiers[7].maxXp, 999999);
      expect(tiers[7].xpRangeLabel, '10000+ XP');
    });

    test('2. Progress and remaining XP are exact at level boundary (Level 4 threshold)', () async {
      await gamification.addXp(2200);

      expect(gamification.currentLevel, 4);
      expect(gamification.levelTitle, 'Campus Warrior');
      expect(gamification.currentLevelBaseXp, 2200);
      expect(gamification.nextLevelXp, 3500);
      expect(gamification.xpRequiredForNextLevel, 1300);
      expect(gamification.levelProgress, 0.0);
      expect(gamification.isMaxRank, isFalse);
    });

    test('3. Grandmaster is handled without a next-rank calculation', () async {
      await gamification.addXp(12000);

      expect(gamification.currentLevel, 8);
      expect(gamification.levelTitle, 'Grandmaster');
      expect(gamification.isMaxRank, isTrue);
      expect(gamification.xpRequiredForNextLevel, 0);
      expect(gamification.levelProgress, 1.0);
    });
  });

  group('CampusRankRoadmapSheet Widget Tests', () {
    testWidgets('4. Displays all eight ranks in order with titles, levels and XP ranges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: CampusRankRoadmapSheet()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CAMPUS RANK ROADMAP'), findsOneWidget);

      // Verify all 8 titles exist
      expect(find.textContaining('Campus Rookie'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Hostel Hustler'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Fitness Seeker'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Campus Warrior'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Desi Beast'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Odisha Titan'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Campus Legend'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Grandmaster'), findsAtLeastNWidgets(1));

      // Verify XP ranges exist
      expect(find.text('0 – 499 XP'), findsOneWidget);
      expect(find.text('500 – 1199 XP'), findsOneWidget);
      expect(find.text('1200 – 2199 XP'), findsOneWidget);
      expect(find.text('2200 – 3499 XP'), findsOneWidget);
      expect(find.text('3500 – 4999 XP'), findsOneWidget);
      expect(find.text('5000 – 6999 XP'), findsOneWidget);
      expect(find.text('7000 – 9999 XP'), findsOneWidget);
      expect(find.text('10000+ XP'), findsOneWidget);
    });

    testWidgets('5. Current rank is highlighted, previous are unlocked, later are locked', (tester) async {
      // Set to Level 4 (2500 XP)
      await gamification.addXp(2500);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: CampusRankRoadmapSheet()),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 1 Current Rank badge
      expect(find.text('CURRENT RANK'), findsOneWidget);

      // Levels 1, 2, 3 are UNLOCKED (3 count)
      expect(find.text('UNLOCKED'), findsNWidgets(3));

      // Levels 5, 6, 7, 8 are LOCKED (4 count)
      expect(find.text('LOCKED'), findsNWidgets(4));

      // Shows progress toward Level 5
      expect(find.textContaining('1000 XP needed for Level 5'), findsAtLeastNWidgets(1));
    });

    testWidgets('6. Grandmaster displays maximum-rank state without next-rank calculation', (tester) async {
      await gamification.addXp(10500);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: CampusRankRoadmapSheet()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RANK'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsNWidgets(7));
      expect(find.text('LOCKED'), findsNothing);

      // Verify max rank label
      expect(find.textContaining('Maximum Campus Rank Achieved'), findsOneWidget);
      expect(find.textContaining('No higher rank exists'), findsOneWidget);
      expect(find.textContaining('Level 9'), findsNothing);
    });

    testWidgets('7. Opening and dismissing the sheet leaves XP and rewards completely unchanged', (tester) async {
      await gamification.addXp(1500);
      final initialXp = gamification.xp;
      final initialUnlockedBadges = gamification.badges.where((b) => b.isUnlocked).length;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CampusRankRoadmapSheet.show(ctx),
                child: const Text('Open Roadmap'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Roadmap'));
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.text('CAMPUS RANK ROADMAP'), findsOneWidget);

      // Dismiss sheet
      final closeButton = find.byTooltip('Close');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify sheet is dismissed
      expect(find.text('CAMPUS RANK ROADMAP'), findsNothing);

      // Verify no XP or reward side-effects
      expect(gamification.xp, equals(initialXp));
      expect(
        gamification.badges.where((b) => b.isUnlocked).length,
        equals(initialUnlockedBadges),
      );
    });

    testWidgets('8. ProfileScreen progression card opens CampusRankRoadmapSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on "Campus Ranks" in the athlete level card
      final ranksButton = find.text('Campus Ranks');
      expect(ranksButton, findsOneWidget);
      await tester.tap(ranksButton);
      await tester.pumpAndSettle();

      // Verify CampusRankRoadmapSheet opened
      expect(find.text('CAMPUS RANK ROADMAP'), findsOneWidget);
    });

    testWidgets('9. StreakXpBanner Level & XP tap opens CampusRankRoadmapSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StreakXpBanner(
              user: const UserProfile(
                xp: 1200,
                level: 3,
                levelTitle: 'Fitness Seeker',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on XP / Level area
      final xpFinder = find.text('1200 XP');
      expect(xpFinder, findsOneWidget);
      await tester.tap(xpFinder);
      await tester.pumpAndSettle();

      // Verify sheet opened
      expect(find.text('CAMPUS RANK ROADMAP'), findsOneWidget);
    });
  });
}
