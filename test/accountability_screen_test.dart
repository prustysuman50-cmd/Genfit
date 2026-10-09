import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/accountability_service.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/daily_stats_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/screens/community/accountability_partner_screen.dart';
import 'package:genfit/screens/community/community_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('accountability_ui_test_');
    AccountabilityService.instance.setCustomStoragePath(tempDir.path);
    CommunityService.instance.setCustomStoragePath(tempDir.path);
    UserService.instance.setCustomStoragePath(tempDir.path);
    GamificationService.instance.setCustomStoragePath(tempDir.path);
    DailyStatsService.instance.setCustomStoragePath(tempDir.path);

    await AccountabilityService.instance.resetToDefaults();
    await CommunityService.instance.resetToDefaults();
    await UserService.instance.resetToDefaults();
    await GamificationService.instance.resetToDefaults();
    await DailyStatsService.instance.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildAccountabilityApp() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const AccountabilityPartnerScreen(),
    );
  }

  Widget buildCommunityApp() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const CommunityScreen(),
    );
  }

  testWidgets(
    'AccountabilityPartnerScreen renders duo hero, motivation, check-in card, and comparison',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAccountabilityApp());
      await tester.pumpAndSettle();

      // 1. Header & Subtitle
      expect(find.text('Accountability Partner'), findsOneWidget);
      expect(
        find.text('Train with a classmate. Never miss a day.'),
        findsOneWidget,
      );

      // 2. Duo Hero Card (You + Partner)
      expect(find.text(UserService.instance.currentUser.name), findsOneWidget);
      expect(find.text('Rahul Patel'), findsWidgets);
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('PARTNER'), findsOneWidget);

      // 3. Motivational Message
      expect(
        find.textContaining("Rahul Patel is already active today. Don't miss your check-in!"),
        findsOneWidget,
      );

      // 4. Daily Check-In Action
      expect(find.text("Today's Mutual Check-in"), findsOneWidget);
      expect(find.text('Check In Today'), findsOneWidget);
      expect(find.text('+20 XP'), findsOneWidget);

      // 5. Comparison Section
      expect(find.text('Partner Comparison'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text("Today's Steps"), findsOneWidget);
      expect(find.text("Today's Workout"), findsOneWidget);
      expect(find.text('Total XP'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);

      // 6. Partner Profile & Nudge
      expect(find.text('Nudge'), findsOneWidget);
      expect(find.text('Brahmaputra Hall'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Check In Today completes check-in, shows SnackBar, and changes button state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAccountabilityApp());
      await tester.pumpAndSettle();

      final checkInButton = find.widgetWithText(FilledButton, 'Check In Today');
      expect(checkInButton, findsOneWidget);

      // Tap Check In
      await tester.tap(checkInButton);
      await tester.pumpAndSettle();

      // Verify SnackBar
      expect(
        find.text('Checked in! +20 XP awarded. Streak protected!'),
        findsOneWidget,
      );

      // Verify service state
      expect(AccountabilityService.instance.isUserCheckedInToday(), isTrue);

      // Button updates to completed state
      expect(find.text('Checked In for Today'), findsOneWidget);
      expect(find.text("Today's Check-in Complete!"), findsOneWidget);

      // Tap again -> shows feedback that user is already checked in
      await tester.tap(find.text('Checked In for Today'));
      await tester.pumpAndSettle();

      expect(find.text('Already checked in for today!'), findsOneWidget);
    },
  );

  testWidgets('Tapping Nudge button displays feedback SnackBar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildAccountabilityApp());
    await tester.pumpAndSettle();

    final nudgeButton = find.widgetWithText(OutlinedButton, 'Nudge');
    expect(nudgeButton, findsOneWidget);

    await tester.tap(nudgeButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Nudge sent to Rahul Patel! Keep each other consistent.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'CommunityScreen Accountability Partner card navigates to AccountabilityPartnerScreen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCommunityApp());
      await tester.pumpAndSettle();

      // Verify Accountability Partner card is rendered on CommunityScreen
      final partnerCard = find.text('Accountability Partner');
      expect(partnerCard, findsWidgets);

      // Tap Accountability Partner card
      await tester.tap(partnerCard.first);
      await tester.pumpAndSettle();

      // Verify navigation to AccountabilityPartnerScreen
      expect(find.text('Train with a classmate. Never miss a day.'), findsOneWidget);
      expect(find.text('Partner Comparison'), findsOneWidget);
    },
  );

  testWidgets(
    'CommunityScreen AppBar icon navigates to AccountabilityPartnerScreen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCommunityApp());
      await tester.pumpAndSettle();

      final partnerIconBtn = find.byTooltip('Accountability Partner');
      expect(partnerIconBtn, findsOneWidget);

      await tester.tap(partnerIconBtn);
      await tester.pumpAndSettle();

      expect(find.text('Train with a classmate. Never miss a day.'), findsOneWidget);
    },
  );
}
