class DailyStats {
  final String date; // Canonical 'YYYY-MM-DD'
  final int steps;
  final int stepsGoal;
  final int activeMinutes;
  final int activeMinutesGoal;
  final int caloriesBurned;
  final int caloriesBurnedGoal;
  final int waterMl;
  final int waterGoalMl;
  final double caloriesConsumed;
  final double caloriesConsumedGoal;
  final double proteinGrams;
  final double proteinGoalGrams;
  final double carbsGrams;
  final double fatsGrams;
  final int mealsLogged;
  final int workoutsCompleted;
  final int workoutMinutes;
  final int totalReps;

  const DailyStats({
    required this.date,
    this.steps = 0,
    this.stepsGoal = 10000,
    this.activeMinutes = 0,
    this.activeMinutesGoal = 45,
    this.caloriesBurned = 0,
    this.caloriesBurnedGoal = 650,
    this.waterMl = 0,
    this.waterGoalMl = 3000,
    this.caloriesConsumed = 0.0,
    this.caloriesConsumedGoal = 2100.0,
    this.proteinGrams = 0.0,
    this.proteinGoalGrams = 110.0,
    this.carbsGrams = 0.0,
    this.fatsGrams = 0.0,
    this.mealsLogged = 0,
    this.workoutsCompleted = 0,
    this.workoutMinutes = 0,
    this.totalReps = 0,
  });

  /// Formats a [DateTime] into canonical 'YYYY-MM-DD' representation
  static String formatDate(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Factory creating an empty stats record for the specified or current day
  factory DailyStats.createToday([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DailyStats(date: formatDate(d));
  }

  double get waterLiters => waterMl / 1000.0;
  double get waterGoalLiters => waterGoalMl / 1000.0;

  double get waterProgress =>
      waterGoalMl > 0 ? (waterMl / waterGoalMl).clamp(0.0, 1.0) : 0.0;

  double get stepsProgress =>
      stepsGoal > 0 ? (steps / stepsGoal).clamp(0.0, 1.0) : 0.0;

  double get activeMinutesProgress => activeMinutesGoal > 0
      ? (activeMinutes / activeMinutesGoal).clamp(0.0, 1.0)
      : 0.0;

  double get caloriesBurnedProgress => caloriesBurnedGoal > 0
      ? (caloriesBurned / caloriesBurnedGoal).clamp(0.0, 1.0)
      : 0.0;

  double get caloriesConsumedProgress => caloriesConsumedGoal > 0
      ? (caloriesConsumed / caloriesConsumedGoal).clamp(0.0, 1.0)
      : 0.0;

  double get proteinProgress => proteinGoalGrams > 0
      ? (proteinGrams / proteinGoalGrams).clamp(0.0, 1.0)
      : 0.0;

  double get overallProgress =>
      (stepsProgress * 0.4 + caloriesBurnedProgress * 0.4 + waterProgress * 0.2)
          .clamp(0.0, 1.0);

  DailyStats copyWith({
    String? date,
    int? steps,
    int? stepsGoal,
    int? activeMinutes,
    int? activeMinutesGoal,
    int? caloriesBurned,
    int? caloriesBurnedGoal,
    int? waterMl,
    int? waterGoalMl,
    double? caloriesConsumed,
    double? caloriesConsumedGoal,
    double? proteinGrams,
    double? proteinGoalGrams,
    double? carbsGrams,
    double? fatsGrams,
    int? mealsLogged,
    int? workoutsCompleted,
    int? workoutMinutes,
    int? totalReps,
  }) {
    return DailyStats(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      activeMinutesGoal: activeMinutesGoal ?? this.activeMinutesGoal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesBurnedGoal: caloriesBurnedGoal ?? this.caloriesBurnedGoal,
      waterMl: waterMl ?? this.waterMl,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      caloriesConsumedGoal: caloriesConsumedGoal ?? this.caloriesConsumedGoal,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      proteinGoalGrams: proteinGoalGrams ?? this.proteinGoalGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatsGrams: fatsGrams ?? this.fatsGrams,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      totalReps: totalReps ?? this.totalReps,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'steps': steps,
    'stepsGoal': stepsGoal,
    'activeMinutes': activeMinutes,
    'activeMinutesGoal': activeMinutesGoal,
    'caloriesBurned': caloriesBurned,
    'caloriesBurnedGoal': caloriesBurnedGoal,
    'waterMl': waterMl,
    'waterGoalMl': waterGoalMl,
    'caloriesConsumed': caloriesConsumed,
    'caloriesConsumedGoal': caloriesConsumedGoal,
    'proteinGrams': proteinGrams,
    'proteinGoalGrams': proteinGoalGrams,
    'carbsGrams': carbsGrams,
    'fatsGrams': fatsGrams,
    'mealsLogged': mealsLogged,
    'workoutsCompleted': workoutsCompleted,
    'workoutMinutes': workoutMinutes,
    'totalReps': totalReps,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] as String,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      stepsGoal: (json['stepsGoal'] as num?)?.toInt() ?? 10000,
      activeMinutes: (json['activeMinutes'] as num?)?.toInt() ?? 0,
      activeMinutesGoal: (json['activeMinutesGoal'] as num?)?.toInt() ?? 45,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      caloriesBurnedGoal: (json['caloriesBurnedGoal'] as num?)?.toInt() ?? 650,
      waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
      waterGoalMl: (json['waterGoalMl'] as num?)?.toInt() ?? 3000,
      caloriesConsumed: (json['caloriesConsumed'] as num?)?.toDouble() ?? 0.0,
      caloriesConsumedGoal:
          (json['caloriesConsumedGoal'] as num?)?.toDouble() ?? 2100.0,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 0.0,
      proteinGoalGrams: (json['proteinGoalGrams'] as num?)?.toDouble() ?? 110.0,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ?? 0.0,
      fatsGrams: (json['fatsGrams'] as num?)?.toDouble() ?? 0.0,
      mealsLogged: (json['mealsLogged'] as num?)?.toInt() ?? 0,
      workoutsCompleted: (json['workoutsCompleted'] as num?)?.toInt() ?? 0,
      workoutMinutes: (json['workoutMinutes'] as num?)?.toInt() ?? 0,
      totalReps: (json['totalReps'] as num?)?.toInt() ?? 0,
    );
  }
}
