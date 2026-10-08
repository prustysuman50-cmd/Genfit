import 'package:flutter/foundation.dart';

import '../../models/personalized_goals.dart';
import '../../models/user_profile.dart';
import 'user_service.dart';

/// Centralized service calculating personalized, deterministic daily goals
/// from the user's existing profile metrics and fitness preferences.
///
/// Implements conservative heuristics suitable for a college-student fitness app.
/// These targets represent general lifestyle fitness recommendations, NOT
/// medical or clinical prescriptions.
class PersonalizedGoalService extends ChangeNotifier {
  PersonalizedGoalService._() {
    UserService.instance.addListener(_onUserChanged);
  }

  static final PersonalizedGoalService instance = PersonalizedGoalService._();

  void _onUserChanged() {
    notifyListeners();
  }

  /// Whether the user has a completed, personalized profile.
  bool get hasUsableProfile => UserService.instance.currentUser.isCompleted;

  /// Current goals calculated from [UserService.instance.currentUser].
  ///
  /// Falls back to [PersonalizedGoals.defaultGoals] if no usable, completed
  /// personalized profile is available.
  PersonalizedGoals get currentGoals {
    final user = UserService.instance.currentUser;
    if (!user.isCompleted) {
      return PersonalizedGoals.defaultGoals;
    }
    return calculateGoals(user);
  }

  /// Pure, deterministic calculation of [PersonalizedGoals] given a [UserProfile].
  ///
  /// If [profile] is null, empty, or uncompleted, or contains invalid/absurd
  /// physical values, graceful fallback to default targets is applied.
  PersonalizedGoals calculateGoals(UserProfile? profile) {
    if (profile == null) {
      return PersonalizedGoals.defaultGoals;
    }

    return PersonalizedGoals(
      stepsGoal: calculateStepsGoal(profile),
      waterGoalMl: calculateWaterGoal(profile),
      caloriesBurnedGoal: calculateCaloriesBurnedGoal(profile),
      activeMinutesGoal: calculateActiveMinutesGoal(profile),
      caloriesConsumedGoal: calculateCaloriesConsumedGoal(profile),
      proteinGoalGrams: calculateProteinGoal(profile),
    );
  }

  /// Calculates the daily water goal in milliliters.
  ///
  /// Baseline heuristic: ~35 ml per kg of body weight, rounded to nearest 50 ml.
  /// Clamped between 2,000 ml and 4,000 ml.
  static int calculateWaterGoal(UserProfile? profile) {
    if (profile == null) return PersonalizedGoals.defaultGoals.waterGoalMl;

    final weight = profile.weightKg;
    if (weight <= 30.0 || weight > 250.0 || weight.isNaN) {
      return PersonalizedGoals.defaultGoals.waterGoalMl;
    }

    double baseMl = weight * 35.0;

    final goal = profile.fitnessGoal.trim().toLowerCase();
    if (goal.contains('lose fat') || goal.contains('improve stamina')) {
      baseMl += 250.0;
    }

    final rounded = (baseMl / 50.0).round() * 50;
    return rounded.clamp(2000, 4000);
  }

  /// Calculates the daily steps goal.
  ///
  /// Baseline heuristic based on fitness level:
  /// - Beginner: 8,000
  /// - Intermediate: 10,000
  /// - Advanced: 12,000
  /// - Goal adjustment: +1,000 for 'Lose Fat' or 'Improve Stamina'
  /// Clamped between 6,000 and 15,000 steps.
  static int calculateStepsGoal(UserProfile? profile) {
    if (profile == null) return PersonalizedGoals.defaultGoals.stepsGoal;

    final level = profile.fitnessLevel.trim().toLowerCase();
    int baseSteps;
    if (level.contains('beginner')) {
      baseSteps = 8000;
    } else if (level.contains('advanced')) {
      baseSteps = 12000;
    } else {
      baseSteps = 10000;
    }

    final goal = profile.fitnessGoal.trim().toLowerCase();
    if (goal.contains('lose fat') || goal.contains('improve stamina')) {
      baseSteps += 1000;
    }

    return baseSteps.clamp(6000, 15000);
  }

  /// Calculates daily active minutes goal.
  ///
  /// Baseline heuristic based on fitness level:
  /// - Beginner: 30 mins
  /// - Intermediate: 45 mins
  /// - Advanced: 60 mins
  /// - Stamina goal: +5 mins
  /// Clamped between 25 and 75 minutes.
  static int calculateActiveMinutesGoal(UserProfile? profile) {
    if (profile == null) {
      return PersonalizedGoals.defaultGoals.activeMinutesGoal;
    }

    final level = profile.fitnessLevel.trim().toLowerCase();
    int baseMins;
    if (level.contains('beginner')) {
      baseMins = 30;
    } else if (level.contains('advanced')) {
      baseMins = 60;
    } else {
      baseMins = 45;
    }

    final goal = profile.fitnessGoal.trim().toLowerCase();
    if (goal.contains('improve stamina')) {
      baseMins += 5;
    }

    return baseMins.clamp(25, 75);
  }

