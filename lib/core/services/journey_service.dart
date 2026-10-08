import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/journey/journey_destination.dart';

/// Central service managing the Odisha Fitness Journey foundation.
/// Tracks progress along the initial route: Bhubaneswar -> Cuttack -> Konark -> Puri.
class JourneyService extends ChangeNotifier {
  JourneyService._() {
    _resetDestinationsState();
  }

  static final JourneyService instance = JourneyService._();

  static const String _fileName = 'genfit_journey.json';

  String? _customStoragePath;
  bool _isInitialized = false;
  double _currentProgressKm = 0.0;

  late List<JourneyDestination> _destinations;

  bool get isInitialized => _isInitialized;
  double get currentProgressKm => _currentProgressKm;
  List<JourneyDestination> get destinations => List.unmodifiable(_destinations);

  /// Total distance across the complete journey route
  double get totalRouteDistanceKm =>
      _destinations.isNotEmpty ? _destinations.last.requiredProgress : 128.0;

  /// Overall journey progress percentage clamped to [0.0, 1.0]
  double get progressPercent => totalRouteDistanceKm > 0
      ? (_currentProgressKm / totalRouteDistanceKm).clamp(0.0, 1.0)
      : 0.0;

  /// The active destination the user is currently progressing toward
  JourneyDestination get currentDestination {
    final pending = _destinations.where((d) => !d.isCompleted).toList();
    if (pending.isNotEmpty) {
      return pending.first;
    }
    return _destinations.last;
  }

  /// The destination directly following the current active destination
  JourneyDestination? get nextDestination {
    final current = currentDestination;
    final currentIndex = _destinations.indexWhere((d) => d.id == current.id);
    if (currentIndex >= 0 && currentIndex + 1 < _destinations.length) {
      return _destinations[currentIndex + 1];
    }
    return null;
  }

  /// List of all milestones completed by the user
  List<JourneyDestination> get completedDestinations =>
      _destinations.where((d) => d.isCompleted).toList();

  /// List of all destinations currently unlocked for viewing or progress
  List<JourneyDestination> get unlockedDestinations =>
      _destinations.where((d) => d.isUnlocked).toList();

  /// Checks if a destination by ID is completed
  bool isDestinationCompleted(String id) {
    return _destinations.any((d) => d.id == id && d.isCompleted);
  }

  /// Checks if a destination by ID is unlocked
  bool isDestinationUnlocked(String id) {
    return _destinations.any((d) => d.id == id && d.isUnlocked);
  }

  /// Returns remaining distance in KM to reach a destination
  double distanceRemainingTo(String id) {
    try {
      final dest = _destinations.firstWhere((d) => d.id == id);
      final remaining = dest.requiredProgress - _currentProgressKm;
      return remaining > 0 ? double.parse(remaining.toStringAsFixed(1)) : 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Sets a custom storage directory path (essential for unit testing isolation)
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  /// Initial canonical milestones for the Odisha Cultural Trail
  static const List<JourneyDestination> initialDestinations = [
    JourneyDestination(
      id: 'dest_bhubaneswar',
      name: 'Bhubaneswar',
      shortDescription:
          'The Temple City: Starting point of your cultural fitness expedition',
      distanceKm: 0.0,
      requiredProgress: 0.0,
      visualIdentifier: 'temple_city',
      isUnlocked: true,
      isCompleted: true,
    ),
    JourneyDestination(
      id: 'dest_cuttack',
      name: 'Cuttack',
      shortDescription: 'The Silver City: Historic millennium city on the banks of the Mahanadi',
      distanceKm: 28.0,
      requiredProgress: 28.0,
      visualIdentifier: 'silver_city',
      isUnlocked: false,
      isCompleted: false,
    ),
    JourneyDestination(
      id: 'dest_konark',
      name: 'Konark',
      shortDescription: 'The Sun Temple: 13th-century UNESCO World Heritage monumental stone chariot',
      distanceKm: 65.0,
      requiredProgress: 93.0, // 28.0 + 65.0 = 93.0 km
      visualIdentifier: 'sun_temple',
      isUnlocked: false,
      isCompleted: false,
    ),
    JourneyDestination(
      id: 'dest_puri',
      name: 'Puri',
      shortDescription: 'The Holy Shore: Sacred coastal haven of Lord Jagannath and the iconic Golden Beach',
      distanceKm: 35.0,
      requiredProgress: 128.0, // 93.0 + 35.0 = 128.0 km
      visualIdentifier: 'golden_beach',
      isUnlocked: false,
      isCompleted: false,
    ),
  ];

  void _resetDestinationsState() {
    _destinations = initialDestinations.map((d) => d.copyWith()).toList();
    _recalculateDestinationStates();
  }

  /// Recalculates unlock and completion states based on current progress
  void _recalculateDestinationStates() {
    bool hasFoundActiveTarget = false;

    _destinations = _destinations.map((dest) {
      final isCompleted = _currentProgressKm >= dest.requiredProgress;

      bool isUnlocked = isCompleted;
      if (!isCompleted && !hasFoundActiveTarget) {
        // The first uncompleted destination is unlocked as the active target
        isUnlocked = true;
        hasFoundActiveTarget = true;
      }

      return dest.copyWith(isCompleted: isCompleted, isUnlocked: isUnlocked);
    }).toList();
  }

  /// Loads journey progress from local storage
  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data['currentProgressKm'] != null) {
            _currentProgressKm = (data['currentProgressKm'] as num).toDouble();
          }

          _resetDestinationsState();
        }
      } else {
        _resetDestinationsState();
      }
    } catch (e) {
      debugPrint('JourneyService init error: $e');
      _resetDestinationsState();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Adds progress in KM (e.g., from workouts, steps, or campus challenges)
  Future<void> addProgress(double distanceKm) async {
    if (distanceKm <= 0) return;
    _currentProgressKm = double.parse(
      (_currentProgressKm + distanceKm).toStringAsFixed(2),
    );
    _recalculateDestinationStates();
    await _persist();
    notifyListeners();
  }

  /// Sets absolute progress in KM
  Future<void> setProgress(double progressKm) async {
    _currentProgressKm = progressKm < 0
        ? 0.0
        : double.parse(progressKm.toStringAsFixed(2));
    _recalculateDestinationStates();
    await _persist();
    notifyListeners();
  }

  /// Manually marks a destination completed by advancing progress to its requiredProgress
  Future<void> completeDestination(String destinationId) async {
    final match = _destinations.where((d) => d.id == destinationId).toList();
    if (match.isNotEmpty) {
      final target = match.first;
      if (_currentProgressKm < target.requiredProgress) {
        _currentProgressKm = target.requiredProgress;
      }
      _recalculateDestinationStates();
      await _persist();
      notifyListeners();
    }
  }

  /// Resets journey progress to 0.0 and restores initial starting state
  Future<void> resetToDefaults() async {
    _currentProgressKm = 0.0;
    _resetDestinationsState();
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
          'currentProgressKm': _currentProgressKm,
          'completedDestinationIds': completedDestinations
              .map((d) => d.id)
              .toList(),
          'unlockedDestinationIds': unlockedDestinations
              .map((d) => d.id)
              .toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('JourneyService persist error: $e');
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
