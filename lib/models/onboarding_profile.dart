class OnboardingProfile {
  final String name;
  final String college;
  final String campus;
  final String goal;
  final String workoutLocation;
  final List<String> equipment;
  final int age;
  final double heightCm;
  final double weightKg;
  final String fitnessLevel;
  final String dietaryPreference;
  final String foodBudget;
  final List<String> motivations;
  final String journeyPreference;
  final bool isCompleted;
  final DateTime? completedAt;

  const OnboardingProfile({
    this.name = '',
    this.college = '',
    this.campus = '',
    this.goal = 'Stay Fit',
    this.workoutLocation = 'Home',
    this.equipment = const ['Bodyweight'],
    this.age = 20,
    this.heightCm = 172.0,
    this.weightKg = 65.0,
    this.fitnessLevel = 'Beginner',
    this.dietaryPreference = 'Vegetarian',
    this.foodBudget = 'Budget Friendly',
    this.motivations = const ['Streaks', 'Progress'],
    this.journeyPreference = 'Campus Champion',
    this.isCompleted = false,
    this.completedAt,
  });

  double get bmi {
    if (heightCm <= 0) return 0.0;
    final heightMeters = heightCm / 100.0;
    return weightKg / (heightMeters * heightMeters);
  }

  String get bmiCategory {
    final value = bmi;
    if (value < 18.5) return 'Underweight';
    if (value < 25.0) return 'Normal weight';
    if (value < 30.0) return 'Overweight';
    return 'Obese';
  }

  OnboardingProfile copyWith({
    String? name,
    String? college,
    String? campus,
    String? goal,
    String? workoutLocation,
    List<String>? equipment,
    int? age,
    double? heightCm,
    double? weightKg,
    String? fitnessLevel,
    String? dietaryPreference,
    String? foodBudget,
    List<String>? motivations,
    String? journeyPreference,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return OnboardingProfile(
      name: name ?? this.name,
      college: college ?? this.college,
      campus: campus ?? this.campus,
      goal: goal ?? this.goal,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      equipment: equipment ?? this.equipment,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      foodBudget: foodBudget ?? this.foodBudget,
      motivations: motivations ?? this.motivations,
      journeyPreference: journeyPreference ?? this.journeyPreference,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'college': college,
      'campus': campus,
      'goal': goal,
      'workoutLocation': workoutLocation,
      'equipment': equipment,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'fitnessLevel': fitnessLevel,
      'dietaryPreference': dietaryPreference,
      'foodBudget': foodBudget,
      'motivations': motivations,
      'journeyPreference': journeyPreference,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      name: json['name'] as String? ?? '',
      college: json['college'] as String? ?? '',
      campus: json['campus'] as String? ?? '',
      goal: json['goal'] as String? ?? 'Stay Fit',
      workoutLocation: json['workoutLocation'] as String? ?? 'Home',
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Bodyweight'],
      age: (json['age'] as num?)?.toInt() ?? 20,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 172.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 65.0,
      fitnessLevel: json['fitnessLevel'] as String? ?? 'Beginner',
      dietaryPreference: json['dietaryPreference'] as String? ?? 'Vegetarian',
      foodBudget: json['foodBudget'] as String? ?? 'Budget Friendly',
      motivations:
          (json['motivations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Streaks'],
      journeyPreference:
          json['journeyPreference'] as String? ?? 'Campus Champion',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
