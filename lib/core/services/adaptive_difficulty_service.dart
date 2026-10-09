import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/workout.dart';
import '../../models/workout/adaptive_difficulty.dart';
import 'daily_stats_service.dart';
import 'gamification_service.dart';
import 'user_service.dart';

/// Central service providing deterministic, explainable adaptive workout difficulty recommendations.
///
/// Features:
/// - Reuses real verified telemetry from [DailyStatsService], [GamificationService], and [UserService].
/// - Evaluates conservative progression rules (Beginner -> Intermediate -> Advanced).
/// - Enforces safe fallbacks and insufficient-history protection (< 3 workouts).
/// - Persists user overrides and active state following GenFit's local JSON conventions.
class AdaptiveDifficultyService extends ChangeNotifier {
  AdaptiveDifficultyService._() {
    _attachListeners();
  }

  static final AdaptiveDifficultyService instance =
      AdaptiveDifficultyService._();

  static const String _fileName = 'genfit_adaptive_difficulty.json';

  String? _customStoragePath;
  bool _isInitialized = false;
  WorkoutDifficultyLevel? _userPreferredLevel;

  UserService _userService = UserService.instance;
  DailyStatsService _dailyStatsService = DailyStatsService.instance;
  GamificationService _gamificationService = GamificationService.instance;

  bool get isInitialized => _isInitialized;
  WorkoutDifficultyLevel? get userPreferredLevel => _userPreferredLevel;

  /// Constructor for testing with dependency injection.
  AdaptiveDifficultyService.forTesting({
    required this._userService,
    required this._dailyStatsService,
    required this._gamificationService,
    this._customStoragePath,
  }) {
    _attachListeners();
  }

  void _attachListeners() {
    _userService.addListener(_onDependenciesUpdated);
    _dailyStatsService.addListener(_onDependenciesUpdated);
    _gamificationService.addListener(_onDependenciesUpdated);
  }

  void _onDependenciesUpdated() {
    notifyListeners();
  }

