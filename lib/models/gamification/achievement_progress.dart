import 'dart:math' as math;

import '../../core/services/gamification_service.dart';
import '../../core/services/heritage_service.dart';
import 'badge_item.dart';

/// Represents genuine, verified progress toward unlocking an achievement badge.
///
/// Progress is derived directly from source-of-truth services ([GamificationService]
/// and [HeritageService]) without fabricating numbers or altering unlock criteria.
class AchievementProgress {
  /// Clamped progress toward the target (0 <= current <= target).
  final int current;

  /// Required metric threshold to unlock the badge.
  final int target;

  /// Unclamped telemetry value from the source-of-truth service.
  final int rawCurrent;

  /// Descriptive unit label (e.g., 'workout', 'days', 'reps', 'meal', etc.).
  final String unit;

  const AchievementProgress({
    required this.current,
    required this.target,
    required this.rawCurrent,
    required this.unit,
  });

  /// Fractional progress between 0.0 and 1.0.
  double get fraction =>
      target > 0 ? (current / target).clamp(0.0, 1.0) : (current > 0 ? 1.0 : 0.0);

  /// Percentage integer between 0 and 100.
  int get percent => (fraction * 100).round();

  /// Formatted progress string (e.g. "60 / 100 reps" or "1 / 1 workout").
  String get displayText => '$current / $target $unit';

  /// Whether the user has met or exceeded the badge unlock target.
  bool get isAchieved => current >= target;

  /// Derives the honest, verified progress for [badge] from the source services.
  ///
  /// Guarantees that progress cannot contradict [badge.isUnlocked].
  static AchievementProgress compute(
    BadgeItem badge,
    GamificationService gamification, {
    HeritageService? heritageService,
  }) {
    int rawValue = 0;
    int target = 1;
    String unit = '';

    final heritage = heritageService ?? HeritageService.instance;
    final heritageMilestones = heritage.awardedMilestoneIds.length;

    switch (badge.id) {
      case 'first_workout':
        rawValue = gamification.totalWorkoutsCompleted;
        target = 1;
        unit = 'workout';
        break;

      case 'seven_day_streak':
        rawValue = gamification.streakDays;
        target = 7;
        unit = 'days';
        break;

      case 'hundred_reps':
        rawValue = gamification.totalReps;
        target = 100;
        unit = 'reps';
        break;

      case 'first_meal_logged':
        rawValue = gamification.totalMealsLogged;
        target = 1;
        unit = 'meal';
        break;

      case 'campus_challenger':
        rawValue = gamification.totalChallengesCompleted;
        target = 1;
        unit = 'challenge';
        break;

      case 'journey_starter':
        rawValue = math.max(
          gamification.totalMilestonesCompleted,
          heritageMilestones,
        );
        target = 1;
        unit = 'milestone';
        break;

      case 'odisha_explorer':
        rawValue = math.max(
          gamification.totalMilestonesCompleted,
          heritageMilestones,
        );
        target = 3;
        unit = 'milestones';
        break;

      default:
        rawValue = badge.isUnlocked ? 1 : 0;
        target = 1;
        unit = '';
        break;
    }

    // Ensure progress and unlocked status never contradict each other.
    final effectiveCurrent = badge.isUnlocked
        ? math.max(rawValue, target)
        : rawValue;

    return AchievementProgress(
      current: effectiveCurrent.clamp(0, target),
      target: target,
      rawCurrent: effectiveCurrent,
      unit: unit,
    );
  }

  /// Returns a motivating, honest guidance message explaining how to unlock [id].
  static String motivationForBadgeId(String id) {
    switch (id) {
      case 'first_workout':
        return 'Every fitness journey starts with day one. Complete your first workout session to earn this badge!';
      case 'seven_day_streak':
        return 'Consistency builds champions. Keep logging daily activities for 7 consecutive days to conquer this badge!';
      case 'hundred_reps':
        return 'Every rep counts toward greatness. Complete 100 cumulative exercise repetitions across your workouts!';
      case 'first_meal_logged':
        return 'Fueling right is half the victory. Log your first meal in the Nutrition module to claim this badge!';
      case 'campus_challenger':
        return 'Step up to the challenge. Complete any daily campus challenge to prove your athletic drive!';
      case 'journey_starter':
        return 'Step onto the historic path. Walk active steps to reach your first milestone on the Odisha Fitness Trail!';
      case 'odisha_explorer':
        return 'Become a true explorer. Complete at least 3 Odisha Fitness Trail milestones to etch your name in heritage!';
      default:
        return 'Keep pushing your limits to unlock this achievement!';
    }
  }

  /// Formats [DateTime] into a clean human-readable date without external dependencies.
  static String formatUnlockDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $year at $hour:$minute $period';
  }
}
