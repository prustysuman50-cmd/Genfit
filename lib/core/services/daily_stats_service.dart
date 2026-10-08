import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/daily_stats.dart';
import '../../models/personalized_goals.dart';
import 'nutrition_service.dart';
import 'personalized_goal_service.dart';

/// Central service managing real user daily activity and hydration stats.
/// Persists records keyed by canonical 'YYYY-MM-DD' dates to `genfit_daily_stats.json`.
class DailyStatsService extends ChangeNotifier {
  DailyStatsService._();

  static final DailyStatsService instance = DailyStatsService._();

  static const String _fileName = 'genfit_daily_stats.json';

  final Map<String, DailyStats> _dailyRecords = {};
  bool _isInitialized = false;
  String? _customStoragePath;
  NutritionService? _observedNutritionService;
  PersonalizedGoalService? _observedGoalService;

  bool get isInitialized => _isInitialized;
  Map<String, DailyStats> get allRecords => Map.unmodifiable(_dailyRecords);

  PersonalizedGoals get _currentPersonalizedGoals =>
      (_observedGoalService ?? PersonalizedGoalService.instance).currentGoals;

  /// Returns today's [DailyStats], creating an empty record if one does not exist yet.
  DailyStats get todayStats {
    final key = DailyStats.formatDate(DateTime.now());
    return getOrCreateStats(key);
  }

  /// Returns or creates a [DailyStats] record for the specified canonical 'YYYY-MM-DD' key.
  /// If creating a new record, its goal fields are initialized using [PersonalizedGoalService]
  /// while all actual telemetry fields start at zero.
  DailyStats getOrCreateStats(String dateKey) {
    if (!_dailyRecords.containsKey(dateKey)) {
      final goals = _currentPersonalizedGoals;
      _dailyRecords[dateKey] = DailyStats(
        date: dateKey,
        stepsGoal: goals.stepsGoal,
        waterGoalMl: goals.waterGoalMl,
        caloriesBurnedGoal: goals.caloriesBurnedGoal,
        activeMinutesGoal: goals.activeMinutesGoal,
        caloriesConsumedGoal: goals.caloriesConsumedGoal,
        proteinGoalGrams: goals.proteinGoalGrams,
      );
    }
    return _dailyRecords[dateKey]!;
  }

  /// Returns or creates a [DailyStats] record for a given [DateTime].
  DailyStats getStatsForDate(DateTime date) {
    final key = DailyStats.formatDate(date);
    return getOrCreateStats(key);
  }

  /// Sets a custom storage directory path (essential for unit test isolation).
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  /// Attaches an observer listener to [service] (defaults to [NutritionService.instance])
  /// to automatically synchronize daily nutrition totals whenever meals or targets change.
  void attachNutritionListener([NutritionService? service]) {
    final target = service ?? NutritionService.instance;
    if (_observedNutritionService != null) {
      _observedNutritionService!.removeListener(_onNutritionChanged);
    }
    _observedNutritionService = target;
    target.addListener(_onNutritionChanged);
  }

  /// Detaches the active [NutritionService] listener.
  void detachNutritionListener() {
    if (_observedNutritionService != null) {
      _observedNutritionService!.removeListener(_onNutritionChanged);
      _observedNutritionService = null;
    }
  }

  void _onNutritionChanged() {
    syncAllDatesFromNutritionService(service: _observedNutritionService);
  }

  /// Attaches an observer listener to [service] (defaults to [PersonalizedGoalService.instance])
  /// to automatically update today's goals whenever personalized targets change.
  void attachGoalListener([PersonalizedGoalService? service]) {
    final target = service ?? PersonalizedGoalService.instance;
    if (_observedGoalService != null) {
      _observedGoalService!.removeListener(_onGoalsChanged);
    }
    _observedGoalService = target;
    target.addListener(_onGoalsChanged);
  }

  /// Detaches the active [PersonalizedGoalService] listener.
  void detachGoalListener() {
    if (_observedGoalService != null) {
      _observedGoalService!.removeListener(_onGoalsChanged);
      _observedGoalService = null;
    }
  }

  void _onGoalsChanged() {
    updateTodayGoals();
  }

  /// Updates only the goal targets for today's [DailyStats] record using the latest
  /// [PersonalizedGoals] (or optionally provided [customGoals]), preserving all
  /// actual recorded telemetry and leaving historical dates completely untouched.
  ///
  /// Historical records remain frozen with their respective goals and telemetry as
  /// recorded, preventing retroactive rewriting of activity history.
  Future<void> updateTodayGoals([PersonalizedGoals? customGoals]) async {
    final todayKey = DailyStats.formatDate(DateTime.now());
    final current = getOrCreateStats(todayKey);
    final goals = customGoals ?? _currentPersonalizedGoals;

    final updated = current.copyWith(
      stepsGoal: goals.stepsGoal,
      waterGoalMl: goals.waterGoalMl,
      caloriesBurnedGoal: goals.caloriesBurnedGoal,
      activeMinutesGoal: goals.activeMinutesGoal,
      caloriesConsumedGoal: goals.caloriesConsumedGoal,
      proteinGoalGrams: goals.proteinGoalGrams,
    );

    _dailyRecords[todayKey] = updated;
    await _persist();
    notifyListeners();
  }

