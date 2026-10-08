/// Immutable data model representing personalized daily targets for a GenFit user.
///
/// Contains safety-bounded goals for activity, hydration, energy expenditure,
/// and nutrition.
class PersonalizedGoals {
  final int stepsGoal;
  final int waterGoalMl;
  final int caloriesBurnedGoal;
  final int activeMinutesGoal;
  final double caloriesConsumedGoal;
  final double proteinGoalGrams;

  const PersonalizedGoals({
    required this.stepsGoal,
    required this.waterGoalMl,
    required this.caloriesBurnedGoal,
    required this.activeMinutesGoal,
    required this.caloriesConsumedGoal,
    required this.proteinGoalGrams,
  });

  /// Standard fallback goals matching project defaults.
  static const PersonalizedGoals defaultGoals = PersonalizedGoals(
    stepsGoal: 10000,
    waterGoalMl: 3000,
    caloriesBurnedGoal: 650,
    activeMinutesGoal: 45,
    caloriesConsumedGoal: 2100.0,
    proteinGoalGrams: 110.0,
  );

  PersonalizedGoals copyWith({
    int? stepsGoal,
    int? waterGoalMl,
    int? caloriesBurnedGoal,
    int? activeMinutesGoal,
    double? caloriesConsumedGoal,
    double? proteinGoalGrams,
  }) {
    return PersonalizedGoals(
      stepsGoal: stepsGoal ?? this.stepsGoal,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      caloriesBurnedGoal: caloriesBurnedGoal ?? this.caloriesBurnedGoal,
      activeMinutesGoal: activeMinutesGoal ?? this.activeMinutesGoal,
      caloriesConsumedGoal: caloriesConsumedGoal ?? this.caloriesConsumedGoal,
      proteinGoalGrams: proteinGoalGrams ?? this.proteinGoalGrams,
    );
  }

  Map<String, dynamic> toJson() => {
    'stepsGoal': stepsGoal,
    'waterGoalMl': waterGoalMl,
    'caloriesBurnedGoal': caloriesBurnedGoal,
    'activeMinutesGoal': activeMinutesGoal,
    'caloriesConsumedGoal': caloriesConsumedGoal,
    'proteinGoalGrams': proteinGoalGrams,
  };

  factory PersonalizedGoals.fromJson(Map<String, dynamic> json) =>
      PersonalizedGoals(
        stepsGoal:
            (json['stepsGoal'] as num?)?.toInt() ?? defaultGoals.stepsGoal,
        waterGoalMl:
            (json['waterGoalMl'] as num?)?.toInt() ?? defaultGoals.waterGoalMl,
        caloriesBurnedGoal:
            (json['caloriesBurnedGoal'] as num?)?.toInt() ??
            defaultGoals.caloriesBurnedGoal,
        activeMinutesGoal:
            (json['activeMinutesGoal'] as num?)?.toInt() ??
            defaultGoals.activeMinutesGoal,
        caloriesConsumedGoal:
            (json['caloriesConsumedGoal'] as num?)?.toDouble() ??
            defaultGoals.caloriesConsumedGoal,
        proteinGoalGrams:
            (json['proteinGoalGrams'] as num?)?.toDouble() ??
            defaultGoals.proteinGoalGrams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedGoals &&
          runtimeType == other.runtimeType &&
          stepsGoal == other.stepsGoal &&
          waterGoalMl == other.waterGoalMl &&
          caloriesBurnedGoal == other.caloriesBurnedGoal &&
          activeMinutesGoal == other.activeMinutesGoal &&
          caloriesConsumedGoal == other.caloriesConsumedGoal &&
          proteinGoalGrams == other.proteinGoalGrams;

  @override
  int get hashCode => Object.hash(
    stepsGoal,
    waterGoalMl,
    caloriesBurnedGoal,
    activeMinutesGoal,
    caloriesConsumedGoal,
    proteinGoalGrams,
  );

  @override
  String toString() =>
      'PersonalizedGoals(steps: $stepsGoal, water: ${waterGoalMl}ml, burned: ${caloriesBurnedGoal}kcal, active: ${activeMinutesGoal}min, consumed: ${caloriesConsumedGoal.toStringAsFixed(0)}kcal, protein: ${proteinGoalGrams.toStringAsFixed(0)}g)';
}
