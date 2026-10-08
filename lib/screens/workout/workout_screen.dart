import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/exercise.dart';
import 'widgets/ai_workout_hero_card.dart';
import 'widgets/exercise_card.dart';
import 'widgets/todays_workout_section.dart';
import 'widgets/workout_categories_bar.dart';
import 'workout_session_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String _selectedCategory = 'All';

  void _openWorkoutSession([Exercise? exercise]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(initialExercise: exercise),
      ),
    );
  }

  List<Exercise> get _filteredExercises {
    if (_selectedCategory == 'All') {
      return Exercise.sampleExercises;
    }
    return Exercise.sampleExercises
        .where(
          (e) => e.category.toLowerCase() == _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredExercises;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Workouts & AI Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              _showAiInfoDialog(context);
            },
            tooltip: 'About AI Vision',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. AI Workout Hero Card with Header, Subtitle, and "Start AI Workout" Button
            AiWorkoutHeroCard(onStartAiWorkout: () => _openWorkoutSession()),
            const SizedBox(height: 24),

            // 2. Today's Workout Section with a sample workout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Workout",
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI Recommended',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TodaysWorkoutSection(onStartWorkout: () => _openWorkoutSession()),
            const SizedBox(height: 26),

            // 3. Exercise Library & Category Filter
            Text(
              'AI Exercise Library',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select an exercise to start a dedicated form-check session.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),

            // Categories Bar: Strength, Core, Full Body, Mobility, Cardio
            WorkoutCategoriesBar(
              categories: Exercise.categories,
              selectedCategory: _selectedCategory,
              onSelectCategory: (cat) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
            const SizedBox(height: 14),

            // 4. Exercise Cards: Squats, Push-ups, Lunges, Jumping Jacks, Plank
            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.fitness_center_outlined,
                      color: AppColors.textMutedDark,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No exercises found for $_selectedCategory',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                      child: const Text('View All Exercises'),
                    ),
                  ],
                ),
              )
            else
              ...filteredList.map((exercise) {
                return ExerciseCard(
                  exercise: exercise,
                  onStart: () => _openWorkoutSession(exercise),
                );
              }),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  void _showAiInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorderDark),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'AI Vision Coach',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          content: const Text(
            'GenFit is engineered to track physical activity without any wearable hardware. In the upcoming release, your phone camera will detect 17 skeletal keypoints using on-device ML Kit MoveNet models. Zero video leaves your device.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Got It',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
