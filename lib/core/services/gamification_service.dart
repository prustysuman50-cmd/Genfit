import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../models/daily_stats.dart';
import '../../models/gamification/badge_item.dart';
import '../../models/gamification/campus_rank.dart';
import '../../models/gamification/gamification_rewards.dart';
import 'daily_stats_service.dart';
import 'nutrition_service.dart';

class GamificationService extends ChangeNotifier {
  GamificationService._();

  static final GamificationService instance = GamificationService._();

  static const String _fileName = 'genfit_gamification.json';

  static const List<CampusRankTier> levelTiers = [
    CampusRankTier(
      level: 1,
      minXp: 0,
      maxXp: 499,
      title: 'Campus Rookie',
      subtitle: 'Starting your college fitness journey',
      icon: Icons.school_rounded,
    ),
    CampusRankTier(
      level: 2,
      minXp: 500,
      maxXp: 1199,
      title: 'Hostel Hustler',
      subtitle: 'Building daily discipline in dorms & hostel rooms',
      icon: Icons.hotel_rounded,
    ),
    CampusRankTier(
      level: 3,
      minXp: 1200,
      maxXp: 2199,
      title: 'Fitness Seeker',
      subtitle: 'Consistent training between lectures and mess',
      icon: Icons.fitness_center_rounded,
    ),
    CampusRankTier(
      level: 4,
      minXp: 2200,
      maxXp: 3499,
      title: 'Campus Warrior',
      subtitle: 'Inspiring peers and maintaining high strength habits',
      icon: Icons.shield_rounded,
    ),
    CampusRankTier(
      level: 5,
      minXp: 3500,
      maxXp: 4999,
      title: 'Desi Beast',
      subtitle: 'Unstoppable work ethic and high-intensity stamina',
      icon: Icons.bolt_rounded,
    ),
    CampusRankTier(
      level: 6,
      minXp: 5000,
      maxXp: 6999,
      title: 'Odisha Titan',
      subtitle: 'Endurance champion leading campus fitness trails',
      icon: Icons.landscape_rounded,
    ),
    CampusRankTier(
      level: 7,
      minXp: 7000,
      maxXp: 9999,
      title: 'Campus Legend',
      subtitle: 'Elite athletic status across the university community',
      icon: Icons.military_tech_rounded,
    ),
    CampusRankTier(
      level: 8,
      minXp: 10000,
      maxXp: 999999,
      title: 'Grandmaster',
      subtitle: 'Peak athletic mastery. Highest honor in GenFit.',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  static List<BadgeItem> get initialBadges => [
    const BadgeItem(
      id: 'first_workout',
      name: 'First Workout',
      description: 'Completed your first workout session in GenFit',
      icon: Icons.fitness_center_rounded,
      category: 'Workouts',
    ),
    const BadgeItem(
      id: 'seven_day_streak',
      name: '7 Day Streak',
      description: 'Maintained a 7-day fitness streak',
      icon: Icons.local_fire_department_rounded,
      category: 'Consistency',
    ),
    const BadgeItem(
      id: 'hundred_reps',
      name: '100 Reps',
      description: 'Crushed 100 cumulative exercise repetitions',
      icon: Icons.military_tech_rounded,
      category: 'Workouts',
    ),
    const BadgeItem(
      id: 'first_meal_logged',
      name: 'First Meal Logged',
      description: 'Logged your first meal in the Nutrition module',
      icon: Icons.restaurant_rounded,
      category: 'Nutrition',
    ),
    const BadgeItem(
      id: 'campus_challenger',
      name: 'Campus Challenger',
      description: 'Completed your first daily campus challenge',
      icon: Icons.emoji_events_rounded,
      category: 'Challenges',
    ),
    const BadgeItem(
      id: 'journey_starter',
      name: 'Journey Starter',
      description: 'Started your Odisha Fitness Trail journey',
      icon: Icons.explore_rounded,
      category: 'Odisha Heritage',
    ),
    const BadgeItem(
      id: 'odisha_explorer',
      name: 'Odisha Explorer',
      description: 'Explored 3 or more regional fitness trail milestones',
      icon: Icons.map_rounded,
      category: 'Odisha Heritage',
    ),
  ];

  static List<Challenge> get defaultChallenges => [
    const Challenge(
      id: 'c_campus_steps',
      title: 'Campus Steps Sprint',
      description: 'Walk 3,000 active steps between college classes today',
      rewardXp: 150,
      progress: 0,
      target: 3000,
      unit: 'steps',
      category: 'Daily Quest',
      timeLeft: '4 hours left',
    ),
    const Challenge(
      id: 'c_streak_7',
      title: '7 Day Streak',
      description: 'Keep your GenFit streak alive for 7 consecutive days',
      rewardXp: 100,
      progress: 0,
      target: 7,
      unit: 'days',
      category: 'Consistency',
      timeLeft: 'Today',
    ),
    const Challenge(
      id: 'c_squats_100',
      title: '100 Squats',
      description: 'Accumulate 100 AI form-checked squats in workout sessions',
      rewardXp: 100,
      progress: 0,
      target: 100,
      unit: 'reps',
      category: 'Strength',
      timeLeft: 'Today',
    ),
    const Challenge(
      id: 'c_steps_10k',
      title: '10K Steps',
      description: 'Walk 10,000 active steps across campus today',
      rewardXp: 50,
      progress: 0,
      target: 10000,
      unit: 'steps',
      category: 'Cardio',
      timeLeft: 'Today',
    ),
    const Challenge(
      id: 'c_weekend_workout',
      title: 'Weekend Workout',
      description: 'Complete a full HIIT or mobility session this weekend',
      rewardXp: 75,
      progress: 0,
      target: 1,
      unit: 'session',
      category: 'Weekend Special',
      timeLeft: '2 days left',
    ),
    const Challenge(
      id: 'c_campus_champion',
      title: 'Campus Champion',
      description: 'Log 3 meals and complete 1 workout in a single day',
      rewardXp: 120,
      progress: 0,
      target: 4,
      unit: 'tasks',
      category: 'Elite Quest',
      timeLeft: 'Today',
    ),
  ];

  int _xp = 0;
  int _streakDays = 0;
  DateTime? _lastActiveDate;

  int _totalWorkoutsCompleted = 0;
  int _totalMealsLogged = 0;
  int _totalReps = 0;
  int _totalChallengesCompleted = 0;
  int _totalMilestonesCompleted = 0;

  List<BadgeItem> _badges = initialBadges;
  List<Challenge> _challenges = defaultChallenges;

  bool _isInitialized = false;
  String? _customStoragePath;
  int _lastObservedMealCount = 0;
  bool _isNutritionListenerAttached = false;
  DailyStatsService? _customDailyStatsService;
  VoidCallback? _dailyStatsListener;
  DailyStatsService? _currentlyAttachedDailyStatsService;

  DailyStatsService get _effectiveDailyStatsService =>
      _customDailyStatsService ?? DailyStatsService.instance;

  /// Sets a custom [DailyStatsService] instance (useful for unit testing isolation).
  void setDailyStatsService(DailyStatsService? service) {
    detachDailyStatsListener();
    _customDailyStatsService = service;
    if (service != null) {
      attachDailyStatsListener(service);
    }
  }

  /// Attaches an automated listener to [DailyStatsService] to synchronize challenge progress.
  void attachDailyStatsListener([DailyStatsService? service]) {
    final target = service ?? _effectiveDailyStatsService;
    if (_currentlyAttachedDailyStatsService == target &&
        _dailyStatsListener != null) {
      return;
    }
    detachDailyStatsListener();
    _currentlyAttachedDailyStatsService = target;
    _dailyStatsListener = () {
      syncChallengesFromDailyStats(target.todayStats);
    };
    target.addListener(_dailyStatsListener!);
  }

  /// Detaches the automated listener from [DailyStatsService].
  void detachDailyStatsListener() {
    if (_currentlyAttachedDailyStatsService != null &&
        _dailyStatsListener != null) {
      _currentlyAttachedDailyStatsService!.removeListener(_dailyStatsListener!);
      _currentlyAttachedDailyStatsService = null;
      _dailyStatsListener = null;
    }
  }

  bool get isInitialized => _isInitialized;
  int get xp => _xp;
  int get streakDays => _streakDays;
  DateTime? get lastActiveDate => _lastActiveDate;

  int get totalWorkoutsCompleted => _totalWorkoutsCompleted;
  int get totalMealsLogged => _totalMealsLogged;
  int get totalReps => _totalReps;
  int get totalChallengesCompleted => _totalChallengesCompleted;
  int get totalMilestonesCompleted => _totalMilestonesCompleted;

  List<BadgeItem> get badges => List.unmodifiable(_badges);
  List<Challenge> get challenges => List.unmodifiable(_challenges);

  Challenge get activeChallenge {
    try {
      return _challenges.firstWhere((c) => !c.isCompleted);
    } catch (_) {
      return _challenges.first;
    }
  }

  Challenge? getChallengeById(String id) {
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  BadgeItem? getBadgeById(String id) {
    try {
      return _badges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Level Calculations ---

  CampusRankTier get _currentTier {
    for (final tier in levelTiers) {
      if (_xp >= tier.minXp && _xp <= tier.maxXp) {
        return tier;
      }
    }
    return levelTiers.last;
  }

  /// All 8 official campus rank tiers in ascending progression order.
  List<CampusRankTier> get allTiers => List.unmodifiable(levelTiers);

  /// Current athletic tier corresponding to the user's accumulated XP.
  CampusRankTier get currentTier => _currentTier;

  /// Whether the user has achieved the pinnacle Grandmaster rank.
  bool get isMaxRank => currentLevel >= 8;

  int get currentLevel => _currentTier.level;
  String get levelTitle => _currentTier.title;
  int get currentLevelBaseXp => _currentTier.minXp;
  int get nextLevelXp => _currentTier.maxXp + 1;

  int get xpRequiredForNextLevel {
    if (isMaxRank) return 0;
    final needed = nextLevelXp - _xp;
    return needed > 0 ? needed : 0;
  }

  double get levelProgress {
    if (isMaxRank) return 1.0;
    final span = nextLevelXp - currentLevelBaseXp;
    if (span <= 0) return 1.0;
    final progress = (_xp - currentLevelBaseXp) / span;
    return progress.clamp(0.0, 1.0);
  }

  // --- Configuration & Initialization ---

  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          _xp = (data['xp'] as num?)?.toInt() ?? 0;
          _streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;
          if (data['lastActiveDate'] != null) {
            _lastActiveDate = DateTime.tryParse(
              data['lastActiveDate'] as String,
            );
          }
          _totalWorkoutsCompleted =
              (data['totalWorkoutsCompleted'] as num?)?.toInt() ?? 0;
          _totalMealsLogged = (data['totalMealsLogged'] as num?)?.toInt() ?? 0;
          _totalReps = (data['totalReps'] as num?)?.toInt() ?? 0;
          _totalChallengesCompleted =
              (data['totalChallengesCompleted'] as num?)?.toInt() ?? 0;
          _totalMilestonesCompleted =
              (data['totalMilestonesCompleted'] as num?)?.toInt() ?? 0;

          if (data['badges'] is List) {
            final loadedBadges = <BadgeItem>[];
            for (final b in data['badges']) {
              if (b is Map<String, dynamic>) {
                loadedBadges.add(BadgeItem.fromJson(b));
              }
            }
            // Merge loaded badges with initial definition so any new badge is present
            _badges = _mergeBadges(loadedBadges);
          }

          if (data['challenges'] is List) {
            final loadedChallenges = <Challenge>[];
            for (final c in data['challenges']) {
              if (c is Map<String, dynamic>) {
                loadedChallenges.add(Challenge.fromJson(c));
              }
            }
            _challenges = _mergeChallenges(loadedChallenges);
          }
        }
      }
    } catch (e) {
      debugPrint('GamificationService init error: $e');
    } finally {
      _isInitialized = true;
      _attachNutritionListener();
      attachDailyStatsListener();
      notifyListeners();
    }
  }

  void _attachNutritionListener() {
    if (_isNutritionListenerAttached) return;
    _isNutritionListenerAttached = true;
    _lastObservedMealCount = NutritionService.instance.allMeals.length;

    NutritionService.instance.addListener(() {
      final currentCount = NutritionService.instance.allMeals.length;
      if (currentCount > _lastObservedMealCount) {
        final newMealsCount = currentCount - _lastObservedMealCount;
        _lastObservedMealCount = currentCount;
        for (int i = 0; i < newMealsCount; i++) {
          recordMealLogged();
        }
      } else {
        _lastObservedMealCount = currentCount;
      }
    });
  }

  List<BadgeItem> _mergeBadges(List<BadgeItem> loaded) {
    final map = {for (final b in initialBadges) b.id: b};
    for (final l in loaded) {
      if (map.containsKey(l.id)) {
        map[l.id] = map[l.id]!.copyWith(
          isUnlocked: l.isUnlocked,
          unlockedAt: l.unlockedAt,
        );
      } else {
        map[l.id] = l;
      }
    }
    return map.values.toList();
  }

  List<Challenge> _mergeChallenges(List<Challenge> loaded) {
    final map = {for (final c in defaultChallenges) c.id: c};
    for (final l in loaded) {
      if (map.containsKey(l.id)) {
        map[l.id] = map[l.id]!.copyWith(
          progress: l.progress,
          isCompleted: l.isCompleted,
        );
      } else {
        map[l.id] = l;
      }
    }
    return map.values.toList();
  }

  // --- Streak Engine ---

  void recordActivity({DateTime? atDate}) {
    final date = atDate ?? DateTime.now();
    final today = DateTime(date.year, date.month, date.day);

    if (_lastActiveDate == null) {
      // First active day starts a 1-day streak
      _streakDays = 1;
      _lastActiveDate = today;
    } else {
      final lastDate = DateTime(
        _lastActiveDate!.year,
        _lastActiveDate!.month,
        _lastActiveDate!.day,
      );
      final dayDiff = today.difference(lastDate).inDays;

      if (dayDiff == 0) {
        // Multiple actions on the same day must not increase streak multiple times
      } else if (dayDiff == 1) {
        // Consecutive active days increase the streak
        _streakDays += 1;
        _lastActiveDate = today;
      } else if (dayDiff > 1) {
        // Missing a calendar day resets the streak
        _streakDays = 1;
        _lastActiveDate = today;
      }
    }

    _checkBadgesInternal(atDate: date);
  }

  void checkStreakReset({DateTime? currentDate}) {
    if (_lastActiveDate == null) return;
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastActiveDate!.year,
      _lastActiveDate!.month,
      _lastActiveDate!.day,
    );
    final dayDiff = today.difference(lastDate).inDays;
    if (dayDiff > 1) {
      _streakDays = 0;
    }
  }

