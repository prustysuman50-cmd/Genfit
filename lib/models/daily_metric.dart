import 'daily_stats.dart';

class DailyMetrics {
  final int steps;
  final int stepsGoal;
  final double waterLiters;
  final double waterGoalLiters;
  final int caloriesBurned;
  final int caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;

  const DailyMetrics({
    required this.steps,
    required this.stepsGoal,
    required this.waterLiters,
    required this.waterGoalLiters,
    required this.caloriesBurned,
    required this.caloriesGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
  });

  factory DailyMetrics.fromDailyStats(DailyStats stats) {
    return DailyMetrics(
      steps: stats.steps,
      stepsGoal: stats.stepsGoal,
      waterLiters: stats.waterLiters,
      waterGoalLiters: stats.waterGoalLiters,
      caloriesBurned: stats.caloriesBurned,
      caloriesGoal: stats.caloriesBurnedGoal,
      activeMinutes: stats.activeMinutes,
      activeMinutesGoal: stats.activeMinutesGoal,
    );
  }

  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);
  double get waterProgress => (waterLiters / waterGoalLiters).clamp(0.0, 1.0);
  double get caloriesProgress =>
      (caloriesBurned / caloriesGoal).clamp(0.0, 1.0);
  double get activeProgress =>
      (activeMinutes / activeMinutesGoal).clamp(0.0, 1.0);

  // Overall combined daily completion percentage
  double get overallProgress =>
      (stepsProgress * 0.4 + caloriesProgress * 0.4 + waterProgress * 0.2);

  DailyMetrics copyWith({
    int? steps,
    int? stepsGoal,
    double? waterLiters,
    double? waterGoalLiters,
    int? caloriesBurned,
    int? caloriesGoal,
    int? activeMinutes,
    int? activeMinutesGoal,
  }) {
    return DailyMetrics(
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      waterLiters: waterLiters ?? this.waterLiters,
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      activeMinutesGoal: activeMinutesGoal ?? this.activeMinutesGoal,
    );
  }
}
