/// Supported fitness difficulty levels in GenFit.
enum WorkoutDifficultyLevel {
  beginner('Beginner', '8–12 reps', 15, 150),
  intermediate('Intermediate', '12–16 reps', 20, 220),
  advanced('Advanced', '18–25 reps', 28, 310);

  final String displayName;
  final String targetRepsRange;
  final int defaultDurationMinutes;
  final int defaultCalories;

  const WorkoutDifficultyLevel(
    this.displayName,
    this.targetRepsRange,
    this.defaultDurationMinutes,
    this.defaultCalories,
  );

  /// Safely parses a string value (case-insensitive) to a [WorkoutDifficultyLevel],
  /// defaulting to [WorkoutDifficultyLevel.beginner] if unknown or null.
  static WorkoutDifficultyLevel fromString(String? value) {
    if (value == null) return WorkoutDifficultyLevel.beginner;
    final lower = value.trim().toLowerCase();
    for (final level in WorkoutDifficultyLevel.values) {
      if (level.name == lower || level.displayName.toLowerCase() == lower) {
        return level;
      }
    }
    return WorkoutDifficultyLevel.beginner;
  }
}

/// The status of adaptive progression evaluation.
enum ProgressionStatus {
  /// Insufficient history; relying strictly on user profile baseline.
  baseline,

  /// Maintaining current level as volume/performance targets are sustained.
  maintained,

  /// Earned progression to a higher difficulty tier based on verified volume.
  promoted,

  /// Conservative deload or ramp-up for unverified claims or long inactivity.
  safeRampUp,
}

/// Structured, explainable recommendation produced by [AdaptiveDifficultyService].
class AdaptiveDifficultyRecommendation {
  /// The recommended difficulty tier.
  final WorkoutDifficultyLevel recommendedLevel;

  /// The user's active baseline level.
  final WorkoutDifficultyLevel currentLevel;

  /// The outcome status of this evaluation.
  final ProgressionStatus status;

  /// Human-readable explanation of the deterministic decision.
  final String explanation;

  /// Real verified count of completed workouts used for evaluation.
  final int completedWorkoutsCount;

  /// Real verified count of exercise repetitions completed.
  final int totalRepsCompleted;

  /// Active streak days.
  final int streakDays;

  /// Whether sufficient historical data was present to progress beyond baseline.
  final bool hasSufficientHistory;

  /// Timestamp when this evaluation was calculated.
  final DateTime evaluatedAt;

  const AdaptiveDifficultyRecommendation({
    required this.recommendedLevel,
    required this.currentLevel,
    required this.status,
    required this.explanation,
    required this.completedWorkoutsCount,
    required this.totalRepsCompleted,
    required this.streakDays,
    required this.hasSufficientHistory,
    required this.evaluatedAt,
  });

  /// Whether the recommended level represents a higher difficulty than current.
  bool get isPromotion =>
      recommendedLevel.index > currentLevel.index;

  /// Whether the recommended level differs from current active level.
  bool get differsFromCurrent =>
      recommendedLevel != currentLevel;

  Map<String, dynamic> toJson() => {
    'recommendedLevel': recommendedLevel.displayName,
    'currentLevel': currentLevel.displayName,
    'status': status.name,
    'explanation': explanation,
    'completedWorkoutsCount': completedWorkoutsCount,
    'totalRepsCompleted': totalRepsCompleted,
    'streakDays': streakDays,
    'hasSufficientHistory': hasSufficientHistory,
    'evaluatedAt': evaluatedAt.toIso8601String(),
  };

  factory AdaptiveDifficultyRecommendation.fromJson(Map<String, dynamic> json) {
    return AdaptiveDifficultyRecommendation(
      recommendedLevel: WorkoutDifficultyLevel.fromString(
        json['recommendedLevel'] as String?,
      ),
      currentLevel: WorkoutDifficultyLevel.fromString(
        json['currentLevel'] as String?,
      ),
      status: ProgressionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ProgressionStatus.baseline,
      ),
      explanation: json['explanation'] as String? ?? '',
      completedWorkoutsCount: json['completedWorkoutsCount'] as int? ?? 0,
      totalRepsCompleted: json['totalRepsCompleted'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      hasSufficientHistory: json['hasSufficientHistory'] as bool? ?? false,
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.tryParse(json['evaluatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