  /// Calculates the daily active calories burned goal.
  ///
  /// Baseline heuristic based on body weight and activity goal:
  /// - base = weightKg * 9.5
  /// - Lose Fat: +100 kcal
  /// - Build Muscle: +50 kcal
  /// - Advanced: +100 kcal
  /// - Beginner: -50 kcal
  /// Rounded to nearest 25 kcal, clamped between 400 and 950 kcal.
  static int calculateCaloriesBurnedGoal(UserProfile? profile) {
    if (profile == null) {
      return PersonalizedGoals.defaultGoals.caloriesBurnedGoal;
    }

    final weight = profile.weightKg;
    if (weight <= 30.0 || weight > 250.0 || weight.isNaN) {
      return PersonalizedGoals.defaultGoals.caloriesBurnedGoal;
    }

    double baseBurn = weight * 9.5;

    final goal = profile.fitnessGoal.trim().toLowerCase();
    if (goal.contains('lose fat')) {
      baseBurn += 100.0;
    } else if (goal.contains('build muscle')) {
      baseBurn += 50.0;
    }

    final level = profile.fitnessLevel.trim().toLowerCase();
    if (level.contains('advanced')) {
      baseBurn += 100.0;
    } else if (level.contains('beginner')) {
      baseBurn -= 50.0;
    }

    final rounded = (baseBurn / 25.0).round() * 25;
    return rounded.clamp(400, 950);
  }

  /// Calculates the daily calories consumed goal.
  ///
  /// Transparent BMR-style baseline estimate for student fitness:
  /// BMR = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
  /// Scaled by ~1.35 student daily activity factor.
  /// Goal adjustments:
  /// - Lose Fat: -300 kcal (moderate deficit)
  /// - Build Muscle: +250 kcal (moderate surplus)
  /// - Stay Fit / neutral: no adjustment
  /// Rounded to nearest 50 kcal, clamped between 1,500 and 3,200 kcal.
  static double calculateCaloriesConsumedGoal(UserProfile? profile) {
    if (profile == null) {
      return PersonalizedGoals.defaultGoals.caloriesConsumedGoal;
    }

    final weight = profile.weightKg;
    final height = profile.heightCm;
    final age = profile.age;

    // Safety checks for physical plausibility
    if (weight <= 30.0 ||
        weight > 250.0 ||
        weight.isNaN ||
        height <= 100.0 ||
        height > 250.0 ||
        height.isNaN ||
        age <= 10 ||
        age > 120) {
      return PersonalizedGoals.defaultGoals.caloriesConsumedGoal;
    }

    final double bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) + 5.0;
    double tdee = bmr * 1.35;

    final goal = profile.fitnessGoal.trim().toLowerCase();
    if (goal.contains('lose fat')) {
      tdee -= 300.0;
    } else if (goal.contains('build muscle')) {
      tdee += 250.0;
    }

    final rounded = ((tdee / 50.0).round() * 50).toDouble();
    return rounded.clamp(1500.0, 3200.0);
  }

  /// Calculates the daily protein goal in grams.
  ///
  /// Baseline heuristic based on body weight and fitness goal:
  /// - Build Muscle: 1.8 g/kg
  /// - Lose Fat: 1.6 g/kg
  /// - Stay Fit / neutral: 1.4 g/kg
  /// For vegetarian/vegan profiles, upper bound is safely capped at 140g
  /// to ensure student mess dining realism.
  /// Rounded to nearest 5g, clamped between 60g and 175g.
  static double calculateProteinGoal(UserProfile? profile) {
    if (profile == null) {
      return PersonalizedGoals.defaultGoals.proteinGoalGrams;
    }

    final weight = profile.weightKg;
    if (weight <= 30.0 || weight > 250.0 || weight.isNaN) {
      return PersonalizedGoals.defaultGoals.proteinGoalGrams;
    }

    double gPerKg;
    final goal = profile.fitnessGoal.trim().toLowerCase();
    if (goal.contains('build muscle')) {
      gPerKg = 1.8;
    } else if (goal.contains('lose fat')) {
      gPerKg = 1.6;
    } else {
      gPerKg = 1.4;
    }

    final rawProtein = weight * gPerKg;

    final diet = profile.dietPreference.trim().toLowerCase();
    double maxCap = 175.0;
    if (diet.contains('vegetarian') ||
        diet.contains('vegan') ||
        diet.contains('jain')) {
      maxCap = 140.0;
    }

    final rounded = ((rawProtein / 5.0).round() * 5).toDouble();
    return rounded.clamp(60.0, maxCap);
  }
}
