import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/screens/home/home_screen.dart';
import 'package:genfit/screens/profile/profile_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('user_profile_ui_test_');
    UserService.instance.setCustomStoragePath(tempDir.path);
    GamificationService.instance.setCustomStoragePath(tempDir.path);
    await UserService.instance.resetToDefaults();
    await GamificationService.instance.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('HomeScreen UserProfile Consumption', () {
    testWidgets('Home displays default UserProfile name and fallback values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Home displays fallback name and college
      expect(find.textContaining('Ayush'), findsOneWidget);
      expect(find.textContaining('ITER • Bhubaneswar Campus'), findsOneWidget);
    });

    testWidgets('Home reactively updates when UserProfile changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ayush'), findsOneWidget);

      await UserService.instance.updateFields(
        name: 'Soumya',
        college: 'OUTR Bhubaneswar',
        campus: 'Ghatikia Campus',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Soumya'), findsOneWidget);
      expect(
        find.textContaining('OUTR Bhubaneswar • Ghatikia Campus'),
        findsOneWidget,
      );
    });
  });

  group('ProfileScreen UserProfile Consumption', () {
    testWidgets(
      'Profile screen displays all 10 centralized UserProfile fields',
      (WidgetTester tester) async {
        await UserService.instance.updateFields(
          name: 'Karan Sharma',
          college: 'GCEK Kalahandi',
          campus: 'Bhawanipatna Campus',
          age: 22,
          heightCm: 175.0,
          weightKg: 68.0,
          fitnessGoal: 'Build Muscle',
          fitnessLevel: 'Intermediate',
          dietPreference: 'Eggetarian',
          budgetPreference: 'Moderate',
        );

        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen()),
        );
        await tester.pumpAndSettle();

        // 1. Name
        expect(find.text('Karan Sharma'), findsOneWidget);

        // 2. College & 3. Campus
        expect(
          find.textContaining('GCEK Kalahandi • Bhawanipatna Campus'),
          findsOneWidget,
        );
        expect(find.text('Bhawanipatna Campus'), findsOneWidget);

        // 4. Age
        expect(find.text('22 yrs'), findsOneWidget);

        // 5. Height
        expect(find.text('175 cm'), findsOneWidget);

        // 6. Weight
        expect(find.text('68 kg'), findsOneWidget);

        // 7. Fitness Goal
        expect(find.text('Build Muscle'), findsOneWidget);

        // 8. Fitness Level
        expect(find.text('Intermediate'), findsOneWidget);

        // 9. Diet Preference
        expect(find.text('Eggetarian'), findsOneWidget);

        // 10. Budget Preference
        expect(find.text('Moderate'), findsOneWidget);
      },
    );

    testWidgets(
      'Profile screen shows safe fallback values when not customized',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ayush'), findsOneWidget);
        expect(find.text('20 yrs'), findsOneWidget);
        expect(find.text('172 cm'), findsOneWidget);
        expect(find.text('65 kg'), findsOneWidget);
        expect(find.text('Stay Fit'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);
        expect(find.text('Vegetarian'), findsOneWidget);
        expect(find.text('Budget Friendly'), findsOneWidget);
      },
    );

    testWidgets('Profile screen reactively updates when UserProfile changes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ayush'), findsOneWidget);

      await UserService.instance.updateFields(
        name: 'Debashish',
        fitnessGoal: 'Lose Fat',
      );
      await tester.pumpAndSettle();

      expect(find.text('Debashish'), findsOneWidget);
      expect(find.text('Lose Fat'), findsOneWidget);
    });
  });
}
