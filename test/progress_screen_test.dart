import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/journey_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/progress_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/screens/profile/profile_screen.dart';
import 'package:genfit/screens/progress/progress_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('progress_screen_test_');
    DailyStatsService.instance.setCustomStoragePath(tempDir.path);
    UserService.instance.setCustomStoragePath(tempDir.path);
    GamificationService.instance.setCustomStoragePath(tempDir.path);
    NutritionService.instance.setCustomStoragePath(tempDir.path);
    JourneyService.instance.setCustomStoragePath(tempDir.path);
    ProgressService.instance.setCustomStoragePath(tempDir.path);

    await DailyStatsService.instance.resetToDefaults();
    await UserService.instance.resetToDefaults();
    await GamificationService.instance.resetToDefaults();
    await NutritionService.instance.resetToDefaults();
    await JourneyService.instance.resetToDefaults();
    await ProgressService.instance.resetToDefaults();
  });

  tearDown(() {
    try {
      DailyStatsService.instance.detachNutritionListener();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildProgressApp() {
    return MaterialApp(theme: AppTheme.darkTheme, home: const ProgressScreen());
  }

  Widget buildProfileApp() {
    return MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen());
  }

  testWidgets(
    'ProgressScreen renders header, weekly overview, 7-day chart, and recommendation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();

      // 1. Header & Subtitle
      expect(find.text('Your Progress'), findsOneWidget);
      expect(find.text('Small steps. Consistent progress.'), findsOneWidget);

      // 2. Personalized Recommendation Card
      expect(find.text('Adaptive Tip'), findsOneWidget);

      // 3. Weekly Overview Grid
      expect(find.text('Weekly Overview'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('Active Calories'), findsOneWidget);
      expect(find.text('Active Minutes'), findsOneWidget);

      // 4. 7-Day Activity Chart
      expect(find.text('7-Day Activity Chart'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // 5. Fitness Milestones
      expect(find.text('Fitness Milestones & Consistency'), findsOneWidget);
      expect(find.text('Fitness Streak'), findsOneWidget);
      expect(find.text('Odisha Trail Progress'), findsOneWidget);
      expect(find.text('Mess Nutrition Meals'), findsOneWidget);

      // 6. Achievements & Badges
      expect(find.text('Achievements & Badges'), findsOneWidget);
    },
  );

  testWidgets('ProfileScreen navigation navigates to ProgressScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildProfileApp());
    await tester.pumpAndSettle();

    // Verify Progress tile is present in ProfileScreen
    final progressTile = find.text('Your Progress & Recommendations');
    expect(progressTile, findsOneWidget);

    await tester.tap(progressTile);
    await tester.pumpAndSettle();

    // Verify ProgressScreen was pushed
    expect(find.text('Your Progress'), findsOneWidget);
    expect(find.text('Weekly Overview'), findsOneWidget);
  });

  testWidgets('ProfileScreen AppBar icon navigates to ProgressScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildProfileApp());
    await tester.pumpAndSettle();

    final insightsButton = find.byTooltip('Your Progress');
    expect(insightsButton, findsOneWidget);

    await tester.tap(insightsButton);
    await tester.pumpAndSettle();

    expect(find.text('Your Progress'), findsOneWidget);
  });
}
