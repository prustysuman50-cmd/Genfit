import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/heritage/heritage_journey.dart';
import '../../models/heritage/heritage_milestone.dart';
import 'daily_stats_service.dart';
import 'gamification_service.dart';

/// Central service managing Odisha Heritage Fitness Challenges.
///
/// Converts factual daily steps from [DailyStatsService] into virtual
/// distances across curated historical Odisha trails (e.g., Lingaraj Temple -> Konark).
/// Milestones and journey completion idempotently award XP and badges via [GamificationService].
class HeritageService extends ChangeNotifier {
  HeritageService._() {
    _initJourneys();
  }

  static final HeritageService instance = HeritageService._();

  static const String _fileName = 'genfit_heritage.json';

  /// Documented deterministic conversion: 1,000 steps = 1.0 virtual km (1 step = 1.0 m).
  static const int stepsPerVirtualKm = 1000;

  String? _customStoragePath;
  bool _isInitialized = false;

  String _activeJourneyId = HeritageJourney.showcaseLingarajToKonark.id;
  late List<HeritageJourney> _journeys;
  final Set<String> _awardedMilestoneIds = {};
  final Set<String> _awardedCompletionIds = {};

  DailyStatsService? _observedDailyStatsService;
  bool _isDailyStatsListenerAttached = false;

  bool get isInitialized => _isInitialized;
  String get activeJourneyId => _activeJourneyId;
  List<HeritageJourney> get journeys => List.unmodifiable(_journeys);
  Set<String> get awardedMilestoneIds => Set.unmodifiable(_awardedMilestoneIds);
  Set<String> get awardedCompletionIds =>
      Set.unmodifiable(_awardedCompletionIds);

  /// The active [HeritageJourney] currently being pursued by the user.
  HeritageJourney get activeJourney {
    final match = _journeys.where((j) => j.id == _activeJourneyId).toList();
    if (match.isNotEmpty) return match.first;
    return _journeys.first;
  }

  DailyStatsService get _statsService =>
      _observedDailyStatsService ?? DailyStatsService.instance;

  /// Cumulative steps across all persisted days in [DailyStatsService].
  int get totalSteps {
    final records = _statsService.allRecords;
    if (records.isNotEmpty) {
      return records.values.fold(0, (sum, stat) => sum + stat.steps);
    }
    return _statsService.todayStats.steps;
  }

  /// Today's step contribution from [DailyStatsService].
  int get todaySteps => _statsService.todayStats.steps;

  /// Today's step contribution converted to virtual km.
  double get todayContributionKm =>
      double.parse((todaySteps / stepsPerVirtualKm).toStringAsFixed(2));

  /// User's current virtual distance along the active route clamped to [0.0, totalDistanceKm].
  double get currentDistanceKm {
    final rawKm = totalSteps / stepsPerVirtualKm;
    final clamped = rawKm.clamp(0.0, activeJourney.totalDistanceKm);
    return double.parse(clamped.toStringAsFixed(2));
  }

  /// Total virtual distance of the active journey in km.
  double get totalRouteDistanceKm => activeJourney.totalDistanceKm;

  /// Percentage progress of the active journey clamped to [0.0, 1.0].
  double get progressPercent => totalRouteDistanceKm > 0
      ? (currentDistanceKm / totalRouteDistanceKm).clamp(0.0, 1.0)
      : 0.0;

  /// Returns true if the active journey has reached 100% completion.
  bool get isCompleted => currentDistanceKm >= activeJourney.totalDistanceKm;

  /// The active milestone the user is currently approaching.
  HeritageMilestone? get currentTargetMilestone {
    final pending = activeJourney.milestones
        .where((m) => currentDistanceKm < m.requiredDistanceKm)
        .toList();
    if (pending.isNotEmpty) return pending.first;
    return activeJourney.milestones.last;
  }

  /// The most recent milestone successfully unlocked/completed by the user.
  HeritageMilestone? get lastReachedMilestone {
    final reached = activeJourney.milestones
        .where((m) => currentDistanceKm >= m.requiredDistanceKm)
        .toList();
    if (reached.isNotEmpty) return reached.last;
    return activeJourney.milestones.first;
  }

  /// Returns remaining virtual distance to reach a milestone.
  double remainingDistanceTo(HeritageMilestone milestone) {
    final remaining = milestone.requiredDistanceKm - currentDistanceKm;
    return remaining > 0 ? double.parse(remaining.toStringAsFixed(2)) : 0.0;
  }

  /// Returns remaining steps to reach a milestone.
  int remainingStepsTo(HeritageMilestone milestone) {
    final km = remainingDistanceTo(milestone);
    return (km * stepsPerVirtualKm).round();
  }

  /// Sets a custom storage directory path (essential for unit testing isolation).
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  void _initJourneys() {
    _journeys = HeritageJourney.defaultJourneys.map((j) => j.copyWith()).toList();
    _syncMilestoneStatesOnly();
  }

  /// Initializes the service from local storage and attaches DailyStats listener.
  Future<void> init() async {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);

