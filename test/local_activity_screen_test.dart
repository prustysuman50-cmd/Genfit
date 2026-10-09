import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/accountability_service.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/heritage_service.dart';
import 'package:genfit/core/services/local_activity_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/models/user_profile.dart';
import 'package:genfit/screens/community/community_screen.dart';
import 'package:genfit/screens/community/local_activity_spots_screen.dart';

Widget buildLocalSpotsApp() {
  return const MaterialApp(
    home: LocalActivitySpotsScreen(),
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
    tempDir = Directory.systemTemp.createTempSync('local_spots_ui_test_');

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

    LocalActivityService.instance.setCustomStoragePath(tempDir.path);
    await LocalActivityService.instance.resetToDefaults();

    CommunityService.instance.setCustomStoragePath(tempDir.path);
    await CommunityService.instance.init();
  });

  tearDown(() {
    DailyStatsService.instance.setCustomStoragePath(null);
    GamificationService.instance.setCustomStoragePath(null);
    UserService.instance.setCustomStoragePath(null);
    AccountabilityService.instance.setCustomStoragePath(null);
    HeritageService.instance.setCustomStoragePath(null);
    LocalActivityService.instance.setCustomStoragePath(null);
    CommunityService.instance.setCustomStoragePath(null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('LocalActivitySpotsScreen renders hero, chips, and curated spots cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLocalSpotsApp());
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Local Activity Spots'), findsOneWidget);

    // Verify Hero Banner
    expect(find.text('CAMPUS & LOCAL SPOTS'), findsOneWidget);
    expect(find.text('Outdoor Training & Tracks'), findsOneWidget);
    expect(find.text('Offline Directory'), findsOneWidget);

    // Verify Category Filter Chips
    expect(find.widgetWithText(FilterChip, 'All Spots (6)'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Open Gyms (2)'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Tracks (1)'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Parks (1)'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Campus (2)'), findsOneWidget);

    // Verify Spots Cards
    expect(find.text('GCEK Campus Sports Complex & Oval'), findsOneWidget);
    expect(find.text('Brahmaputra Hostel Calisthenics Zone'), findsOneWidget);
    expect(find.text('Kalahandi Eco Park & Fitness Trail'), findsOneWidget);
    expect(find.text('Collectorate Green Park Open Gym'), findsOneWidget);
    expect(find.text('Manikeswari Temple Lake Loop'), findsOneWidget);
    expect(find.text('College West Lawn & Agility Area'), findsOneWidget);
  });

  testWidgets('Category chips filter the spot list correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLocalSpotsApp());
    await tester.pumpAndSettle();

    // Tap 'Open Gyms' filter chip
    final openGymChip = find.textContaining('Open Gyms (2)');
    expect(openGymChip, findsOneWidget);
    await tester.tap(openGymChip);
    await tester.pumpAndSettle();

    // Only Open Gyms should be shown
    expect(find.text('Brahmaputra Hostel Calisthenics Zone'), findsOneWidget);
    expect(find.text('Collectorate Green Park Open Gym'), findsOneWidget);
    expect(find.text('Manikeswari Temple Lake Loop'), findsNothing);
    expect(find.text('GCEK Campus Sports Complex & Oval'), findsNothing);
  });

  testWidgets('Search input filters spots and displays empty state with reset button', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLocalSpotsApp());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Enter search query
    await tester.enterText(searchField, 'Lake');
    await tester.pumpAndSettle();

    expect(find.text('Manikeswari Temple Lake Loop'), findsOneWidget);
    expect(find.text('Brahmaputra Hostel Calisthenics Zone'), findsNothing);

    // Enter query with zero matches
    await tester.enterText(searchField, 'UnknownNonExistentPlace');
    await tester.pumpAndSettle();

    expect(find.text('No matching activity spots found'), findsOneWidget);
    expect(find.text('Reset Filters'), findsOneWidget);

    // Tap reset filters
    await tester.tap(find.text('Reset Filters'));
    await tester.pumpAndSettle();

    expect(find.text('GCEK Campus Sports Complex & Oval'), findsOneWidget);
    expect(find.text('Brahmaputra Hostel Calisthenics Zone'), findsOneWidget);
  });

  testWidgets('Tapping View Details opens modal sheet with equipment & tips', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLocalSpotsApp());
    await tester.pumpAndSettle();

    final viewDetailsButtons = find.text('View Details');
    expect(viewDetailsButtons, findsWidgets);

    // Tap first "View Details"
    await tester.tap(viewDetailsButtons.first);
    await tester.pumpAndSettle();

    // Modal sheet contents
    expect(find.text('About Spot'), findsOneWidget);
    expect(find.text('Facilities & Amenities'), findsOneWidget);
    expect(find.text('Surface Type'), findsOneWidget);
    expect(find.text('Student Tip & Advice'), findsOneWidget);
  });

  testWidgets('Tapping favorite bookmark toggles state and updates saved counter', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLocalSpotsApp());
    await tester.pumpAndSettle();

    expect(find.text('★ 1 Saved'), findsNothing);

    final bookmarkButtons = find.byTooltip('Save Spot');
    expect(bookmarkButtons, findsWidgets);

    // Tap first bookmark button
    await tester.tap(bookmarkButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('★ 1 Saved'), findsOneWidget);
  });

  testWidgets('CommunityScreen renders Local Activity Spots card and navigates on tap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildCommunityApp());
    await tester.pumpAndSettle();

    // Banner card exists
    final bannerCard = find.text('Local Activity Spots');
    expect(bannerCard, findsOneWidget);
    expect(find.text('6 spots'), findsOneWidget);

    // Tap banner card
    await tester.tap(bannerCard);
    await tester.pumpAndSettle();

    // Now on LocalActivitySpotsScreen
    expect(find.text('Outdoor Training & Tracks'), findsOneWidget);
  });

  testWidgets('CommunityScreen AppBar icon navigates to LocalActivitySpotsScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildCommunityApp());
    await tester.pumpAndSettle();

    final spotsAction = find.byTooltip('Local Activity Spots');
    expect(spotsAction, findsOneWidget);

    await tester.tap(spotsAction);
    await tester.pumpAndSettle();

    expect(find.text('Outdoor Training & Tracks'), findsOneWidget);
  });
}
