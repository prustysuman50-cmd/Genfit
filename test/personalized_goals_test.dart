import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/personalized_goal_service.dart';
import 'package:genfit/models/personalized_goals.dart';
import 'package:genfit/models/user_profile.dart';

void main() {
  group('GenFit Phase 1 Step 8A: Personalized Goals Engine Tests', () {
    final goalService = PersonalizedGoalService.instance;

    test('1. defaultGoals exactly match the existing fallback goals', () {
      const defaults = PersonalizedGoals.defaultGoals;

      expect(defaults.stepsGoal, equals(10000));
      expect(defaults.waterGoalMl, equals(3000));
      expect(defaults.caloriesBurnedGoal, equals(650));
      expect(defaults.activeMinutesGoal, equals(45));
      expect(defaults.caloriesConsumedGoal, equals(2100.0));
      expect(defaults.proteinGoalGrams, equals(110.0));
    });

    test('2. Missing/null profile safely returns fallback goals', () {
      final goalsNull = goalService.calculateGoals(null);

      expect(goalsNull.stepsGoal, equals(10000));
      expect(goalsNull.waterGoalMl, equals(3000));
      expect(goalsNull.caloriesBurnedGoal, equals(650));
      expect(goalsNull.activeMinutesGoal, equals(45));
      expect(goalsNull.caloriesConsumedGoal, equals(2100.0));
      expect(goalsNull.proteinGoalGrams, equals(110.0));
    });

    test(
      '3. Normal student profile produces deterministic personalized goals',
      () {
        const student = UserProfile(
          age: 20,
          heightCm: 172.0,
          weightKg: 65.0,
          fitnessGoal: 'Stay Fit',
          fitnessLevel: 'Beginner',
          dietPreference: 'Vegetarian',
        );

        final goals = goalService.calculateGoals(student);

        // Water: 65 * 35 = 2275 -> 2300 ml
        expect(goals.waterGoalMl, equals(2300));
        // Steps: Beginner -> 8000
        expect(goals.stepsGoal, equals(8000));
        // Active minutes: Beginner -> 30 min
        expect(goals.activeMinutesGoal, equals(30));
        // Active calories: 65 * 9.5 = 617.5 - 50 (beginner) = 567.5 -> 575 kcal
        expect(goals.caloriesBurnedGoal, equals(575));
        // Calorie intake: BMR = 10*65 + 6.25*172 - 5*20 + 5 = 1630 * 1.35 = 2200.5 -> 2200 kcal
        expect(goals.caloriesConsumedGoal, equals(2200.0));
        // Protein: 65 * 1.4 = 91 -> 90g
        expect(goals.proteinGoalGrams, equals(90.0));
      },
    );

    test('4. Different weights produce sensible water and protein changes', () {
      const lighterUser = UserProfile(
        age: 20,
        heightCm: 165.0,
        weightKg: 50.0,
        fitnessGoal: 'Stay Fit',
        fitnessLevel: 'Intermediate',
      );

      const heavierUser = UserProfile(
        age: 20,
        heightCm: 180.0,
        weightKg: 85.0,
        fitnessGoal: 'Stay Fit',
        fitnessLevel: 'Intermediate',
      );

      final lighterGoals = goalService.calculateGoals(lighterUser);
      final heavierGoals = goalService.calculateGoals(heavierUser);

      // Heavier user requires more water
      expect(heavierGoals.waterGoalMl, greaterThan(lighterGoals.waterGoalMl));
      expect(
        lighterGoals.waterGoalMl,
        equals(2000),
      ); // 50 * 35 = 1750 clamped to 2000
      expect(heavierGoals.waterGoalMl, equals(3000)); // 85 * 35 = 2975 -> 3000

      // Heavier user requires more protein
      expect(
        heavierGoals.proteinGoalGrams,
        greaterThan(lighterGoals.proteinGoalGrams),
      );
      expect(lighterGoals.proteinGoalGrams, equals(70.0)); // 50 * 1.4 = 70
      expect(
        heavierGoals.proteinGoalGrams,
        equals(120.0),
      ); // 85 * 1.4 = 119 -> 120
    });

    test('5. Different fitness levels affect steps and active minutes', () {
      const beginner = UserProfile(
        fitnessLevel: 'Beginner',
        fitnessGoal: 'Stay Fit',
      );
      const intermediate = UserProfile(
        fitnessLevel: 'Intermediate',
        fitnessGoal: 'Stay Fit',
      );
      const advanced = UserProfile(
        fitnessLevel: 'Advanced',
        fitnessGoal: 'Stay Fit',
      );

      final bGoals = goalService.calculateGoals(beginner);
      final iGoals = goalService.calculateGoals(intermediate);
      final aGoals = goalService.calculateGoals(advanced);

      expect(bGoals.stepsGoal, equals(8000));
      expect(iGoals.stepsGoal, equals(10000));
      expect(aGoals.stepsGoal, equals(12000));

      expect(bGoals.activeMinutesGoal, equals(30));
      expect(iGoals.activeMinutesGoal, equals(45));
      expect(aGoals.activeMinutesGoal, equals(60));
    });

    test('6. Different fitness goals affect relevant targets', () {
      const loseFat = UserProfile(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 21,
        fitnessGoal: 'Lose Fat',
        fitnessLevel: 'Intermediate',
      );

      const buildMuscle = UserProfile(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 21,
        fitnessGoal: 'Build Muscle',
        fitnessLevel: 'Intermediate',
      );

      const stayFit = UserProfile(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 21,
        fitnessGoal: 'Stay Fit',
        fitnessLevel: 'Intermediate',
      );

      final fatLossGoals = goalService.calculateGoals(loseFat);
      final muscleGoals = goalService.calculateGoals(buildMuscle);
      final fitGoals = goalService.calculateGoals(stayFit);

      // Calorie intake: deficit for fat loss, surplus for muscle gain
      expect(
        fatLossGoals.caloriesConsumedGoal,
        lessThan(fitGoals.caloriesConsumedGoal),
      );
      expect(
        muscleGoals.caloriesConsumedGoal,
        greaterThan(fitGoals.caloriesConsumedGoal),
      );

      // Protein: muscle gain > fat loss > stay fit
      expect(
        muscleGoals.proteinGoalGrams,
        greaterThanOrEqualTo(fatLossGoals.proteinGoalGrams),
      );
      expect(
        fatLossGoals.proteinGoalGrams,
        greaterThan(fitGoals.proteinGoalGrams),
      );

      // Steps: fat loss adds 1000 steps compared to stay fit
      expect(fatLossGoals.stepsGoal, equals(fitGoals.stepsGoal + 1000));

      // Active burn: fat loss sets higher burn goal than stay fit
      expect(
        fatLossGoals.caloriesBurnedGoal,
        greaterThan(fitGoals.caloriesBurnedGoal),
      );
    });

    test('7. Goals remain strictly within all declared safety bounds', () {
      // Very heavy user
      const extremeHeavy = UserProfile(
        weightKg: 220.0,
        heightCm: 210.0,
        age: 25,
        fitnessLevel: 'Advanced',
        fitnessGoal: 'Lose Fat',
      );

      final heavyGoals = goalService.calculateGoals(extremeHeavy);
      expect(heavyGoals.waterGoalMl, inInclusiveRange(2000, 4000));
      expect(heavyGoals.stepsGoal, inInclusiveRange(6000, 15000));
      expect(heavyGoals.activeMinutesGoal, inInclusiveRange(25, 75));
      expect(heavyGoals.caloriesBurnedGoal, inInclusiveRange(400, 950));
      expect(heavyGoals.caloriesConsumedGoal, inInclusiveRange(1500.0, 3200.0));
      expect(heavyGoals.proteinGoalGrams, inInclusiveRange(60.0, 175.0));

      // Very light user
      const extremeLight = UserProfile(
        weightKg: 35.0,
        heightCm: 140.0,
        age: 18,
        fitnessLevel: 'Beginner',
        fitnessGoal: 'Stay Fit',
      );

      final lightGoals = goalService.calculateGoals(extremeLight);
      expect(lightGoals.waterGoalMl, inInclusiveRange(2000, 4000));
      expect(lightGoals.stepsGoal, inInclusiveRange(6000, 15000));
      expect(lightGoals.activeMinutesGoal, inInclusiveRange(25, 75));
      expect(lightGoals.caloriesBurnedGoal, inInclusiveRange(400, 950));
      expect(lightGoals.caloriesConsumedGoal, inInclusiveRange(1500.0, 3200.0));
      expect(lightGoals.proteinGoalGrams, inInclusiveRange(60.0, 175.0));
    });

    test('8. Same UserProfile produces identical results every time (pure determinism)', () {
      const user = UserProfile(
        age: 22,
        heightCm: 178.0,
        weightKg: 72.0,
        fitnessGoal: 'Improve Stamina',
        fitnessLevel: 'Intermediate',
      );

      final run1 = goalService.calculateGoals(user);
      final run2 = goalService.calculateGoals(user);
      final run3 = goalService.calculateGoals(user);

      expect(run1, equals(run2));
      expect(run2, equals(run3));
      expect(run1.hashCode, equals(run2.hashCode));
    });

    test('9. No DailyStats actual telemetry is involved or modified', () {
      const user = UserProfile(weightKg: 68.0, heightCm: 174.0, age: 20);

      final goals = goalService.calculateGoals(user);

      // Verify returned object is strictly PersonalizedGoals
      expect(goals, isA<PersonalizedGoals>());
      expect(goals.stepsGoal, isPositive);
      expect(goals.waterGoalMl, isPositive);
    });

    test('10. Vegetarian/vegan profile does not produce unsafe/extreme protein targets', () {
      const heavyVegUser = UserProfile(
        weightKg: 100.0,
        fitnessGoal: 'Build Muscle',
        dietPreference: 'Vegetarian',
      );

      final goals = goalService.calculateGoals(heavyVegUser);
      // 100 * 1.8 = 180g, but clamped to 140g for vegetarian college dining realism
      expect(goals.proteinGoalGrams, equals(140.0));
    });

    test('11. Boundary/invalid values are handled safely with fallbacks', () {
      const invalidUser = UserProfile(age: -5, heightCm: 0.0, weightKg: -20.0);

      final goals = goalService.calculateGoals(invalidUser);

      // Invalid weight/height/age safely fall back to standard defaults
      expect(
        goals.waterGoalMl,
        equals(PersonalizedGoals.defaultGoals.waterGoalMl),
      );
      expect(
        goals.caloriesBurnedGoal,
        equals(PersonalizedGoals.defaultGoals.caloriesBurnedGoal),
      );
      expect(
        goals.caloriesConsumedGoal,
        equals(PersonalizedGoals.defaultGoals.caloriesConsumedGoal),
      );
      expect(
        goals.proteinGoalGrams,
        equals(PersonalizedGoals.defaultGoals.proteinGoalGrams),
      );
    });

    test(
      '12. Existing fallback defaults remain intact and model JSON roundtrips',
      () {
        const original = PersonalizedGoals.defaultGoals;
        final json = original.toJson();
        final restored = PersonalizedGoals.fromJson(json);

        expect(restored, equals(original));
        expect(restored.toString(), contains('PersonalizedGoals'));
      },
    );
  });
}
