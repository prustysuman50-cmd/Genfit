import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/core/services/gamification_service.dart';
import 'package:genfit/core/services/storage_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/models/onboarding_profile.dart';
import 'package:genfit/screens/community/community_screen.dart';
import 'package:genfit/screens/home/home_screen.dart';
import 'package:genfit/screens/onboarding/onboarding_flow_screen.dart';
import 'package:genfit/screens/onboarding/steps/personal_info_step.dart';
import 'package:genfit/screens/profile/profile_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('personal_info_test_');
    UserService.instance.setCustomStoragePath(tempDir.path);
    StorageService.instance.resetOnboarding();
    CommunityService.instance.setCustomStoragePath(tempDir.path);
    GamificationService.instance.setCustomStoragePath(tempDir.path);
    await UserService.instance.resetToDefaults();
    await CommunityService.instance.resetToDefaults();
    await GamificationService.instance.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('PersonalInfoStep Unit & Widget Tests', () {
    testWidgets('renders name, college, and campus input fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PersonalInfoStep(
              initialName: '',
              initialCollege: '',
              initialCampus: '',
              onChanged: (_, _, _, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Identity'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('College / University *'), findsOneWidget);
      expect(find.text('Enter your college'), findsOneWidget);
      expect(find.text('Campus / Location (Optional)'), findsOneWidget);
      expect(find.text('Enter your campus'), findsOneWidget);
    });

    testWidgets(
      'validation fails when required fields are empty and shows inline errors',
      (WidgetTester tester) async {
        bool isValid = true;
        String capturedName = '';
        String capturedCollege = '';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: PersonalInfoStep(
                initialName: '',
                initialCollege: '',
                initialCampus: '',
                onChanged: (name, college, campus, valid) {
                  capturedName = name;
                  capturedCollege = college;
                  isValid = valid;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially invalid when empty
        expect(isValid, isFalse);

        // Enter name only
        final nameField = find.widgetWithText(TextField, 'Enter your name');
        await tester.enterText(nameField, 'Swadhin');
        await tester.pumpAndSettle();

        expect(capturedName, 'Swadhin');
        expect(isValid, isFalse); // College still empty

        // Enter college
        final collegeField = find.widgetWithText(
          TextField,
          'Enter your college',
        );
        await tester.enterText(collegeField, 'GCEK');
        await tester.pumpAndSettle();

        expect(capturedCollege, 'GCEK');
        expect(isValid, isTrue); // Both name and college filled

        // Clear name to trigger validation error
        await tester.enterText(nameField, '');
        await tester.pumpAndSettle();

        expect(isValid, isFalse);
        expect(find.text('Please enter your name'), findsOneWidget);
      },
    );

    testWidgets('campus is optional and updates live preview card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PersonalInfoStep(
              initialName: '',
              initialCollege: '',
              initialCampus: '',
              onChanged: (_, _, _, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Enter your name');
      final collegeField = find.widgetWithText(TextField, 'Enter your college');
      final campusField = find.widgetWithText(TextField, 'Enter your campus');

      await tester.enterText(nameField, 'Aakash Jena');
      await tester.enterText(collegeField, 'OUTR');
      await tester.enterText(campusField, 'Bhubaneswar Campus');
      await tester.pumpAndSettle();

      // Avatar initials derived from name
      expect(find.text('AJ'), findsOneWidget);
      expect(find.text('Aakash Jena'), findsWidgets);
      expect(find.text('OUTR • Bhubaneswar Campus'), findsOneWidget);
    });
  });

  group('Onboarding Flow to UserService Integration', () {
    testWidgets(
      'completing onboarding with custom identity updates UserService, Home, Profile, and Community',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Start from Page 5 (PersonalInfoStep)
        await tester.pumpWidget(
          const MaterialApp(home: OnboardingFlowScreen(initialPage: 5)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Student Identity'), findsOneWidget);

        // 2. Fill personal info
        final nameField = find.widgetWithText(TextField, 'Enter your name');
        final collegeField = find.widgetWithText(
          TextField,
          'Enter your college',
        );
        final campusField = find.widgetWithText(TextField, 'Enter your campus');

        await tester.enterText(nameField, 'Manas Ranjan');
        await tester.enterText(collegeField, 'VSSUT');
        await tester.enterText(campusField, 'Burla Campus');
        await tester.pumpAndSettle();

        // Continue button should be enabled
        final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');
        expect(continueBtn, findsOneWidget);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // 3. Advances to Step 6: Fitness Level
        expect(find.text('What is your fitness level?'), findsOneWidget);
      },
    );

    test('OnboardingProfile serializes name, college, campus and syncs to UserService', () async {
      const profile = OnboardingProfile(
        name: 'Chinmayee',
        college: 'GCEK Kalahandi',
        campus: 'Bhawanipatna Campus',
        goal: 'Build Muscle',
        workoutLocation: 'College Gym',
        age: 21,
        heightCm: 168.0,
        weightKg: 58.0,
        isCompleted: true,
      );

      // Verify serialization roundtrip
      final json = profile.toJson();
      final restored = OnboardingProfile.fromJson(json);
      expect(restored.name, 'Chinmayee');
      expect(restored.college, 'GCEK Kalahandi');
      expect(restored.campus, 'Bhawanipatna Campus');

      // Sync to UserService
      await UserService.instance.syncFromOnboarding(profile);

      expect(UserService.instance.currentUser.name, 'Chinmayee');
      expect(UserService.instance.currentUser.college, 'GCEK Kalahandi');
      expect(UserService.instance.currentUser.campus, 'Bhawanipatna Campus');
      expect(UserService.instance.currentUser.avatarInitials, 'CH');

      // Verify persistence across reload
      await UserService.instance.init();
      expect(UserService.instance.currentUser.name, 'Chinmayee');
      expect(UserService.instance.currentUser.college, 'GCEK Kalahandi');
    });

    testWidgets(
      'Home, Profile, and Community immediately display newly onboarded user identity',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Simulate completing onboarding with new identity
        const completedOnboarding = OnboardingProfile(
          name: 'Tanmay Mohanty',
          college: 'Silicon Institute',
          campus: 'Bhubaneswar Campus',
          goal: 'Lose Fat',
          age: 22,
          heightCm: 178.0,
          weightKg: 74.0,
          fitnessLevel: 'Intermediate',
          dietaryPreference: 'Non-vegetarian',
          foodBudget: 'Moderate',
          isCompleted: true,
        );

        await UserService.instance.syncFromOnboarding(completedOnboarding);

        // 1. Verify Home Screen displays custom user
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Tanmay Mohanty'), findsOneWidget);
        expect(
          find.textContaining('Silicon Institute • Bhubaneswar Campus'),
          findsOneWidget,
        );

        // 2. Verify Profile Screen displays custom user
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tanmay Mohanty'), findsOneWidget);
        expect(
          find.textContaining('Silicon Institute • Bhubaneswar Campus'),
          findsOneWidget,
        );
        expect(find.text('Bhubaneswar Campus'), findsOneWidget);
        expect(find.text('TM'), findsOneWidget);

        // 3. Verify Community Screen current-user card displays custom user
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const CommunityScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tanmay Mohanty'), findsOneWidget);
        expect(
          find.textContaining('Silicon Institute • Bhubaneswar Campus'),
          findsOneWidget,
        );
      },
    );
  });
}
