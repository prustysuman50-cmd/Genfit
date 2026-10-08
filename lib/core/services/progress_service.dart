import 'package:flutter/foundation.dart';

import '../../models/progress/progress_summary.dart';
import 'daily_stats_service.dart';
import 'gamification_service.dart';
import 'journey_service.dart';
import 'nutrition_service.dart';
import 'user_service.dart';

/// Central service that aggregates user activity, nutrition logs, gamification XP,
/// Odisha Journey milestones, and weekly progress charts.
///
/// Daily telemetry (steps, active minutes, calories, water, workouts) is owned
/// and persisted authoritatively by [DailyStatsService]. This service provides
/// calendar week aggregations, progress summaries, and recent activity timelines.
class ProgressService extends ChangeNotifier {
  ProgressService._() {
    UserService.instance.addListener(notifyListeners);
    GamificationService.instance.addListener(notifyListeners);
    NutritionService.instance.addListener(notifyListeners);
    JourneyService.instance.addListener(notifyListeners);
    DailyStatsService.instance.addListener(notifyListeners);
  }

  static final ProgressService instance = ProgressService._();

  String? _customStoragePath;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  Future<void> init() async {
    if (_customStoragePath != null) {
      DailyStatsService.instance.setCustomStoragePath(_customStoragePath);
      await DailyStatsService.instance.init();
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Records daily telemetry by delegating to the authoritative [DailyStatsService].
  /// Preserved for backwards compatibility with earlier progress recording workflows.
  Future<void> recordDailyTelemetry({
    DateTime? date,
    int steps = 0,
    int activeMinutes = 0,
    int calories = 0,
    int workouts = 0,
  }) async {
    final targetDate = date ?? DateTime.now();
    final current = DailyStatsService.instance.getStatsForDate(targetDate);
    if (steps > 0 || activeMinutes > 0 || calories > 0) {
      await DailyStatsService.instance.updateActivity(
        steps: steps > 0 ? current.steps + steps : current.steps,
        activeMinutes: activeMinutes > 0
            ? current.activeMinutes + activeMinutes
            : current.activeMinutes,
        caloriesBurned: calories > 0
            ? current.caloriesBurned + calories
            : current.caloriesBurned,
        date: targetDate,
      );
    }
    if (workouts > 0) {
      await DailyStatsService.instance.recordWorkoutCompleted(
        durationMinutes: 0,
        totalReps: 0,
        caloriesBurned: 0,
        date: targetDate,
      );
    }
    notifyListeners();
  }

  /// Returns Monday-through-Sunday activity data for the current calendar week.
  /// Sourced purely from persisted DailyStats records for each calendar date.
  /// Unrecorded days remain zero (strictly no fabricated historical records).
  List<DailyActivitySummary> getWeeklyActivity({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    // Monday is weekday 1, Sunday is 7
    final currentWeekday = now.weekday;
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: currentWeekday - 1));

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final weekDays = <DailyActivitySummary>[];

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final isToday =
          dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;

      final dailyStats = DailyStatsService.instance.getStatsForDate(dayDate);

      weekDays.add(
        DailyActivitySummary(
          dayLabel: labels[i],
          dayName: names[i],
          workouts: dailyStats.workoutsCompleted,
          steps: dailyStats.steps,
          activeMinutes: dailyStats.activeMinutes + dailyStats.workoutMinutes,
          calories: dailyStats.caloriesBurned,
          waterMl: dailyStats.waterMl,
          isToday: isToday,
        ),
      );
    }

    return List.unmodifiable(weekDays);
  }

