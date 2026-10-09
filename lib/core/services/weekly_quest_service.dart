import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/gamification/iso_week.dart';
import '../../models/gamification/weekly_quest.dart';
import 'daily_stats_service.dart';
import 'gamification_service.dart';

/// Central service managing the GenFit Weekly Quest Board.
///
/// Responsibilities:
/// - Aggregates factual activity strictly within the active ISO week (Monday–Sunday).
/// - Enforces exact-once duplicate reward protection per quest per ISO week.
/// - Grants quest XP rewards solely through [GamificationService.addXp].
/// - Retains full offline persistence in `genfit_weekly_quests.json`.
///
/// Note on Crash-Consistency:
/// GenFit operates offline with independent JSON flat files (`genfit_weekly_quests.json`
/// and `genfit_gamification.json`). The guarded flow registers and persists the claim record
/// before calling [GamificationService.addXp]. In the event of an abrupt process crash
/// occurring between the two separate file I/O operations, the claim record prevents
/// duplicate XP payout, but cross-file ACID atomicity requires a transactional SQLite engine.
class WeeklyQuestService extends ChangeNotifier {
  WeeklyQuestService._();

  static final WeeklyQuestService instance = WeeklyQuestService._();

  static const String _fileName = 'genfit_weekly_quests.json';

  String? _customStoragePath;
  bool _isInitialized = false;

  final Set<String> _claimedRewardKeys = {};
  final Set<String> _pendingClaimKeys = {};

  DailyStatsService? _customDailyStatsService;
  GamificationService? _customGamificationService;
  VoidCallback? _dailyStatsListener;
  DailyStatsService? _currentlyAttachedDailyStatsService;

  DateTime? _mockDate;

  bool get isInitialized => _isInitialized;
  Set<String> get claimedRewardKeys => Set.unmodifiable(_claimedRewardKeys);

  DailyStatsService get _effectiveDailyStatsService =>
      _customDailyStatsService ?? DailyStatsService.instance;

  GamificationService get _effectiveGamificationService =>
      _customGamificationService ?? GamificationService.instance;

  /// Effective date used for ISO week evaluation (supports deterministic unit tests).
  DateTime get effectiveCurrentDate => _mockDate ?? DateTime.now();

  /// The active [IsoWeek] calculated from the effective date.
  IsoWeek get currentWeek => IsoWeek.fromDateTime(effectiveCurrentDate);

  /// Canonical ISO week key, e.g. `2026-W41`.
  String get currentWeekKey => currentWeek.weekKey;

  /// Default 5-quest template designed for balanced campus weekly fitness.
  ///
  /// Note on Heritage Journey:
  /// Heritage milestones currently track cumulative lifetime distance without
  /// ISO-week date telemetry. To preserve integrity and never fabricate progress,
  /// weekly heritage quests are intentionally omitted until weekly route telemetry exists.
  static List<WeeklyQuest> get defaultQuestsTemplate => const [
    WeeklyQuest(
      id: 'weekly_workouts',
      title: 'Campus Iron',
      description: 'Complete 3 verified workout sessions this week',
      target: 3,
      unit: 'workouts',
      rewardXp: 150,
      category: 'Workouts',
    ),
    WeeklyQuest(
      id: 'weekly_steps',
      title: 'Campus Trekker',
      description: 'Accumulate 25,000 active steps across campus this week',
      target: 25000,
      unit: 'steps',
      rewardXp: 150,
      category: 'Steps',
    ),
    WeeklyQuest(
      id: 'weekly_reps',
      title: 'Rep Centurion',
      description: 'Crush 150 verified exercise repetitions this week',
      target: 150,
      unit: 'reps',
      rewardXp: 150,
      category: 'Strength',
    ),
    WeeklyQuest(
      id: 'weekly_meal_days',
      title: 'Nutrient Discipline',
      description: 'Log meals on at least 4 distinct days this week',
      target: 4,
      unit: 'days',
      rewardXp: 150,
      category: 'Nutrition',
    ),
    WeeklyQuest(
      id: 'weekly_active_minutes',
      title: 'Active Rush',
      description: 'Reach 120 total active minutes this week',
      target: 120,
      unit: 'minutes',
      rewardXp: 150,
      category: 'Activity',
    ),
  ];

  /// Configures a deterministic mock date for unit testing.
  void setMockCurrentDate(DateTime? date) {
    _mockDate = date;
  }

  /// Sets custom storage directory for test isolation.
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  /// Sets isolated [DailyStatsService] instance for testing.
  void setDailyStatsService(DailyStatsService? service) {
    detachDailyStatsListener();
    _customDailyStatsService = service;
    if (service != null) {
      attachDailyStatsListener(service);
    }
  }

  /// Sets isolated [GamificationService] instance for testing.
  void setGamificationService(GamificationService? service) {
    _customGamificationService = service;
  }

  /// Attaches listener to [DailyStatsService] to automatically recompute weekly quests.
  void attachDailyStatsListener([DailyStatsService? service]) {
    final target = service ?? _effectiveDailyStatsService;
    if (_currentlyAttachedDailyStatsService == target &&
        _dailyStatsListener != null) {
      return;
    }
    detachDailyStatsListener();
    _currentlyAttachedDailyStatsService = target;
    _dailyStatsListener = () {
      recomputeAndClaimRewards();
    };
    target.addListener(_dailyStatsListener!);
  }