  // --- XP & Action Handlers ---

  Future<void> addXp(int amount, {String? reason}) async {
    if (amount <= 0) return;
    _xp += amount;
    _checkBadgesInternal();
    await _persist();
    notifyListeners();
  }

  Future<void> recordWorkoutCompleted({
    String? workoutId,
    int reps = 0,
    DateTime? atDate,
  }) async {
    _totalWorkoutsCompleted += 1;
    if (reps > 0) {
      _totalReps += reps;
    }
    recordActivity(atDate: atDate);
    _xp += GamificationRewards.workoutCompleted;
    _checkBadgesInternal(atDate: atDate);
    await _persist();
    notifyListeners();
  }

  Future<void> recordMealLogged({String? mealId, DateTime? atDate}) async {
    _totalMealsLogged += 1;
    recordActivity(atDate: atDate);
    _xp += GamificationRewards.mealLogged;
    _checkBadgesInternal(atDate: atDate);
    await _persist();
    notifyListeners();
  }

  Future<void> recordJourneyMilestone(
    String milestoneId, {
    DateTime? atDate,
  }) async {
    _totalMilestonesCompleted += 1;
    recordActivity(atDate: atDate);
    _xp += GamificationRewards.journeyMilestone;
    _checkBadgesInternal(atDate: atDate);
    await _persist();
    notifyListeners();
  }

