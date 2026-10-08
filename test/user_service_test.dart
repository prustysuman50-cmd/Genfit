import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/models/onboarding_profile.dart';
import 'package:genfit/models/user_profile.dart';

void main() {
  late Directory tempDir;
  final service = UserService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('user_service_test_');
    service.setCustomStoragePath(tempDir.path);
    await service.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('UserProfile Model Tests', () {
    test('default UserProfile has expected demo values and fallbacks', () {
      const user = UserProfile.defaultUser;
      expect(user.id, 'user_01');
      expect(user.name, 'Ayush');
      expect(user.college, 'ITER • Bhubaneswar Campus');
      expect(user.campus, 'Bhubaneswar Campus');
      expect(user.avatarInitials, 'AK');
      expect(user.streakDays, 7);
      expect(user.xp, 3850);
      expect(user.level, 4);
      expect(user.age, 20);
      expect(user.heightCm, 172.0);
      expect(user.weightKg, 65.0);
      expect(user.fitnessGoal, 'Stay Fit');
      expect(user.fitnessLevel, 'Beginner');
      expect(user.dietPreference, 'Vegetarian');
      expect(user.budgetPreference, 'Budget Friendly');
    });

    test('calculates BMI and BMI category accurately', () {
      const user = UserProfile(heightCm: 175.0, weightKg: 70.0);
      // BMI = 70 / (1.75 * 1.75) = 22.86
      expect(user.bmi, closeTo(22.86, 0.05));
      expect(user.bmiCategory, 'Normal weight');

      const underweightUser = UserProfile(heightCm: 180.0, weightKg: 50.0);
      expect(underweightUser.bmiCategory, 'Underweight');

      const overweightUser = UserProfile(heightCm: 170.0, weightKg: 80.0);
      expect(overweightUser.bmiCategory, 'Overweight');
    });

    test('serializes and deserializes UserProfile to and from JSON', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'usr_custom_99',
        name: 'Priya Sharma',
        college: 'GCEK Kalahandi',
        campus: 'Bhawanipatna Campus',
        avatarInitials: 'PS',
        streakDays: 12,
        xp: 4500,
        level: 5,
        levelTitle: 'Campus Master',
        nextLevelXp: 6000,
        age: 21,
        heightCm: 165.0,
        weightKg: 58.0,
        fitnessGoal: 'Build Muscle',
        fitnessLevel: 'Intermediate',
        dietPreference: 'Eggetarian',
        budgetPreference: 'Moderate',
        workoutLocation: 'College Gym',
        equipment: const ['Dumbbells', 'Pull-up Bar'],
        motivations: const ['Streaks', 'Competition'],
        journeyPreference: 'Campus Champion',
        isCompleted: true,
        completedAt: now,
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, 'usr_custom_99');
      expect(restored.name, 'Priya Sharma');
      expect(restored.college, 'GCEK Kalahandi');
      expect(restored.campus, 'Bhawanipatna Campus');
      expect(restored.avatarInitials, 'PS');
      expect(restored.streakDays, 12);
      expect(restored.xp, 4500);
      expect(restored.level, 5);
      expect(restored.age, 21);
      expect(restored.heightCm, 165.0);
      expect(restored.weightKg, 58.0);
      expect(restored.fitnessGoal, 'Build Muscle');
      expect(restored.fitnessLevel, 'Intermediate');
      expect(restored.dietPreference, 'Eggetarian');
      expect(restored.budgetPreference, 'Moderate');
      expect(restored.workoutLocation, 'College Gym');
      expect(restored.equipment, ['Dumbbells', 'Pull-up Bar']);
      expect(restored.motivations, ['Streaks', 'Competition']);
      expect(restored.isCompleted, isTrue);
    });

    test('computes initials correctly when not provided', () {
      expect(UserProfile.computeInitials('Rahul Verma'), 'RV');
      expect(UserProfile.computeInitials('Sneha'), 'SN');
      expect(UserProfile.computeInitials('A'), 'A');
      expect(UserProfile.computeInitials(''), 'GF');
    });

    test('converts from OnboardingProfile', () {
      const onboarding = OnboardingProfile(
        goal: 'Lose Fat',
        workoutLocation: 'Home',
        equipment: ['Resistance Bands'],
        age: 23,
        heightCm: 180.0,
        weightKg: 78.0,
        fitnessLevel: 'Advanced',
        dietaryPreference: 'Non-vegetarian',
        foodBudget: 'Flexible',
        motivations: ['Transformation', 'Progress'],
        journeyPreference: 'Explore Odisha',
        isCompleted: true,
      );

      final user = UserProfile.fromOnboarding(onboarding);

      expect(user.fitnessGoal, 'Lose Fat');
      expect(user.workoutLocation, 'Home');
      expect(user.equipment, ['Resistance Bands']);
      expect(user.age, 23);
      expect(user.heightCm, 180.0);
      expect(user.weightKg, 78.0);
      expect(user.fitnessLevel, 'Advanced');
      expect(user.dietPreference, 'Non-vegetarian');
      expect(user.budgetPreference, 'Flexible');
      expect(user.motivations, ['Transformation', 'Progress']);
      expect(user.journeyPreference, 'Explore Odisha');
      expect(user.isCompleted, isTrue);
      // Preserved default identity fields
      expect(user.name, 'Ayush');
      expect(user.college, 'ITER • Bhubaneswar Campus');
    });
  });

  group('UserService Integration and Persistence Tests', () {
    test(
      'initializes with default UserProfile when no saved file exists',
      () async {
        await service.init();
        expect(service.currentUser.name, 'Ayush');
        expect(service.currentUser.college, 'ITER • Bhubaneswar Campus');
        expect(service.currentUser.campus, 'Bhubaneswar Campus');
        expect(service.currentUser.fitnessGoal, 'Stay Fit');
      },
    );

    test(
      'updateFields updates in-memory profile and notifies listeners',
      () async {
        bool notified = false;
        service.addListener(() {
          notified = true;
        });

        await service.updateFields(
          name: 'Rohan Jena',
          college: 'GCEK Kalahandi',
          campus: 'Kalahandi Campus',
          age: 22,
          heightCm: 176.0,
          weightKg: 70.0,
          fitnessGoal: 'Build Muscle',
        );

        expect(notified, isTrue);
        expect(service.currentUser.name, 'Rohan Jena');
        expect(service.currentUser.college, 'GCEK Kalahandi');
        expect(service.currentUser.campus, 'Kalahandi Campus');
        expect(service.currentUser.age, 22);
        expect(service.currentUser.heightCm, 176.0);
        expect(service.currentUser.weightKg, 70.0);
        expect(service.currentUser.fitnessGoal, 'Build Muscle');
      },
    );

    test(
      'persists user profile to disk and restores across service re-init',
      () async {
        await service.updateFields(
          name: 'Ananya Pattnaik',
          college: 'OUTR Bhubaneswar',
          campus: 'Ghatikia Campus',
          age: 19,
          heightCm: 162.0,
          weightKg: 52.0,
          fitnessGoal: 'Improve Stamina',
          dietPreference: 'Eggetarian',
          budgetPreference: 'Budget Friendly',
        );

        // Verify file was written to custom storage path
        final savedFile = File('${tempDir.path}/genfit_user_profile.json');
        expect(savedFile.existsSync(), isTrue);

        // Simulate app restart by re-initializing service
        await service.init();

        expect(service.currentUser.name, 'Ananya Pattnaik');
        expect(service.currentUser.college, 'OUTR Bhubaneswar');
        expect(service.currentUser.campus, 'Ghatikia Campus');
        expect(service.currentUser.age, 19);
        expect(service.currentUser.heightCm, 162.0);
        expect(service.currentUser.weightKg, 52.0);
        expect(service.currentUser.fitnessGoal, 'Improve Stamina');
        expect(service.currentUser.dietPreference, 'Eggetarian');
        expect(service.currentUser.budgetPreference, 'Budget Friendly');
      },
    );

    test(
      'syncFromOnboarding updates vitals, goals, preferences and persists',
      () async {
        const onboarding = OnboardingProfile(
          goal: 'Build Muscle',
          workoutLocation: 'College Gym',
          equipment: ['Full Gym'],
          age: 21,
          heightCm: 178.0,
          weightKg: 72.0,
          fitnessLevel: 'Intermediate',
          dietaryPreference: 'Non-vegetarian',
          foodBudget: 'Moderate',
          motivations: ['Competition'],
          journeyPreference: 'Campus Champion',
          isCompleted: true,
        );

        await service.syncFromOnboarding(onboarding);

        expect(service.currentUser.fitnessGoal, 'Build Muscle');
        expect(service.currentUser.workoutLocation, 'College Gym');
        expect(service.currentUser.equipment, ['Full Gym']);
        expect(service.currentUser.age, 21);
        expect(service.currentUser.heightCm, 178.0);
        expect(service.currentUser.weightKg, 72.0);
        expect(service.currentUser.fitnessLevel, 'Intermediate');
        expect(service.currentUser.dietPreference, 'Non-vegetarian');
        expect(service.currentUser.budgetPreference, 'Moderate');
        expect(service.currentUser.isCompleted, isTrue);

        // Verify persistence
        await service.init();
        expect(service.currentUser.fitnessGoal, 'Build Muscle');
        expect(service.currentUser.age, 21);
      },
    );

    test('resetToDefaults resets profile back to initial demo state', () async {
      await service.updateFields(name: 'Changed Name', age: 30);
      expect(service.currentUser.name, 'Changed Name');

      await service.resetToDefaults();
      expect(service.currentUser.name, 'Ayush');
      expect(service.currentUser.age, 20);

      final savedFile = File('${tempDir.path}/genfit_user_profile.json');
      expect(savedFile.existsSync(), isFalse);
    });
  });
}
