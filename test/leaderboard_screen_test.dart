import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/journey_service.dart';
import 'package:genfit/core/services/leaderboard_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/screens/journey/journey_screen.dart';
import 'package:genfit/screens/leaderboard/leaderboard_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('leaderboard_screen_test_');
    UserService.instance.setCustomStoragePath(tempDir.path);
    GamificationService.instance.setCustomStoragePath(tempDir.path);
    CommunityService.instance.setCustomStoragePath(tempDir.path);
    JourneyService.instance.setCustomStoragePath(tempDir.path);

    await UserService.instance.resetToDefaults();
    await GamificationService.instance.resetToDefaults();
    await CommunityService.instance.resetToDefaults();
    await JourneyService.instance.resetToDefaults();

    LeaderboardService.instance.setFilter(LeaderboardFilter.campus);
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildLeaderboardApp() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const LeaderboardScreen(),
    );
  }

  Widget buildJourneyApp() {
    return MaterialApp(theme: AppTheme.darkTheme, home: const JourneyScreen());
  }

  testWidgets(
    'LeaderboardScreen renders header, subtitle, tabs, and current user card',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildLeaderboardApp());
      await tester.pumpAndSettle();

      // 1. Header & Subtitle
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Train together. Climb together.'), findsOneWidget);

      // 2. Filter Tabs
      expect(find.text('Campus'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);

      // 3. Current User Card
      expect(find.text('YOU'), findsWidgets);
      expect(find.text(UserService.instance.currentUser.name), findsWidgets);
      expect(
        find.textContaining('${GamificationService.instance.xp} XP'),
        findsWidgets,
      );

      // 4. Podium Section
      expect(find.text('Campus Champions'), findsOneWidget);
      expect(find.text('#1'), findsWidgets);
      expect(find.text('#2'), findsWidgets);
      expect(find.text('#3'), findsWidgets);

      // 5. Ranked List Header
      expect(find.text('Student Rankings'), findsOneWidget);
      expect(find.textContaining('Students'), findsOneWidget);
    },
  );

  testWidgets('Switching tabs to Friends updates leaderboard list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLeaderboardApp());
    await tester.pumpAndSettle();

    // Tap Friends tab
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(
      LeaderboardService.instance.currentFilter,
      equals(LeaderboardFilter.friends),
    );

    // Connected friends + current user = 4 students
    expect(find.text('4 Students'), findsOneWidget);
  });

  testWidgets('Switching tabs to Weekly displays weekly XP metrics', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLeaderboardApp());
    await tester.pumpAndSettle();

    // Tap Weekly tab
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(
      LeaderboardService.instance.currentFilter,
      equals(LeaderboardFilter.weekly),
    );

    expect(find.textContaining('Weekly XP'), findsWidgets);
  });

  testWidgets('JourneyScreen AppBar button navigates to LeaderboardScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildJourneyApp());
    await tester.pumpAndSettle();

    // Find and tap Leaderboard icon button in JourneyScreen
    final leaderboardButton = find.byTooltip('Campus Leaderboard');
    expect(leaderboardButton, findsOneWidget);

    await tester.tap(leaderboardButton);
    await tester.pumpAndSettle();

    // Verify LeaderboardScreen is pushed
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Train together. Climb together.'), findsOneWidget);
  });
}
