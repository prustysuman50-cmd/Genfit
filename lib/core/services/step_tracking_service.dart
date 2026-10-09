import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/daily_stats.dart';
import 'daily_stats_service.dart';

/// Tracking mode for student step monitoring.
enum StepTrackingMode {
  /// Default mode: steps are exclusively collected by the phone hardware step sensor.
  liveSensor,

  /// Controlled simulation mode: used strictly for hackathon testing/demonstrations.
  demoSimulation;

  String get displayName {
    switch (this) {
      case StepTrackingMode.liveSensor:
        return 'Live Sensor';
      case StepTrackingMode.demoSimulation:
        return 'Demo Mode';
    }
  }
}

/// Status of the native step sensor and permissions.
enum StepSensorStatus {
  uninitialized,
  permissionPending,
  permissionGranted,
  permissionDenied,
  permissionPermanentlyDenied,
  sensorUnavailable,
  tracking,
  error,
}

/// Central service managing real hardware step tracking on Android devices.
///
/// It translates raw hardware sensor readings (cumulative steps since device boot)
/// into an accurate daily step count using persisted baselines and reboot detection,
/// then idempotently updates [DailyStatsService.instance.updateActivity].
class StepTrackingService extends ChangeNotifier {
  StepTrackingService._();

  static final StepTrackingService instance = StepTrackingService._();

  static const String _fileName = 'genfit_step_tracker.json';

  String? _customStoragePath;
  bool _isInitialized = false;
  bool _enablePlatformSensor = true;

  StreamSubscription<StepCount>? _stepSubscription;

  StepTrackingMode _currentMode = StepTrackingMode.liveSensor;
  StepSensorStatus _sensorStatus = StepSensorStatus.uninitialized;
  bool _isSensorAvailable = true;
  bool _isPermissionGranted = false;
  String? _statusMessage;

  String? _trackingDate;
  int? _dayStartBaseline;
  int? _lastRawSensorValue;
  int _rebootPreservedSteps = 0;
  int _todayTrackedSteps = 0;
  int _demoAccumulatedSteps = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  StepTrackingMode get currentMode => _currentMode;
  StepSensorStatus get sensorStatus => _sensorStatus;
  bool get isSensorAvailable => _isSensorAvailable;
  bool get isPermissionGranted => _isPermissionGranted;
  bool get isTrackingActive =>
      _isInitialized &&
      _sensorStatus == StepSensorStatus.tracking &&
      _currentMode == StepTrackingMode.liveSensor;

  int get todayTrackedSteps => _todayTrackedSteps;
  int? get dayStartBaseline => _dayStartBaseline;
  int? get lastRawSensorValue => _lastRawSensorValue;
  int get rebootPreservedSteps => _rebootPreservedSteps;
  int get demoAccumulatedSteps => _demoAccumulatedSteps;
  String? get trackingDate => _trackingDate;
  String? get statusMessage => _statusMessage;

  /// Custom storage path for isolated unit tests.
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  /// Enables or disables listening to native platform sensor streams (useful for tests).
  void setPlatformSensorEnabled(bool enabled) {
    _enablePlatformSensor = enabled;
  }

  /// Initializes persisted tracking state and starts the hardware sensor stream if enabled.
  Future<void> init() async {
    await _loadPersistedState();

    if (!_enablePlatformSensor || (!Platform.isAndroid && !Platform.isIOS)) {
      _isInitialized = true;
      _statusMessage ??=
          'Platform step sensor not active in this environment.';
      notifyListeners();
      return;
    }

    await _checkPermissionAndStartSensor();
    _isInitialized = true;
    notifyListeners();
  }

