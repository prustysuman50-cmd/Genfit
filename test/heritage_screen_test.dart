import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/accountability_service.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/heritage_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/models/user_profile.dart';
import 'package:genfit/screens/community/community_screen.dart';
import 'package:genfit/screens/heritage/heritage_challenge_screen.dart';

Widget buildHeritageApp() {
  return const MaterialApp(
    home: HeritageChallengeScreen(),
  );
}

Widget buildCommunityApp() {
  return const MaterialApp(
    home: CommunityScreen(),
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('heritage_ui_test_');

    DailyStatsService.instance.setCustomStoragePath(tempDir.path);
    await DailyStatsService.instance.init();

    GamificationService.instance.setCustomStoragePath(tempDir.path);
    await GamificationService.instance.resetToDefaults();

    UserService.instance.setCustomStoragePath(tempDir.path);
    await UserService.instance.init();
    await UserService.instance.updateProfile(
      const UserProfile(
        name: 'Avishek Das',
        college: 'GCEK Kalahandi',
        hostel: 'Brahmaputra Hall',
      ),
    );

    AccountabilityService.instance.setCustomStoragePath(tempDir.path);
    await AccountabilityService.instance.resetToDefaults();

    HeritageService.instance.setCustomStoragePath(tempDir.path);
    await HeritageService.instance.resetToDefaults();
    HeritageService.instance.attachDailyStatsListener(DailyStatsService.instance);

    CommunityService.instance.setCustomStoragePath(tempDir.path);
    await CommunityService.instance.init();
  });

  tearDown(() {
    DailyStatsService.instance.setCustomStoragePath(null);
    GamificationService.instance.setCustomStoragePath(null);
    UserService.instance.setCustomStoragePath(null);
    AccountabilityService.instance.setCustomStoragePath(null);
    HeritageService.instance.setCustomStoragePath(null);
    HeritageService.instance.detachDailyStatsListener();
    CommunityService.instance.setCustomStoragePath(null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('HeritageChallengeScreen renders hero, progress, milestones, and badges', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHeritageApp());
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Odisha Heritage Challenges'), findsOneWidget);

    // Verify Route Header
    expect(find.text('ODISHA HERITAGE TRAIL'), findsOneWidget);
    expect(find.text('Lingaraj Temple → Konark Sun Temple'), findsWidgets);

    // Verify Milestone Timeline
    expect(find.text('Trail Expedition Milestones'), findsOneWidget);
    expect(find.text('Lingaraj Temple'), findsWidgets);
    expect(find.text('Dhauli Shanti Stupa'), findsOneWidget);
    expect(find.text('Pipili Applique Craft Village'), findsOneWidget);
    expect(find.text('Nimapada Heritage Stop'), findsOneWidget);
    expect(find.text('Konark Sun Temple'), findsWidgets);

    // Verify Cultural Badges Showcase
    expect(find.text('Cultural Heritage Badges'), findsOneWidget);
    expect(find.text('Peace of Dhauli'), findsWidgets);
    expect(find.text('Pipili Master Artisan'), findsWidgets);

    // Verify Route Switcher
    expect(find.text('Choose Heritage Route'), findsOneWidget);
    expect(find.text('Puri Jagannath → Chilika Lake'), findsOneWidget);
  });

  testWidgets('CommunityScreen displays Heritage Challenge banner and navigates to screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildCommunityApp());
    await tester.pumpAndSettle();

    // Banner card exists
    final bannerCard = find.text('Odisha Heritage Challenge');
    expect(bannerCard, findsOneWidget);

    // Tap banner card
    await tester.tap(bannerCard);
    await tester.pumpAndSettle();

    // Now on HeritageChallengeScreen
    expect(find.text('Odisha Heritage Challenges'), findsOneWidget);
    expect(find.text('Trail Expedition Milestones'), findsOneWidget);
  });

  testWidgets('CommunityScreen AppBar icon navigates to HeritageChallengeScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildCommunityApp());
    await tester.pumpAndSettle();

    final exploreButton = find.byTooltip('Heritage Challenges');
    expect(exploreButton, findsOneWidget);

    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    expect(find.text('Odisha Heritage Challenges'), findsOneWidget);
  });
}