          if (data['activeJourneyId'] is String) {
            _activeJourneyId = data['activeJourneyId'] as String;
          }

          if (data['awardedMilestoneIds'] is List) {
            _awardedMilestoneIds.clear();
            for (final id in data['awardedMilestoneIds']) {
              if (id is String) _awardedMilestoneIds.add(id);
            }
          }

          if (data['awardedCompletionIds'] is List) {
            _awardedCompletionIds.clear();
            for (final id in data['awardedCompletionIds']) {
              if (id is String) _awardedCompletionIds.add(id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('HeritageService init error: $e');
    } finally {
      _isInitialized = true;
      attachDailyStatsListener();
      await _syncMilestonesAndRewards();
    }
  }

  /// Attaches an observer listener to [DailyStatsService] to automatically
  /// update journey progress whenever step counts change.
  void attachDailyStatsListener([DailyStatsService? service]) {
    final target = service ?? DailyStatsService.instance;
    if (_observedDailyStatsService != null && _isDailyStatsListenerAttached) {
      _observedDailyStatsService!.removeListener(_onDailyStatsChanged);
    }
    _observedDailyStatsService = target;
    target.addListener(_onDailyStatsChanged);
    _isDailyStatsListenerAttached = true;
  }

  /// Detaches the active [DailyStatsService] listener.
  void detachDailyStatsListener() {
    if (_observedDailyStatsService != null && _isDailyStatsListenerAttached) {
      _observedDailyStatsService!.removeListener(_onDailyStatsChanged);
      _isDailyStatsListenerAttached = false;
      _observedDailyStatsService = null;
    }
  }

  void _onDailyStatsChanged() {
    _syncMilestonesAndRewards();
  }

  /// Switches the active journey route.
  Future<void> setActiveJourney(String journeyId) async {
    if (_activeJourneyId != journeyId &&
        _journeys.any((j) => j.id == journeyId)) {
      _activeJourneyId = journeyId;
      await _syncMilestonesAndRewards();
    }
  }

  void _syncMilestoneStatesOnly() {
    final distance = currentDistanceKm;
    bool hasTargetAssigned = false;

    for (int jIndex = 0; jIndex < _journeys.length; jIndex++) {
      final journey = _journeys[jIndex];
      final isCurrentRoute = journey.id == _activeJourneyId;
      final routeDist = isCurrentRoute ? distance : 0.0;

      hasTargetAssigned = false;

      final updatedMilestones = journey.milestones.map((milestone) {
        final isCompleted = milestone.isReached(routeDist);
        bool isUnlocked = isCompleted;

        if (!isCompleted && !hasTargetAssigned && isCurrentRoute) {
          isUnlocked = true;
          hasTargetAssigned = true;
        }

        return milestone.copyWith(
          isCompleted: isCompleted,
          isUnlocked: isUnlocked,
        );
      }).toList();

      _journeys[jIndex] = journey.copyWith(milestones: updatedMilestones);
    }
  }

  /// Synchronizes milestone states, awards rewards idempotently, and updates UI.
  Future<void> syncMilestonesAndRewards() => _syncMilestonesAndRewards();

  Future<void> _syncMilestonesAndRewards() async {
    _syncMilestoneStatesOnly();

    // 2. Award milestone XP and badges strictly idempotently
    final active = activeJourney;
    for (final milestone in active.milestones) {
      if (milestone.isCompleted) {
        if (!_awardedMilestoneIds.contains(milestone.id)) {
          _awardedMilestoneIds.add(milestone.id);

          if (milestone.badgeId != null) {
            GamificationService.instance.unlockBadge(milestone.badgeId!);
          }

          if (milestone.rewardXp > 0) {
            await GamificationService.instance.recordJourneyMilestone(
              milestone.id,
            );
          }
        }
      }
    }

    // 3. Award journey completion reward strictly idempotently
    if (isCompleted && !_awardedCompletionIds.contains(active.id)) {
      _awardedCompletionIds.add(active.id);

      if (active.completionRewardXp > 0) {
        await GamificationService.instance.addXp(
          active.completionRewardXp,
          reason: 'Completed Heritage Trail: ${active.title}',
        );
      }

      if (active.completionBadgeId != null) {
        GamificationService.instance.unlockBadge(active.completionBadgeId!);
      }
    }

    _persistSync();
    notifyListeners();
  }

  /// Resets journey state to initial defaults (useful for testing or full user reset).
  Future<void> resetToDefaults() async {
    _activeJourneyId = HeritageJourney.showcaseLingarajToKonark.id;
    _awardedMilestoneIds.clear();
    _awardedCompletionIds.clear();
    _initJourneys();
    _persistSync();
    notifyListeners();
  }

  void _persistSync() {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }

        final Map<String, dynamic> data = {
          'activeJourneyId': _activeJourneyId,
          'awardedMilestoneIds': _awardedMilestoneIds.toList(),
          'awardedCompletionIds': _awardedCompletionIds.toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('HeritageService persist error: $e');
    }
  }

  File? _getExistingFileOrTarget() {
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