  Future<void> progressChallenge(
    String challengeId, {
    int delta = 1,
    DateTime? atDate,
  }) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return;

    final challenge = _challenges[index];
    if (challenge.isCompleted) return;

    final newProgress = (challenge.progress + delta).clamp(0, challenge.target);
    final isDone = newProgress >= challenge.target;

    _challenges[index] = challenge.copyWith(
      progress: newProgress,
      isCompleted: isDone,
    );

    recordActivity(atDate: atDate);

    if (isDone) {
      _totalChallengesCompleted += 1;
      _xp += challenge.rewardXp > 0
          ? challenge.rewardXp
          : GamificationRewards.dailyChallengeCompleted;
      _checkBadgesInternal(atDate: atDate);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> completeChallenge(String challengeId, {DateTime? atDate}) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return;

    final challenge = _challenges[index];
    if (challenge.isCompleted) return;

    _challenges[index] = challenge.copyWith(
      progress: challenge.target,
      isCompleted: true,
    );

    _totalChallengesCompleted += 1;
    recordActivity(atDate: atDate);
    _xp += challenge.rewardXp > 0
        ? challenge.rewardXp
        : GamificationRewards.dailyChallengeCompleted;
    _checkBadgesInternal(atDate: atDate);

    await _persist();
    notifyListeners();
  }