  /// Detaches listener from [DailyStatsService].
  void detachDailyStatsListener() {
    if (_currentlyAttachedDailyStatsService != null &&
        _dailyStatsListener != null) {
      _currentlyAttachedDailyStatsService!.removeListener(_dailyStatsListener!);
      _currentlyAttachedDailyStatsService = null;
      _dailyStatsListener = null;
    }
  }

  /// Initializes the service from local storage and attaches listener.
  Future<void> init() async {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);

          if (data['claimedRewardKeys'] is List) {
            _claimedRewardKeys.clear();
            for (final k in data['claimedRewardKeys']) {
              if (k is String) _claimedRewardKeys.add(k);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('WeeklyQuestService init error: $e');
    } finally {
      _isInitialized = true;
      attachDailyStatsListener();
      await recomputeAndClaimRewards();
    }
  }

  /// Calculates real weekly progress for all quests strictly within [atDate]'s ISO week.
  List<WeeklyQuest> getQuestsForWeek({DateTime? atDate}) {
    final date = atDate ?? effectiveCurrentDate;
    final week = IsoWeek.fromDateTime(date);
    final dayKeys = week.dayDateKeys;
    final records = _effectiveDailyStatsService.allRecords;

    int totalWorkouts = 0;
    int totalSteps = 0;
    int totalReps = 0;
    int mealDays = 0;
    int totalActiveMinutes = 0;

    for (final dateKey in dayKeys) {
      final stat = records[dateKey];
      if (stat != null) {
        totalWorkouts += stat.workoutsCompleted;
        totalSteps += stat.steps;
        totalReps += stat.totalReps;
        if (stat.mealsLogged > 0) {
          mealDays += 1;
        }
        totalActiveMinutes += stat.activeMinutes;
      }
    }

    return defaultQuestsTemplate.map((template) {
      int current = 0;
      switch (template.id) {
        case 'weekly_workouts':
          current = totalWorkouts;
          break;
        case 'weekly_steps':
          current = totalSteps;
          break;
        case 'weekly_reps':
          current = totalReps;
          break;
        case 'weekly_meal_days':
          current = mealDays;
          break;
        case 'weekly_active_minutes':
          current = totalActiveMinutes;
          break;
      }

      final rewardKey = '${week.weekKey}:${template.id}';
      final isClaimed = _claimedRewardKeys.contains(rewardKey);

      return template.copyWith(
        current: current.clamp(0, template.target),
        isClaimed: isClaimed,
      );
    }).toList();
  }

  /// Whether a specific quest reward has been claimed for [weekKey].
  bool isQuestClaimed(String weekKey, String questId) {
    return _claimedRewardKeys.contains('$weekKey:$questId');
  }

  /// Recomputes weekly quest completion and awards XP with exact-once protection.
  ///
  /// Safe against race conditions and repeated invocations.
  Future<void> recomputeAndClaimRewards({DateTime? atDate}) async {
    final date = atDate ?? effectiveCurrentDate;
    final week = IsoWeek.fromDateTime(date);
    final quests = getQuestsForWeek(atDate: date);

    bool hasNewClaim = false;

    for (final q in quests) {
      if (q.isCompleted) {
        final rewardKey = '${week.weekKey}:${q.id}';

        // Guard against race conditions and duplicate payouts
        if (!_claimedRewardKeys.contains(rewardKey) &&
            !_pendingClaimKeys.contains(rewardKey)) {
          _pendingClaimKeys.add(rewardKey);
          try {
            _claimedRewardKeys.add(rewardKey);
            hasNewClaim = true;

            // Persist claim key immediately
            await _persist();

            // Award XP through GamificationService
            await _effectiveGamificationService.addXp(
              q.rewardXp,
              reason: 'Weekly Quest Completed: ${q.title} (${week.weekKey})',
            );
          } catch (e) {
            debugPrint('WeeklyQuestService error claiming $rewardKey: $e');
          } finally {
            _pendingClaimKeys.remove(rewardKey);
          }
        }
      }
    }

    if (hasNewClaim) {
      notifyListeners();
    }
  }

  /// Resets all claimed reward keys and state to empty defaults (essential for test isolation).
  Future<void> resetToDefaults() async {
    _claimedRewardKeys.clear();
    _pendingClaimKeys.clear();
    _mockDate = null;
    await _persist();
    notifyListeners();
  }

  // --- Persistence Engine ---

  File? _getExistingFileOrTarget() {
    if (_customStoragePath != null) {
      return File('$_customStoragePath/$_fileName');
    }
    return File(_fileName);
  }

  Future<void> _persist() async {
    try {
      final file = _getExistingFileOrTarget();
      if (file == null) return;

      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      final data = {
        'version': 1,
        'claimedRewardKeys': _claimedRewardKeys.toList(),
        'lastObservedWeekKey': currentWeekKey,
      };

      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('WeeklyQuestService _persist error: $e');
    }
  }
}
