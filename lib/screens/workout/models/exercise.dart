import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String name;
  final String
  category; // 'Strength', 'Core', 'Full Body', 'Mobility', 'Cardio'
  final String targetMuscles;
  final int defaultReps;
  final int defaultDurationSeconds;
  final bool isTimed;
  final String difficulty;
  final String formHint;
  final IconData icon;
  final String description;
  final int estimatedCalories;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.targetMuscles,
    this.defaultReps = 15,
    this.defaultDurationSeconds = 45,
    this.isTimed = false,
    required this.difficulty,
    required this.formHint,
    required this.icon,
    required this.description,
    this.estimatedCalories = 35,
  });

  static const List<String> categories = [
    'All',
    'Strength',
    'Core',
    'Full Body',
    'Mobility',
    'Cardio',
  ];

  static const List<Exercise> sampleExercises = [
    Exercise(
      id: 'ex_squats',
      name: 'Squats',
      category: 'Strength',
      targetMuscles: 'Quadriceps, Glutes, Hamstrings',
      defaultReps: 15,
      difficulty: 'Beginner',
      formHint: 'Keep knees behind toes & chest upright',
      icon: Icons.accessibility_new_rounded,
      description: 'Fundamental lower body compound exercise. Builds leg strength and hip mobility.',
      estimatedCalories: 45,
    ),
    Exercise(
      id: 'ex_pushups',
      name: 'Push-ups',
      category: 'Strength',
      targetMuscles: 'Chest, Triceps, Anterior Deltoids',
      defaultReps: 12,
      difficulty: 'Intermediate',
      formHint: 'Maintain a straight plank line and tuck elbows at 45°',
      icon: Icons.fitness_center_rounded,
      description: 'Upper body pushing staple. Strengthens chest, shoulders, and core stability.',
      estimatedCalories: 40,
    ),
    Exercise(
      id: 'ex_lunges',
      name: 'Lunges',
      category: 'Strength',
      targetMuscles: 'Glutes, Quads, Calves',
      defaultReps: 12,
      difficulty: 'Intermediate',
      formHint: 'Step forward keeping front knee over ankle at 90°',
      icon: Icons.directions_walk_rounded,
      description: 'Unilateral leg builder that improves balance, stability, and lower body power.',
      estimatedCalories: 38,
    ),
    Exercise(
      id: 'ex_jumping_jacks',
      name: 'Jumping Jacks',
      category: 'Cardio',
      targetMuscles: 'Full Body, Calves, Deltoids',
      defaultReps: 30,
      isTimed: true,
      defaultDurationSeconds: 45,
      difficulty: 'Beginner',
      formHint: 'Land softly on the balls of your feet and keep core engaged',
      icon: Icons.flash_on_rounded,
      description: 'High-energy cardiovascular movement to rapidly boost heart rate and calorie burn in small rooms.',
      estimatedCalories: 50,
    ),
    Exercise(
      id: 'ex_plank',
      name: 'Plank',
      category: 'Core',
      targetMuscles: 'Transverse Abdominis, Lower Back, Obliques',
      defaultReps: 1,
      isTimed: true,
      defaultDurationSeconds: 60,
      difficulty: 'Intermediate',
      formHint: 'Lock glutes, brace stomach, and keep neutral neck alignment',
      icon: Icons.horizontal_rule_rounded,
      description: 'Isometric core stability anchor. Builds endurance throughout the entire posterior and anterior chain.',
      estimatedCalories: 30,
    ),
  ];
}
