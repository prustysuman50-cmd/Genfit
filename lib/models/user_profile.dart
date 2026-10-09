import 'onboarding_profile.dart';

class UserProfile {
  final String id;
  final String name;
  final String college;
  final String campus;
  final String hostel;
  final String avatarInitials;
  final int streakDays;
  final int xp;
  final int level;
  final String levelTitle;
  final int nextLevelXp;
  final double? customLevelProgress;

  // Personal & physical attributes
  final int age;
  final double heightCm;
  final double weightKg;

  // Fitness & lifestyle preferences
  final String fitnessGoal;
  final String fitnessLevel;
  final String dietPreference;
  final String budgetPreference;
  final String workoutLocation;
  final List<String> equipment;
  final List<String> motivations;
  final String journeyPreference;

  // Profile completion status
  final bool isCompleted;
  final DateTime? completedAt;

  const UserProfile({
    this.id = 'user_01',
    this.name = 'Ayush',
    this.college = 'ITER • Bhubaneswar Campus',
    this.campus = 'Bhubaneswar Campus',
    this.hostel = 'Mahanadi Hostel',
    this.avatarInitials = 'AK',
    this.streakDays = 7,
    this.xp = 3850,
    this.level = 4,
    this.levelTitle = 'Campus Warrior',
    this.nextLevelXp = 5000,
    this.customLevelProgress,
    this.age = 20,
    this.heightCm = 172.0,
    this.weightKg = 65.0,
    this.fitnessGoal = 'Stay Fit',
    this.fitnessLevel = 'Beginner',
    this.dietPreference = 'Vegetarian',
    this.budgetPreference = 'Budget Friendly',
    this.workoutLocation = 'Home',
    this.equipment = const ['Bodyweight'],
    this.motivations = const ['Streaks', 'Progress'],
    this.journeyPreference = 'Campus Champion',
    this.isCompleted = false,
    this.completedAt,
  });

  static const UserProfile defaultUser = UserProfile();

  double get levelProgress => customLevelProgress ?? ((xp % 1000) / 1000.0);
  int get currentLevelBaseXp => (level - 1) * 1000;
  int get xpInCurrentLevel => xp - currentLevelBaseXp;
  int get xpNeededForNextLevel => nextLevelXp - xp;

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

  static String computeInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'GF';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? college,
    String? campus,
    String? hostel,
    String? avatarInitials,
    int? streakDays,
    int? xp,
    int? level,
    String? levelTitle,
    int? nextLevelXp,
    double? customLevelProgress,
    int? age,
    double? heightCm,
    double? weightKg,
    String? fitnessGoal,
    String? fitnessLevel,
    String? dietPreference,
    String? budgetPreference,
    String? workoutLocation,
    List<String>? equipment,
    List<String>? motivations,
    String? journeyPreference,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      college: college ?? this.college,
      campus: campus ?? this.campus,
      hostel: hostel ?? this.hostel,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      streakDays: streakDays ?? this.streakDays,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      customLevelProgress: customLevelProgress ?? this.customLevelProgress,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietPreference: dietPreference ?? this.dietPreference,
      budgetPreference: budgetPreference ?? this.budgetPreference,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      equipment: equipment ?? this.equipment,
      motivations: motivations ?? this.motivations,
      journeyPreference: journeyPreference ?? this.journeyPreference,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory UserProfile.fromOnboarding(
    OnboardingProfile onboarding, {
    UserProfile? base,
  }) {
    final current = base ?? defaultUser;
    final userName = onboarding.name.trim().isNotEmpty
        ? onboarding.name.trim()
        : current.name;
    final userCollege = onboarding.college.trim().isNotEmpty
        ? onboarding.college.trim()
        : current.college;
    final userCampus = onboarding.campus.trim().isNotEmpty
        ? onboarding.campus.trim()
        : current.campus;
    final initials = UserProfile.computeInitials(userName);

    return current.copyWith(
      name: userName,
      college: userCollege,
      campus: userCampus,
      avatarInitials: initials,
      fitnessGoal: onboarding.goal,
      workoutLocation: onboarding.workoutLocation,
      equipment: onboarding.equipment,
      age: onboarding.age,
      heightCm: onboarding.heightCm,
      weightKg: onboarding.weightKg,
      fitnessLevel: onboarding.fitnessLevel,
      dietPreference: onboarding.dietaryPreference,
      budgetPreference: onboarding.foodBudget,
      motivations: onboarding.motivations,
      journeyPreference: onboarding.journeyPreference,
      isCompleted: onboarding.isCompleted,
      completedAt: onboarding.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'college': college,
      'campus': campus,
      'hostel': hostel,
      'avatarInitials': avatarInitials,
      'streakDays': streakDays,
      'xp': xp,
      'level': level,
      'levelTitle': levelTitle,
      'nextLevelXp': nextLevelXp,
      'customLevelProgress': customLevelProgress,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'fitnessGoal': fitnessGoal,
      'fitnessLevel': fitnessLevel,
      'dietPreference': dietPreference,
      'budgetPreference': budgetPreference,
      'workoutLocation': workoutLocation,
      'equipment': equipment,
      'motivations': motivations,
      'journeyPreference': journeyPreference,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Ayush';
    final initials = json['avatarInitials'] as String? ?? computeInitials(name);

    return UserProfile(
      id: json['id'] as String? ?? 'user_01',
      name: name,
      college: json['college'] as String? ?? 'ITER • Bhubaneswar Campus',
      campus: json['campus'] as String? ?? 'Bhubaneswar Campus',
      hostel: json['hostel'] as String? ?? 'Mahanadi Hostel',
      avatarInitials: initials,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 7,
      xp: (json['xp'] as num?)?.toInt() ?? 3850,
      level: (json['level'] as num?)?.toInt() ?? 4,
      levelTitle: json['levelTitle'] as String? ?? 'Campus Warrior',
      nextLevelXp: (json['nextLevelXp'] as num?)?.toInt() ?? 5000,
      customLevelProgress: (json['customLevelProgress'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt() ?? 20,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 172.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 65.0,
      fitnessGoal: json['fitnessGoal'] as String? ?? 'Stay Fit',
      fitnessLevel: json['fitnessLevel'] as String? ?? 'Beginner',
      dietPreference:
          json['dietPreference'] as String? ??
          json['dietaryPreference'] as String? ??
          'Vegetarian',
      budgetPreference:
          json['budgetPreference'] as String? ??
          json['foodBudget'] as String? ??
          'Budget Friendly',
      workoutLocation: json['workoutLocation'] as String? ?? 'Home',
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Bodyweight'],
      motivations:
          (json['motivations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Streaks', 'Progress'],
      journeyPreference:
          json['journeyPreference'] as String? ?? 'Campus Champion',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