  /// Requests ACTIVITY_RECOGNITION runtime permission and initializes sensor stream.
  Future<void> _checkPermissionAndStartSensor() async {
    try {
      _sensorStatus = StepSensorStatus.permissionPending;

      final status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        _isPermissionGranted = true;
        _sensorStatus = StepSensorStatus.permissionGranted;
        _startSensorStream();
      } else if (status.isPermanentlyDenied) {
        _isPermissionGranted = false;
        _sensorStatus = StepSensorStatus.permissionPermanentlyDenied;
        _statusMessage =
            'Physical activity permission is permanently denied. Enable in Settings.';
      } else {
        _isPermissionGranted = false;
        _sensorStatus = StepSensorStatus.permissionDenied;
        _statusMessage = 'Physical activity permission is required for step counting.';
      }
    } catch (e) {
      debugPrint('StepTrackingService permission error: $e');
      _sensorStatus = StepSensorStatus.error;
      _statusMessage = 'Error checking permissions: $e';
    }
  }

  void _startSensorStream() {
    if (_stepSubscription != null) return;

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onSensorEvent,
        onError: _onSensorError,
        cancelOnError: false,
      );
      _sensorStatus = StepSensorStatus.tracking;
      _isSensorAvailable = true;
      _statusMessage = 'Live step sensor active.';
    } catch (e) {
      debugPrint('StepTrackingService stream error: $e');
      _isSensorAvailable = false;
      _sensorStatus = StepSensorStatus.sensorUnavailable;
      _statusMessage = 'Step counter sensor unavailable on this device.';
    }
  }

  void _onSensorEvent(StepCount event) {
    processRawSensorReading(event.steps, now: event.timeStamp);
  }

  void _onSensorError(dynamic error) {
    debugPrint('Pedometer sensor error: $error');
    _isSensorAvailable = false;
    _sensorStatus = StepSensorStatus.sensorUnavailable;
    _statusMessage = 'Hardware step sensor unavailable on this device.';
    notifyListeners();
  }

  /// Processes a raw sensor reading from Android's TYPE_STEP_COUNTER.
  ///
  /// The reading represents total steps taken since device boot.
  /// This method:
  /// 1. Detects calendar-day rollovers and re-anchors the day-start baseline.
  /// 2. Detects device reboots (reading < previous reading) and preserves accumulated steps.
  /// 3. Computes the current day's total steps.
  /// 4. Pushes the result to [DailyStatsService.updateActivity] (steps ONLY).
  Future<int> processRawSensorReading(
    int rawSensorSteps, {
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final todayKey = DailyStats.formatDate(effectiveNow);

    // 1. Calendar Day Rollover or First Run
    if (_trackingDate != todayKey) {
      _trackingDate = todayKey;
      _dayStartBaseline = rawSensorSteps;
      _lastRawSensorValue = rawSensorSteps;
      _rebootPreservedSteps = 0;
      _demoAccumulatedSteps = 0;
      _todayTrackedSteps = 0;
    } else {
      // 2. Same calendar day: check for device reboot
      final lastVal = _lastRawSensorValue ?? rawSensorSteps;
      if (rawSensorSteps < lastVal) {
        // Device rebooted: sensor counter reset to zero or a lower count
        final accumulatedBeforeReboot =
            ((_lastRawSensorValue ?? 0) - (_dayStartBaseline ?? 0)).clamp(0, 1000000);
        _rebootPreservedSteps += accumulatedBeforeReboot;
        _dayStartBaseline = rawSensorSteps;
        _lastRawSensorValue = rawSensorSteps;
      } else {
        // Normal monotonic increase
        _dayStartBaseline ??= rawSensorSteps;
        _lastRawSensorValue = rawSensorSteps;
      }

      final currentDelta =
          (rawSensorSteps - (_dayStartBaseline ?? rawSensorSteps)).clamp(0, 1000000);
      _todayTrackedSteps = currentDelta + _rebootPreservedSteps;
    }

    _lastRawSensorValue = rawSensorSteps;

    // 3. In Live Sensor Mode, push to DailyStatsService (STEPS ONLY, NO CALORIES)
    if (_currentMode == StepTrackingMode.liveSensor) {
      await DailyStatsService.instance.updateActivity(
        steps: _todayTrackedSteps,
        date: effectiveNow,
      );
    }

    await _persist();
    notifyListeners();
    return _todayTrackedSteps;
  }

  /// Switches tracking mode between [StepTrackingMode.liveSensor] and [StepTrackingMode.demoSimulation].
  Future<void> setMode(StepTrackingMode mode) async {
    if (_currentMode != mode) {
      _currentMode = mode;
      if (mode == StepTrackingMode.demoSimulation) {
        // Seed demo count from existing today stats
        _demoAccumulatedSteps = DailyStatsService.instance.todayStats.steps;
        _statusMessage = 'Demo Simulation Mode Active (Manual increments allowed).';
      } else {
        _statusMessage = 'Live Sensor Mode Active (Hardware sensor is source of truth).';
        // Immediately re-push sensor count if available
        if (_todayTrackedSteps > 0) {
          await DailyStatsService.instance.updateActivity(
            steps: _todayTrackedSteps,
          );
        }
      }
      await _persist();
      notifyListeners();
    }
  }

  /// Injects simulated steps during hackathon testing or emulator runs.
  ///
  /// Rejects injection when in [StepTrackingMode.liveSensor] mode.
  Future<bool> injectDemoSteps(int stepsToAdd, {DateTime? date}) async {
    if (_currentMode != StepTrackingMode.demoSimulation) {
      debugPrint(
        'StepTrackingService: Manual step injection rejected because Live Sensor Mode is active.',
      );
      return false;
    }

    if (stepsToAdd <= 0) return true;

    final targetDate = date ?? DateTime.now();
    final todayKey = DailyStats.formatDate(targetDate);

    if (_trackingDate != todayKey) {
      _trackingDate = todayKey;
      _demoAccumulatedSteps = 0;
    }

    _demoAccumulatedSteps += stepsToAdd;
    _todayTrackedSteps = _demoAccumulatedSteps;

    // Push simulated steps to DailyStatsService (steps ONLY)
    await DailyStatsService.instance.updateActivity(
      steps: _demoAccumulatedSteps,
      date: targetDate,
    );

    await _persist();
    notifyListeners();
    return true;
  }

  /// Resets state to clean defaults (for unit tests / demo reset).
  Future<void> resetToDefaults() async {
    if (_stepSubscription != null) {
      await _stepSubscription!.cancel();
      _stepSubscription = null;
    }

    _currentMode = StepTrackingMode.liveSensor;
    _sensorStatus = StepSensorStatus.uninitialized;
    _isSensorAvailable = true;
    _isPermissionGranted = false;
    _statusMessage = null;

    _trackingDate = null;
    _dayStartBaseline = null;
    _lastRawSensorValue = null;
    _rebootPreservedSteps = 0;
    _todayTrackedSteps = 0;
    _demoAccumulatedSteps = 0;

    await _persist();
    notifyListeners();
  }

  // --- Persistence Logic ---

  Future<void> _loadPersistedState() async {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);

          _trackingDate = data['trackingDate'] as String?;
          _dayStartBaseline = data['dayStartBaseline'] as int?;
          _lastRawSensorValue = data['lastRawSensorValue'] as int?;
          _rebootPreservedSteps = (data['rebootPreservedSteps'] as int?) ?? 0;
          _demoAccumulatedSteps = (data['demoAccumulatedSteps'] as int?) ?? 0;
          _todayTrackedSteps = (data['todayTrackedSteps'] as int?) ?? 0;

          final modeStr = data['currentMode'] as String?;
          if (modeStr == 'demoSimulation') {
            _currentMode = StepTrackingMode.demoSimulation;
          } else {
            _currentMode = StepTrackingMode.liveSensor;
          }

          if (data['isSensorAvailable'] is bool) {
            _isSensorAvailable = data['isSensorAvailable'] as bool;
          }
        }
      }
    } catch (e) {
      debugPrint('StepTrackingService load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }

        final Map<String, dynamic> data = {
          'trackingDate': _trackingDate,
          'dayStartBaseline': _dayStartBaseline,
          'lastRawSensorValue': _lastRawSensorValue,
          'rebootPreservedSteps': _rebootPreservedSteps,
          'demoAccumulatedSteps': _demoAccumulatedSteps,
          'todayTrackedSteps': _todayTrackedSteps,
          'currentMode': _currentMode.name,
          'isSensorAvailable': _isSensorAvailable,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('StepTrackingService persist error: $e');
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

  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }
}