  /// Synchronizes daily challenge progress from factual [DailyStats] telemetry.
  ///
  /// This method is strictly idempotent: calling it repeatedly with unchanged
  /// or incremental telemetry will NOT duplicate progress or award duplicate XP.
  /// Historical [DailyStats] (dates other than today) are rejected to prevent
  /// retroactive challenge progression.
  Future<void> syncChallengesFromDailyStats(
    DailyStats stats, {
    DateTime? atDate,
  }) async {
    final effectiveDate = atDate ?? DateTime.now();
    final todayKey = DailyStats.formatDate(effectiveDate);
    if (stats.date != todayKey) {
      // Historical DailyStats records do not create challenge progress or award XP.
      return;
    }

    bool hasChanged = false;

    for (int i = 0; i < _challenges.length; i++) {
      final challenge = _challenges[i];
      if (challenge.isCompleted) {
        // Completed challenges are never re-evaluated and never award duplicate XP.
        continue;
      }

      int newProgress = challenge.progress;
      bool isNowDone = false;

      switch (challenge.id) {
        case 'c_campus_steps':
        case 'c_steps_10k':
          newProgress = stats.steps.clamp(0, challenge.target);
          isNowDone = stats.steps >= challenge.target;
          break;

        case 'c_squats_100':
          newProgress = stats.totalReps.clamp(0, challenge.target);
          isNowDone = stats.totalReps >= challenge.target;
          break;

        case 'c_weekend_workout':
          newProgress = stats.workoutsCompleted.clamp(0, challenge.target);
          isNowDone = stats.workoutsCompleted >= challenge.target;
          break;

        case 'c_campus_champion':
          // Log 3 meals AND complete 1 workout in a single day
          final mealsContribution = stats.mealsLogged.clamp(0, 3);
          final workoutContribution = stats.workoutsCompleted >= 1 ? 1 : 0;
          newProgress = (mealsContribution + workoutContribution).clamp(
            0,
            challenge.target,
          );
          isNowDone = stats.mealsLogged >= 3 && stats.workoutsCompleted >= 1;
          break;

        case 'c_streak_7':
          newProgress = _streakDays.clamp(0, challenge.target);
          isNowDone = _streakDays >= challenge.target;
          break;

        default:
          if (challenge.unit.toLowerCase() == 'steps') {
            newProgress = stats.steps.clamp(0, challenge.target);
            isNowDone = stats.steps >= challenge.target;
          } else if (challenge.unit.toLowerCase() == 'reps') {
            newProgress = stats.totalReps.clamp(0, challenge.target);
            isNowDone = stats.totalReps >= challenge.target;
          } else if (challenge.unit.toLowerCase() == 'session' ||
              challenge.unit.toLowerCase() == 'workout') {
            newProgress = stats.workoutsCompleted.clamp(0, challenge.target);
            isNowDone = stats.workoutsCompleted >= challenge.target;
          } else {
            continue;
          }
          break;
      }

      if (newProgress != challenge.progress || isNowDone != challenge.isCompleted) {
        _challenges[i] = challenge.copyWith(
          progress: newProgress,
          isCompleted: isNowDone,
        );
        hasChanged = true;

        if (isNowDone) {
          _totalChallengesCompleted += 1;
          _xp += challenge.rewardXp > 0
              ? challenge.rewardXp
              : GamificationRewards.dailyChallengeCompleted;
          recordActivity(atDate: effectiveDate);
          _checkBadgesInternal(atDate: effectiveDate);
        }
      }
    }

    if (hasChanged) {
      await _persist();
      notifyListeners();
    }
  }

