import 'package:flutter/foundation.dart';

import '../../models/progress/recommendation_item.dart';
import 'gamification_service.dart';
import 'journey_service.dart';
import 'nutrition_service.dart';
import 'user_service.dart';

/// Central service generating explainable, rule-based adaptive fitness and lifestyle recommendations.
/// This system is strictly non-medical and focuses on student consistency, campus nutrition, and milestone encouragement.
class RecommendationService extends ChangeNotifier {
  RecommendationService._() {
    UserService.instance.addListener(notifyListeners);
    GamificationService.instance.addListener(notifyListeners);
    NutritionService.instance.addListener(notifyListeners);
    JourneyService.instance.addListener(notifyListeners);
  }

  static final RecommendationService instance = RecommendationService._();

  /// Evaluates current state across all modules and returns prioritized adaptive recommendations
  List<RecommendationItem> getRecommendations() {
    final user = UserService.instance.currentUser;
    final gamification = GamificationService.instance;
    final nutrition = NutritionService.instance;
    final journey = JourneyService.instance;

    final recommendations = <RecommendationItem>[];

    final streak = gamification.streakDays;
    final workouts = gamification.totalWorkoutsCompleted;
    final mealsCount = nutrition.todayMeals.length;
    final proteinConsumed = nutrition.todayProtein;
    final proteinTarget = nutrition.proteinTarget;
    final journeyKm = journey.currentProgressKm;
    final nextMilestone = journey.currentDestination.name;

    // RULE 1: Consistency & Streak
    if (streak >= 5) {
      recommendations.add(
        RecommendationItem(
          id: 'rec_streak_high',
          title: 'Streak Momentum',
          message:
              'Keep your $streak-day streak going with today\'s quick hostel workout.',
          category: 'Streak',
          actionLabel: 'Keep Streak Alive',
          iconIdentifier: 'flame',
          priority: 2,
        ),
      );
    } else if (streak == 0 || workouts == 0) {
      recommendations.add(
        const RecommendationItem(
          id: 'rec_consistency_low',
          title: 'Build Consistency',
          message:
              'Try a short 10-minute workout today to rebuild your streak.',
          category: 'Consistency',
          actionLabel: 'Start Workout',
          iconIdentifier: 'flame',
          priority: 1,
        ),
      );
    }

    // RULE 2: Workout Progression & Goal Alignment
    if (workouts >= 3) {
      recommendations.add(
        const RecommendationItem(
          id: 'rec_workout_progression',
          title: 'Increase Intensity',
          message: 'You\'re building strong consistency. Consider increasing your workout difficulty gradually.',
          category: 'Workout',
          actionLabel: 'Explore Workouts',
          iconIdentifier: 'fitness',
          priority: 3,
        ),
      );
    } else if (user.fitnessGoal.toLowerCase().contains('muscle')) {
      recommendations.add(
        const RecommendationItem(
          id: 'rec_goal_muscle',
          title: 'Muscle Growth Focus',
          message: 'For your goal of building muscle, push for full range of motion on squats and push-ups.',
          category: 'Workout',
          actionLabel: 'AI Vision Workout',
          iconIdentifier: 'fitness',
          priority: 3,
        ),
      );
    } else if (user.fitnessGoal.toLowerCase().contains('weight') ||
        user.fitnessGoal.toLowerCase().contains('fat')) {
      recommendations.add(
        const RecommendationItem(
          id: 'rec_goal_fat_loss',
          title: 'Metabolic Conditioning',
          message: 'Combine brisk campus walks with AI squats to elevate your daily calorie burn.',
          category: 'Workout',
          actionLabel: 'Start Workout',
          iconIdentifier: 'fitness',
          priority: 3,
        ),
      );
    }

    // RULE 3: Nutrition Logging
    if (mealsCount == 0) {
      recommendations.add(
        const RecommendationItem(
          id: 'rec_nutrition_log',
          title: 'Log Mess Nutrition',
          message: 'Log your next hostel/mess meal to improve your nutrition tracking.',
          category: 'Nutrition',
          actionLabel: 'Open Mess Menu',
          iconIdentifier: 'nutrition',
          priority: 2,
        ),
      );
    }

    // RULE 4: Protein Intake vs Diet Preference
    final diet = user.dietPreference.toLowerCase();
    final isVeg = diet.contains('veg') && !diet.contains('non');
    if (mealsCount > 0 && proteinConsumed < (proteinTarget * 0.7)) {
      final proteinSources = isVeg
          ? 'dal, dalma, soya chunks, chana, or paneer'
          : 'dal, eggs, soya or paneer';

      recommendations.add(
        RecommendationItem(
          id: 'rec_protein_target',
          title: 'Protein Optimization',
          message:
              'Your protein intake is below target. Consider a protein-rich option such as $proteinSources.',
          category: 'Nutrition',
          actionLabel: 'View High-Protein Foods',
          iconIdentifier: 'nutrition',
          priority: 2,
        ),
      );
    }

    // RULE 5: Odisha Journey Progress
    if (journeyKm < 15.0 || !journey.isDestinationCompleted('dest_cuttack')) {
      recommendations.add(
        RecommendationItem(
          id: 'rec_journey_progress',
          title: 'Odisha Trail Advance',
          message:
              'Complete a workout or challenge to continue your Odisha Journey toward $nextMilestone.',
          category: 'Journey',
          actionLabel: 'View Odisha Trail',
          iconIdentifier: 'explore',
          priority: 4,
        ),
      );
    }

    // Fallback if none matched
    if (recommendations.isEmpty) {
      recommendations.add(
        const RecommendationItem(
          id: 'rec_general_keep_going',
          title: 'Stay Consistent',
          message: 'Small daily efforts compound into major campus fitness transformations.',
          category: 'Consistency',
          actionLabel: 'View Workouts',
          iconIdentifier: 'star',
          priority: 5,
        ),
      );
    }

    // Sort by priority (1 is highest)
    recommendations.sort((a, b) => a.priority.compareTo(b.priority));
    return List.unmodifiable(recommendations);
  }

  /// Returns the top-ranked single recommendation
  RecommendationItem getPrimaryRecommendation() {
    return getRecommendations().first;
  }
}