  /// Initializes the service by reading `genfit_daily_stats.json` from disk.
  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data['dailyRecords'] is Map) {
            final recordsMap = data['dailyRecords'] as Map<String, dynamic>;
            _dailyRecords.clear();
            recordsMap.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                _dailyRecords[key] = DailyStats.fromJson(value);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('DailyStatsService init error: $e');
    } finally {
      // Always ensure today's record is initialized
      final todayKey = DailyStats.formatDate(DateTime.now());
      if (!_dailyRecords.containsKey(todayKey)) {
        final goals = _currentPersonalizedGoals;
        _dailyRecords[todayKey] = DailyStats(
          date: todayKey,
          stepsGoal: goals.stepsGoal,
          waterGoalMl: goals.waterGoalMl,
          caloriesBurnedGoal: goals.caloriesBurnedGoal,
          activeMinutesGoal: goals.activeMinutesGoal,
          caloriesConsumedGoal: goals.caloriesConsumedGoal,
          proteinGoalGrams: goals.proteinGoalGrams,
        );
      }
      _isInitialized = true;
      attachNutritionListener();
      attachGoalListener();
      notifyListeners();
    }
  }

  /// Adds water in milliliters to the specified date (defaults to today), persists immediately,
  /// and notifies listeners.
  Future<void> addWater(int ml, {DateTime? date}) async {
    if (ml <= 0) return;
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);
    final updated = current.copyWith(waterMl: current.waterMl + ml);
    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Sets or updates the daily activity metrics (steps, activeMinutes, caloriesBurned)
  /// for today (or a specified [date]).
  ///
  /// Any parameter left null will retain its current value.
  /// This method is idempotent: reporting the same values repeatedly will NOT
  /// result in duplicate counting or accidental accumulation.
  Future<void> updateActivity({
    int? steps,
    int? activeMinutes,
    int? caloriesBurned,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);

    final updated = current.copyWith(
      steps: steps != null && steps >= 0 ? steps : current.steps,
      activeMinutes: activeMinutes != null && activeMinutes >= 0
          ? activeMinutes
          : current.activeMinutes,
      caloriesBurned: caloriesBurned != null && caloriesBurned >= 0
          ? caloriesBurned
          : current.caloriesBurned,
    );

    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Alias for [updateActivity] ensuring compatibility with different caller semantics.
  Future<void> setActivityMetrics({
    int? steps,
    int? activeMinutes,
    int? caloriesBurned,
    DateTime? date,
  }) => updateActivity(
    steps: steps,
    activeMinutes: activeMinutes,
    caloriesBurned: caloriesBurned,
    date: date,
  );

  /// Adds steps (and optionally calories burned) to today (or a specified [date]).
  Future<void> addSteps(
    int steps, {
    int caloriesBurned = 0,
    DateTime? date,
  }) async {
    if (steps <= 0 && caloriesBurned <= 0) return;
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);

    final updated = current.copyWith(
      steps: current.steps + (steps > 0 ? steps : 0),
      caloriesBurned:
          current.caloriesBurned + (caloriesBurned > 0 ? caloriesBurned : 0),
    );

    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Adds active minutes (and optionally calories burned) to today (or a specified [date]).
  Future<void> addActiveMinutes(
    int minutes, {
    int caloriesBurned = 0,
    DateTime? date,
  }) async {
    if (minutes <= 0 && caloriesBurned <= 0) return;
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);

    final updated = current.copyWith(
      activeMinutes: current.activeMinutes + (minutes > 0 ? minutes : 0),
      caloriesBurned:
          current.caloriesBurned + (caloriesBurned > 0 ? caloriesBurned : 0),
    );

    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Adds calories burned to today (or a specified [date]).
  Future<void> addCaloriesBurned(int calories, {DateTime? date}) async {
    if (calories <= 0) return;
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);

    final updated = current.copyWith(
      caloriesBurned: current.caloriesBurned + calories,
    );

    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Records a completed workout session, accumulating workout count, duration minutes,
  /// repetitions, and calories burned for today (or the specified date). Persists immediately
  /// and notifies listeners.
  Future<void> recordWorkoutCompleted({
    required int durationMinutes,
    required int totalReps,
    int caloriesBurned = 0,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);
    final updated = current.copyWith(
      workoutsCompleted: current.workoutsCompleted + 1,
      workoutMinutes:
          current.workoutMinutes + (durationMinutes > 0 ? durationMinutes : 0),
      totalReps: current.totalReps + (totalReps > 0 ? totalReps : 0),
      caloriesBurned:
          current.caloriesBurned + (caloriesBurned > 0 ? caloriesBurned : 0),
    );
    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Synchronizes daily nutrition totals (calories, protein, carbs, fats, meals logged)
  /// from the authoritative [NutritionService] for today (or a specified [date]).
  ///
  /// Prevents double-counting by deriving totals directly from the meal records rather
  /// than incrementing accumulators.
  Future<void> syncNutritionFromService({
    NutritionService? service,
    DateTime? date,
  }) async {
    final nutrition =
        service ?? _observedNutritionService ?? NutritionService.instance;
    final targetDate = date ?? DateTime.now();
    final key = DailyStats.formatDate(targetDate);
    final current = getOrCreateStats(key);

    final mealsForDate = nutrition.allMeals.where((m) {
      return m.loggedAt.year == targetDate.year &&
          m.loggedAt.month == targetDate.month &&
          m.loggedAt.day == targetDate.day;
    }).toList();

    final double calories = double.parse(
      mealsForDate
          .fold<double>(0.0, (sum, m) => sum + m.calories)
          .toStringAsFixed(1),
    );
    final double protein = double.parse(
      mealsForDate
          .fold<double>(0.0, (sum, m) => sum + m.protein)
          .toStringAsFixed(1),
    );
    final double carbs = double.parse(
      mealsForDate
          .fold<double>(0.0, (sum, m) => sum + m.carbohydrates)
          .toStringAsFixed(1),
    );
    final double fats = double.parse(
      mealsForDate
          .fold<double>(0.0, (sum, m) => sum + m.fats)
          .toStringAsFixed(1),
    );
    final int mealsLogged = mealsForDate.length;

    final updated = current.copyWith(
      caloriesConsumed: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatsGrams: fats,
      mealsLogged: mealsLogged,
    );

    _dailyRecords[key] = updated;
    await _persist();
    notifyListeners();
  }

  /// Synchronizes nutrition totals for all dates that contain meals in [NutritionService],
  /// as well as today.
  Future<void> syncAllDatesFromNutritionService({
    NutritionService? service,
  }) async {
    final nutrition =
        service ?? _observedNutritionService ?? NutritionService.instance;
    final dates = <String>{DailyStats.formatDate(DateTime.now())};
    for (final meal in nutrition.allMeals) {
      dates.add(DailyStats.formatDate(meal.loggedAt));
    }

    for (final dateStr in dates) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final targetDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final key = DailyStats.formatDate(targetDate);
        final current = getOrCreateStats(key);

        final mealsForDate = nutrition.allMeals.where((m) {
          return m.loggedAt.year == targetDate.year &&
              m.loggedAt.month == targetDate.month &&
              m.loggedAt.day == targetDate.day;
        }).toList();

        final double calories = double.parse(
          mealsForDate
              .fold<double>(0.0, (sum, m) => sum + m.calories)
              .toStringAsFixed(1),
        );
        final double protein = double.parse(
          mealsForDate
              .fold<double>(0.0, (sum, m) => sum + m.protein)
              .toStringAsFixed(1),
        );
        final double carbs = double.parse(
          mealsForDate
              .fold<double>(0.0, (sum, m) => sum + m.carbohydrates)
              .toStringAsFixed(1),
        );
        final double fats = double.parse(
          mealsForDate
              .fold<double>(0.0, (sum, m) => sum + m.fats)
              .toStringAsFixed(1),
        );
        final int mealsLogged = mealsForDate.length;

        final updated = current.copyWith(
          caloriesConsumed: calories,
          proteinGrams: protein,
          carbsGrams: carbs,
          fatsGrams: fats,
          mealsLogged: mealsLogged,
        );

        _dailyRecords[key] = updated;
      }
    }
    await _persist();
    notifyListeners();
  }

  /// Resets in-memory stats to empty defaults and clears disk persistence.
  Future<void> resetToDefaults() async {
    detachNutritionListener();
    detachGoalListener();
    _dailyRecords.clear();
    final todayKey = DailyStats.formatDate(DateTime.now());
    final goals = _currentPersonalizedGoals;
    _dailyRecords[todayKey] = DailyStats(
      date: todayKey,
      stepsGoal: goals.stepsGoal,
      waterGoalMl: goals.waterGoalMl,
      caloriesBurnedGoal: goals.caloriesBurnedGoal,
      activeMinutesGoal: goals.activeMinutesGoal,
      caloriesConsumedGoal: goals.caloriesConsumedGoal,
      proteinGoalGrams: goals.proteinGoalGrams,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final Map<String, dynamic> data = {
          'dailyRecords': _dailyRecords.map(
            (key, val) => MapEntry(key, val.toJson()),
          ),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('DailyStatsService persist error: $e');
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

      // Check if file already exists in any candidate directory
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