  // --- Badges Engine ---

  void unlockBadge(String badgeId, {DateTime? atDate}) {
    final index = _badges.indexWhere((b) => b.id == badgeId);
    if (index != -1 && !_badges[index].isUnlocked) {
      _badges[index] = _badges[index].copyWith(
        isUnlocked: true,
        unlockedAt: atDate ?? DateTime.now(),
      );
    }
  }

  void _checkBadgesInternal({DateTime? atDate}) {
    final now = atDate ?? DateTime.now();

    // 1. First Workout
    if (_totalWorkoutsCompleted >= 1) {
      unlockBadge('first_workout', atDate: now);
    }

    // 2. 7 Day Streak
    if (_streakDays >= 7) {
      unlockBadge('seven_day_streak', atDate: now);
    }

    // 3. 100 Reps
    if (_totalReps >= 100) {
      unlockBadge('hundred_reps', atDate: now);
    }

    // 4. First Meal Logged
    if (_totalMealsLogged >= 1) {
      unlockBadge('first_meal_logged', atDate: now);
    }

    // 5. Campus Challenger
    if (_totalChallengesCompleted >= 1) {
      unlockBadge('campus_challenger', atDate: now);
    }

    // 6. Journey Starter
    if (_totalMilestonesCompleted >= 1) {
      unlockBadge('journey_starter', atDate: now);
    }

    // 7. Odisha Explorer
    if (_totalMilestonesCompleted >= 3) {
      unlockBadge('odisha_explorer', atDate: now);
    }
  }

