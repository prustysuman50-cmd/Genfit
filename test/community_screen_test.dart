import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/screens/community/community_screen.dart';

void main() {
  late Directory tempDir;
  final service = CommunityService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('community_ui_test_');
    service.setCustomStoragePath(tempDir.path);
    UserService.instance.setCustomStoragePath(tempDir.path);
    await service.resetToDefaults();
    await UserService.instance.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildCommunityApp() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const CommunityScreen(),
    );
  }

  testWidgets(
    'CommunityScreen renders header, current user summary, and 3 tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCommunityApp());
      await tester.pumpAndSettle();

      // Verify Header & Subtitle
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('GCEK'), findsOneWidget);
      expect(find.text('Train together. Stay accountable.'), findsOneWidget);

      // Verify Current User Summary Card uses dynamic UserProfile
      expect(find.text('YOU'), findsOneWidget);
      expect(
        find.textContaining(UserService.instance.currentUser.name),
        findsOneWidget,
      );
      expect(
        find.textContaining(UserService.instance.currentUser.campus),
        findsOneWidget,
      );

      // Verify 3 Filter Tabs
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Campus'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);

      // Verify Campus Section Heading (default selected tab is Campus)
      expect(find.text('GCEK Fitness Community'), findsOneWidget);
      expect(find.textContaining('Rahul Patel'), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsOneWidget);
      expect(find.textContaining('Aman Mohapatra'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Connect toggles connection state and updates Friends tab',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCommunityApp());
      await tester.pumpAndSettle();

      // Initially Aman is not connected
      expect(service.getStudentById('student_aman')?.isConnected, isFalse);

      // Scroll to Aman if needed and tap Connect button
      final connectBtn = find.widgetWithText(FilledButton, 'Connect').first;
      expect(connectBtn, findsWidgets);

      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Switch to Friends tab
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();

      expect(find.text('Your Fitness Circle'), findsOneWidget);
      expect(find.textContaining('active'), findsOneWidget);
    },
  );

  testWidgets('Switching to Activity tab renders live campus feed', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildCommunityApp());
    await tester.pumpAndSettle();

    // Switch to Activity tab
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    // Verify Activity Feed section
    expect(find.text('Live Campus Activity'), findsOneWidget);
    expect(find.text('Real-time'), findsOneWidget);
    expect(
      find.textContaining('completed a workout', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('reached a 7 day streak', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets(
    'Community current-user summary card reactively updates when UserProfile changes',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCommunityApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Ayush'), findsOneWidget);

      await UserService.instance.updateFields(
        name: 'Bikash Mohanty',
        college: 'GCEK Kalahandi',
        campus: 'Bhawanipatna Campus',
        avatarInitials: 'BM',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bikash Mohanty'), findsOneWidget);
      expect(find.text('BM'), findsOneWidget);
      expect(find.textContaining('GCEK Kalahandi'), findsWidgets);
    },
  );
}
