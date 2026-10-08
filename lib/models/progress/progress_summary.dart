/// Represents an activity summary for a single day of the week (e.g. Mon, Tue).
class DailyActivitySummary {
  final String dayLabel; // 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  final String dayName; // 'Monday', 'Tuesday', ...
  final int workouts;
  final int steps;
  final int activeMinutes;
  final int calories;
  final int waterMl;
  final bool isToday;

  const DailyActivitySummary({
    required this.dayLabel,
    required this.dayName,
    this.workouts = 0,
    this.steps = 0,
    this.activeMinutes = 0,
    this.calories = 0,
    this.waterMl = 0,
    this.isToday = false,
  });

  Map<String, dynamic> toJson() => {
    'dayLabel': dayLabel,
    'dayName': dayName,
    'workouts': workouts,
    'steps': steps,
    'activeMinutes': activeMinutes,
    'calories': calories,
    'waterMl': waterMl,
    'isToday': isToday,
  };

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) =>
      DailyActivitySummary(
        dayLabel: json['dayLabel'] as String? ?? 'Mon',
        dayName: json['dayName'] as String? ?? 'Monday',
        workouts: (json['workouts'] as num?)?.toInt() ?? 0,
        steps: (json['steps'] as num?)?.toInt() ?? 0,
        activeMinutes: (json['activeMinutes'] as num?)?.toInt() ?? 0,
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
        isToday: json['isToday'] as bool? ?? false,
      );

  DailyActivitySummary copyWith({
    String? dayLabel,
    String? dayName,
    int? workouts,
    int? steps,
    int? activeMinutes,
    int? calories,
    int? waterMl,
    bool? isToday,
  }) {
    return DailyActivitySummary(
      dayLabel: dayLabel ?? this.dayLabel,
      dayName: dayName ?? this.dayName,
      workouts: workouts ?? this.workouts,
      steps: steps ?? this.steps,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      calories: calories ?? this.calories,
      waterMl: waterMl ?? this.waterMl,
      isToday: isToday ?? this.isToday,
    );
  }
}

/// Comprehensive progress summary aggregating fitness, nutrition, gamification, and journey data.
class ProgressSummary {
  final int workoutsCompleted;
  final int totalReps;
  final int steps;
  final int activeCalories;
  final int activeMinutes;
  final int waterMl;
  final int currentStreak;
  final int xp;
  final int level;
  final String levelTitle;
  final int nutritionMealsLogged;
  final double journeyProgressKm;
  final double journeyCompletionPercent;
  final int badgesUnlocked;
  final int totalBadges;
  final List<DailyActivitySummary> weeklyActivity;

  const ProgressSummary({
    this.workoutsCompleted = 0,
    this.totalReps = 0,
    this.steps = 0,
    this.activeCalories = 0,
    this.activeMinutes = 0,
    this.waterMl = 0,
    this.currentStreak = 0,
    this.xp = 0,
    this.level = 1,
    this.levelTitle = 'Campus Rookie',
    this.nutritionMealsLogged = 0,
    this.journeyProgressKm = 0.0,
    this.journeyCompletionPercent = 0.0,
    this.badgesUnlocked = 0,
    this.totalBadges = 7,
    this.weeklyActivity = const [],
  });

  Map<String, dynamic> toJson() => {
    'workoutsCompleted': workoutsCompleted,
    'totalReps': totalReps,
    'steps': steps,
    'activeCalories': activeCalories,
    'activeMinutes': activeMinutes,
    'waterMl': waterMl,
    'currentStreak': currentStreak,
    'xp': xp,
    'level': level,
    'levelTitle': levelTitle,
    'nutritionMealsLogged': nutritionMealsLogged,
    'journeyProgressKm': journeyProgressKm,
    'journeyCompletionPercent': journeyCompletionPercent,
    'badgesUnlocked': badgesUnlocked,
    'totalBadges': totalBadges,
    'weeklyActivity': weeklyActivity.map((a) => a.toJson()).toList(),
  };

  factory ProgressSummary.fromJson(
    Map<String, dynamic> json,
  ) => ProgressSummary(
    workoutsCompleted: (json['workoutsCompleted'] as num?)?.toInt() ?? 0,
    totalReps: (json['totalReps'] as num?)?.toInt() ?? 0,
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    activeCalories: (json['activeCalories'] as num?)?.toInt() ?? 0,
    activeMinutes: (json['activeMinutes'] as num?)?.toInt() ?? 0,
    waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
    currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    level: (json['level'] as num?)?.toInt() ?? 1,
    levelTitle: json['levelTitle'] as String? ?? 'Campus Rookie',
    nutritionMealsLogged: (json['nutritionMealsLogged'] as num?)?.toInt() ?? 0,
    journeyProgressKm: (json['journeyProgressKm'] as num?)?.toDouble() ?? 0.0,
    journeyCompletionPercent:
        (json['journeyCompletionPercent'] as num?)?.toDouble() ?? 0.0,
    badgesUnlocked: (json['badgesUnlocked'] as num?)?.toInt() ?? 0,
    totalBadges: (json['totalBadges'] as num?)?.toInt() ?? 7,
    weeklyActivity:
        (json['weeklyActivity'] as List<dynamic>?)
            ?.map(
              (a) => DailyActivitySummary.fromJson(a as Map<String, dynamic>),
            )
            .toList() ??
        const [],
  );

  ProgressSummary copyWith({
    int? workoutsCompleted,
    int? totalReps,
    int? steps,
    int? activeCalories,
    int? activeMinutes,
    int? waterMl,
    int? currentStreak,
    int? xp,
    int? level,
    String? levelTitle,
    int? nutritionMealsLogged,
    double? journeyProgressKm,
    double? journeyCompletionPercent,
    int? badgesUnlocked,
    int? totalBadges,
    List<DailyActivitySummary>? weeklyActivity,
  }) {
    return ProgressSummary(
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      totalReps: totalReps ?? this.totalReps,
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      waterMl: waterMl ?? this.waterMl,
      currentStreak: currentStreak ?? this.currentStreak,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      nutritionMealsLogged: nutritionMealsLogged ?? this.nutritionMealsLogged,
      journeyProgressKm: journeyProgressKm ?? this.journeyProgressKm,
      journeyCompletionPercent:
          journeyCompletionPercent ?? this.journeyCompletionPercent,
      badgesUnlocked: badgesUnlocked ?? this.badgesUnlocked,
      totalBadges: totalBadges ?? this.totalBadges,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
    );
  }
}