  Future<void> resetToDefaults() async {
    _xp = 0;
    _streakDays = 0;
    _lastActiveDate = null;
    _totalWorkoutsCompleted = 0;
    _totalMealsLogged = 0;
    _totalReps = 0;
    _totalChallengesCompleted = 0;
    _totalMilestonesCompleted = 0;
    _badges = initialBadges;
    _challenges = defaultChallenges;
    _lastObservedMealCount = 0;
    detachDailyStatsListener();
    _customDailyStatsService = null;
    await _persist();
    notifyListeners();
  }

  // --- Local File Persistence ---

  Future<void> _persist() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final Map<String, dynamic> data = {
          'xp': _xp,
          'streakDays': _streakDays,
          'lastActiveDate': _lastActiveDate?.toIso8601String(),
          'totalWorkoutsCompleted': _totalWorkoutsCompleted,
          'totalMealsLogged': _totalMealsLogged,
          'totalReps': _totalReps,
          'totalChallengesCompleted': _totalChallengesCompleted,
          'totalMilestonesCompleted': _totalMilestonesCompleted,
          'badges': _badges.map((b) => b.toJson()).toList(),
          'challenges': _challenges.map((c) => c.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('GamificationService persist error: $e');
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

      // Check if file already exists in candidate
      for (final dirPath in candidates) {
        final file = File('$dirPath/$_fileName');
        if (file.existsSync()) {
          return file;
        }
      }

      // Return first writable candidate
      for (final dirPath in candidates) {
        try {
          final dir = Directory(dirPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final testFile = File('$dirPath/$_fileName');
          return testFile;
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
      final pkg = _getAndroidPackageName() ?? 'com.example.genfit';
      list.addAll([
        '/data/user/0/$pkg/files',
        '/data/data/$pkg/files',
        '/data/user/0/$pkg/app_flutter',
        '/data/data/$pkg/app_flutter',
        '/data/user/0/com.example.genfit/files',
        '/data/data/com.example.genfit/files',
        '/data/user/0/$pkg/cache',
        '/data/data/$pkg/cache',
      ]);
    }

    list.add(Directory.systemTemp.path);
    return list;
  }

  String? _getAndroidPackageName() {
    try {
      final cmd = File('/proc/self/cmdline').readAsStringSync();
      final pkg = cmd.split('\u0000').first.trim();
      if (pkg.isNotEmpty && pkg.contains('.')) return pkg;
    } catch (_) {}
    return null;
  }
}