  /// Sets custom directory for unit test storage isolation.
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  /// Initializes storage and loads persisted user overrides.
  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> json = jsonDecode(content);
          if (json.containsKey('userPreferredLevel')) {
            _userPreferredLevel = WorkoutDifficultyLevel.fromString(
              json['userPreferredLevel'] as String?,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AdaptiveDifficultyService.init error: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Evaluates deterministic, explainable difficulty recommendations based on real user activity.
  AdaptiveDifficultyRecommendation evaluateRecommendation() {
    final user = _userService.currentUser;
    final currentLevel = _userPreferredLevel ??
        WorkoutDifficultyLevel.fromString(user.fitnessLevel);

    // Compute verified completed workouts and reps from DailyStats and Gamification
    int statsWorkouts = 0;
    int statsReps = 0;
    for (final record in _dailyStatsService.allRecords.values) {
      statsWorkouts += record.workoutsCompleted;
      statsReps += record.totalReps;
    }

    final totalWorkouts = statsWorkouts > _gamificationService.totalWorkoutsCompleted
        ? statsWorkouts
        : _gamificationService.totalWorkoutsCompleted;
    final totalReps = statsReps > _gamificationService.totalReps
        ? statsReps
        : _gamificationService.totalReps;
    final streakDays = _gamificationService.streakDays;

    final now = DateTime.now();

    // -------------------------------------------------------------
    // RULE 1: Insufficient History (< 3 completed workouts)
    // -------------------------------------------------------------
    if (totalWorkouts < 3) {
      // Safe ramp-up: if user selected Advanced with zero history, recommend Intermediate first
      if (currentLevel == WorkoutDifficultyLevel.advanced && totalWorkouts == 0) {
        return AdaptiveDifficultyRecommendation(
          recommendedLevel: WorkoutDifficultyLevel.intermediate,
          currentLevel: currentLevel,
          status: ProgressionStatus.safeRampUp,
          explanation:
              'Safe Ramp-Up: Your profile states Advanced, but without recent workout logs, Intermediate is recommended to build volume safely.',
          completedWorkoutsCount: totalWorkouts,
          totalRepsCompleted: totalReps,
          streakDays: streakDays,
          hasSufficientHistory: false,
          evaluatedAt: now,
        );
      }

      final String explanation = totalWorkouts == 0
          ? 'Profile baseline: ${currentLevel.displayName}. Complete at least 3 workouts to unlock personalized adaptive progression.'
          : 'Building consistency: $totalWorkouts/3 completed sessions ($totalReps reps). Complete at least 3 workouts to evaluate progression.';

      return AdaptiveDifficultyRecommendation(
        recommendedLevel: currentLevel,
        currentLevel: currentLevel,
        status: ProgressionStatus.baseline,
        explanation: explanation,
        completedWorkoutsCount: totalWorkouts,
        totalRepsCompleted: totalReps,
        streakDays: streakDays,
        hasSufficientHistory: false,
        evaluatedAt: now,
      );
    }

    // -------------------------------------------------------------
    // RULE 2: Sufficient History (>= 3 workouts) - Conservative Progression
    // -------------------------------------------------------------

    // Case A: User is currently Beginner
    if (currentLevel == WorkoutDifficultyLevel.beginner) {
      // Promotion to Intermediate requires 4+ workouts and 60+ reps
      if (totalWorkouts >= 4 && totalReps >= 60) {
        return AdaptiveDifficultyRecommendation(
          recommendedLevel: WorkoutDifficultyLevel.intermediate,
          currentLevel: currentLevel,
          status: ProgressionStatus.promoted,
          explanation:
              'Ready for promotion: Completed $totalWorkouts workouts with $totalReps total reps. Moving up to Intermediate intensity.',
          completedWorkoutsCount: totalWorkouts,
          totalRepsCompleted: totalReps,
          streakDays: streakDays,
          hasSufficientHistory: true,
          evaluatedAt: now,
        );
      }
      return AdaptiveDifficultyRecommendation(
        recommendedLevel: WorkoutDifficultyLevel.beginner,
        currentLevel: currentLevel,
        status: ProgressionStatus.maintained,
        explanation:
            'Maintaining Beginner: Completed $totalWorkouts workouts ($totalReps reps). Intermediate unlocks at 4 workouts & 60 reps.',
        completedWorkoutsCount: totalWorkouts,
        totalRepsCompleted: totalReps,
        streakDays: streakDays,
        hasSufficientHistory: true,
        evaluatedAt: now,
      );
    }

    // Case B: User is currently Intermediate
    if (currentLevel == WorkoutDifficultyLevel.intermediate) {
      // Promotion to Advanced requires 8+ workouts, 150+ reps, and streak >= 4
      if (totalWorkouts >= 8 && totalReps >= 150 && streakDays >= 4) {
        return AdaptiveDifficultyRecommendation(
          recommendedLevel: WorkoutDifficultyLevel.advanced,
          currentLevel: currentLevel,
          status: ProgressionStatus.promoted,
          explanation:
              'Outstanding volume: Completed $totalWorkouts workouts ($totalReps reps) with a $streakDays-day streak. Ready for Advanced intensity.',
          completedWorkoutsCount: totalWorkouts,
          totalRepsCompleted: totalReps,
          streakDays: streakDays,
          hasSufficientHistory: true,
          evaluatedAt: now,
        );
      }
      return AdaptiveDifficultyRecommendation(
        recommendedLevel: WorkoutDifficultyLevel.intermediate,
        currentLevel: currentLevel,
        status: ProgressionStatus.maintained,
        explanation:
            'Maintaining Intermediate: Consistent training ($totalWorkouts workouts, $totalReps reps). Advanced unlocks at 8 workouts & 150 reps.',
        completedWorkoutsCount: totalWorkouts,
        totalRepsCompleted: totalReps,
        streakDays: streakDays,
        hasSufficientHistory: true,
        evaluatedAt: now,
      );
    }

    // Case C: User is currently Advanced
    return AdaptiveDifficultyRecommendation(
      recommendedLevel: WorkoutDifficultyLevel.advanced,
      currentLevel: currentLevel,
      status: ProgressionStatus.maintained,
      explanation:
          'High performance: Sustaining advanced training volume with $totalWorkouts workouts ($totalReps reps).',
      completedWorkoutsCount: totalWorkouts,
      totalRepsCompleted: totalReps,
      streakDays: streakDays,
      hasSufficientHistory: true,
      evaluatedAt: now,
    );
  }

  /// Sets an explicit user-selected difficulty preference and persists it.
  Future<void> setUserPreferredDifficulty(WorkoutDifficultyLevel level) async {
    _userPreferredLevel = level;
    await _persist();
    await _userService.updateFields(fitnessLevel: level.displayName);
    notifyListeners();
  }

  /// Adopts the currently recommended difficulty tier and persists it.
  Future<void> acceptRecommendation() async {
    final recommendation = evaluateRecommendation();
    await setUserPreferredDifficulty(recommendation.recommendedLevel);
  }

  /// Resets overrides back to baseline user profile.
  Future<void> resetOverrides() async {
    _userPreferredLevel = null;
    await _persist();
    notifyListeners();
  }

  /// Generates Today's Workout tailored to the user's active/recommended difficulty level.
  Workout getAdaptiveTodaysWorkout([WorkoutDifficultyLevel? levelOverride]) {
    final level = levelOverride ?? evaluateRecommendation().recommendedLevel;

    switch (level) {
      case WorkoutDifficultyLevel.beginner:
        return const Workout(
          id: 'w_today_beginner',
          title: 'Hostel Room High-Burn HIIT',
          category: 'Full Body & Posture',
          durationMinutes: 15,
          calories: 150,
          intensity: 'Beginner',
          exercisesCount: 3,
          equipment: 'No Equipment (Dorm Friendly)',
          tags: ['AI Vision Ready', 'Foundation', 'Low Impact', 'Form Check'],
        );
      case WorkoutDifficultyLevel.intermediate:
        return const Workout(
          id: 'w_today_intermediate',
          title: 'Hostel Room High-Burn HIIT',
          category: 'Full Body & Core',
          durationMinutes: 20,
          calories: 220,
          intensity: 'Intermediate',
          exercisesCount: 5,
          equipment: 'No Equipment (Dorm Friendly)',
          tags: ['AI Vision Ready', 'Cardio', 'Core', 'Fat Burn'],
        );
      case WorkoutDifficultyLevel.advanced:
        return const Workout(
          id: 'w_today_advanced',
          title: 'Hostel Room High-Burn HIIT',
          category: 'Full Body & Power',
          durationMinutes: 28,
          calories: 310,
          intensity: 'Advanced',
          exercisesCount: 7,
          equipment: 'No Equipment (Dorm Friendly)',
          tags: [
            'AI Vision Ready',
            'High Intensity',
            'Hypertrophy',
            'Endurance',
          ],
        );
    }
  }

  Future<void> _persist() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final Map<String, dynamic> data = {
          'userPreferredLevel': _userPreferredLevel?.displayName,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('AdaptiveDifficultyService._persist error: $e');
    }
  }

  Future<File?> _getExistingFileOrTarget() async {
    try {
      if (_customStoragePath != null) {
        final dir = Directory(_customStoragePath!);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/$_fileName');
      }

      final candidates = _getCandidateDirectories();
      for (final dirPath in candidates) {
        final file = File('$dirPath/$_fileName');
        if (file.existsSync()) {
          return file;
        }
      }

      for (final dirPath in candidates) {
        try {
          final dir = Directory(dirPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          return File('$dirPath/$_fileName');
        } catch (_) {
          continue;
        }
      }

      return File('${Directory.systemTemp.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  List<String> _getCandidateDirectories() {
    final list = <String>[];
    if (Platform.isAndroid) {
      list.addAll([
        '/data/user/0/com.example.genfit/files',
        '/data/data/com.example.genfit/files',
        '/data/user/0/com.example.genfit/app_flutter',
        '/data/data/com.example.genfit/app_flutter',
      ]);
    }
    list.add(Directory.systemTemp.path);
    return list;
  }
}