  /// Aggregates all live data from services into a unified ProgressSummary
  ProgressSummary getSummary() {
    final gamification = GamificationService.instance;
    final nutrition = NutritionService.instance;
    final journey = JourneyService.instance;
    final dailyStats = DailyStatsService.instance;

    final weekly = getWeeklyActivity();

    // Total weekly aggregated stats
    int weeklyWorkouts = 0;
    int weeklySteps = 0;
    int weeklyCalories = 0;
    int weeklyMinutes = 0;
    int weeklyWater = 0;

    for (final day in weekly) {
      weeklyWorkouts += day.workouts;
      weeklySteps += day.steps;
      weeklyCalories += day.calories;
      weeklyMinutes += day.activeMinutes;
      weeklyWater += day.waterMl;
    }

    // Workouts: aggregate from DailyStatsService records or gamification
    final totalDailyStatsWorkouts = dailyStats.allRecords.values.fold<int>(
      0,
      (sum, s) => sum + s.workoutsCompleted,
    );
    final totalWorkouts =
        totalDailyStatsWorkouts > gamification.totalWorkoutsCompleted
        ? totalDailyStatsWorkouts
        : (gamification.totalWorkoutsCompleted > weeklyWorkouts
              ? gamification.totalWorkoutsCompleted
              : weeklyWorkouts);

    // Total reps: aggregate from DailyStatsService records or gamification
    final totalDailyStatsReps = dailyStats.allRecords.values.fold<int>(
      0,
      (sum, s) => sum + s.totalReps,
    );
    final totalReps = totalDailyStatsReps > gamification.totalReps
        ? totalDailyStatsReps
        : gamification.totalReps;

    // Steps, active calories, active minutes: use real weekly aggregated data without synthetic fallbacks
    final totalSteps = weeklySteps;
    final totalCalories = weeklyCalories;
    final totalMinutes = weeklyMinutes;

    // Meals: aggregate from DailyStatsService records or NutritionService
    final totalDailyStatsMeals = dailyStats.allRecords.values.fold<int>(
      0,
      (sum, s) => sum + s.mealsLogged,
    );
    final mealsCount = totalDailyStatsMeals > 0
        ? totalDailyStatsMeals
        : (nutrition.allMeals.isNotEmpty
              ? nutrition.allMeals.length
              : gamification.totalMealsLogged);

    final badgesUnlocked = gamification.badges
        .where((b) => b.isUnlocked)
        .length;

    return ProgressSummary(
      workoutsCompleted: totalWorkouts,
      totalReps: totalReps,
      steps: totalSteps,
      activeCalories: totalCalories,
      activeMinutes: totalMinutes,
      waterMl: weeklyWater,
      currentStreak: gamification.streakDays,
      xp: gamification.xp,
      level: gamification.currentLevel,
      levelTitle: gamification.levelTitle,
      nutritionMealsLogged: mealsCount,
      journeyProgressKm: journey.currentProgressKm,
      journeyCompletionPercent: journey.progressPercent,
      badgesUnlocked: badgesUnlocked,
      totalBadges: gamification.badges.length,
      weeklyActivity: weekly,
    );
  }

  /// Gathers chronological recent activity items from workouts, meals, challenges, and journey
  List<Map<String, dynamic>> getRecentActivities() {
    final activities = <Map<String, dynamic>>[];
    final now = DateTime.now();

    final gamification = GamificationService.instance;
    final nutrition = NutritionService.instance;
    final journey = JourneyService.instance;
    final dailyStats = DailyStatsService.instance;

    final totalDailyWorkouts = dailyStats.allRecords.values.fold<int>(
      0,
      (sum, s) => sum + s.workoutsCompleted,
    );
    final totalDailyReps = dailyStats.allRecords.values.fold<int>(
      0,
      (sum, s) => sum + s.totalReps,
    );
    final effectiveWorkouts =
        totalDailyWorkouts > gamification.totalWorkoutsCompleted
        ? totalDailyWorkouts
        : gamification.totalWorkoutsCompleted;
    final effectiveReps = totalDailyReps > gamification.totalReps
        ? totalDailyReps
        : gamification.totalReps;

    // Recent workouts
    if (effectiveWorkouts > 0) {
      activities.add({
        'title': 'AI Rep Analysis Workout',
        'subtitle': '$effectiveReps total reps recorded',
        'category': 'Workout',
        'timestamp': now.subtract(const Duration(hours: 3)),
        'xp': 100,
        'icon': 'fitness',
      });
    }

    // Recent meals
    for (final meal in nutrition.allMeals.take(3)) {
      activities.add({
        'title': '${meal.name} (${meal.category.displayName})',
        'subtitle':
            '${meal.calories.toInt()} kcal • ${meal.protein.toStringAsFixed(1)}g protein',
        'category': 'Nutrition',
        'timestamp': meal.loggedAt,
        'xp': 20,
        'icon': 'nutrition',
      });
    }

    // Completed challenges
    for (final challenge in gamification.challenges.where(
      (c) => c.isCompleted,
    )) {
      activities.add({
        'title': challenge.title,
        'subtitle': 'Campus quest completed • +${challenge.rewardXp} XP',
        'category': 'Challenge',
        'timestamp': now.subtract(const Duration(hours: 8)),
        'xp': challenge.rewardXp,
        'icon': 'challenge',
      });
    }

    // Journey destinations
    for (final dest in journey.completedDestinations) {
      if (dest.requiredProgress > 0) {
        activities.add({
          'title': 'Reached ${dest.name}',
          'subtitle':
              '${dest.distanceKm.toStringAsFixed(1)} km landmark reached',
          'category': 'Journey',
          'timestamp': now.subtract(const Duration(days: 1)),
          'xp': 100,
          'icon': 'journey',
        });
      }
    }

    // Sort by timestamp descending
    activities.sort((a, b) {
      final timeA = a['timestamp'] as DateTime;
      final timeB = b['timestamp'] as DateTime;
      return timeB.compareTo(timeA);
    });

    return activities;
  }

  Future<void> resetToDefaults() async {
    notifyListeners();
  }
}
