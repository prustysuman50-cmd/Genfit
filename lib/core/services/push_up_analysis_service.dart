import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_detection_service.dart';

/// The two primary movement phases of a push-up repetition:
/// TOP (arms extended) and DOWN (arms bent).
enum PushUpState {
  /// In top plank position with arms extended.
  top,

  /// In down position with elbows bent significantly.
  down,
}

/// User-friendly display names for push-up movement states.
extension PushUpStateExtension on PushUpState {
  String get displayName {
    switch (this) {
      case PushUpState.top:
        return 'Top';
      case PushUpState.down:
        return 'Down';
    }
  }
}

/// Real-time diagnostic telemetry snapshot for the push-up detector.
class PushUpTelemetryData {
  final PushUpState state;
  final double? leftElbowAngle;
  final double? rightElbowAngle;
  final double? rawElbowAngle;
  final double? smoothedElbowAngle;
  final double? leftShoulderX;
  final double? leftShoulderY;
  final double? rightShoulderX;
  final double? rightShoulderY;
  final double? leftHipX;
  final double? leftHipY;
  final double? rightHipX;
  final double? rightHipY;
  final double? torsoLength;
  final double averageConfidence;
  final bool hasEstablishedTopPlank;
  final String blockingCondition;
  final String lastTransitionLog;
  final DateTime timestamp;

  const PushUpTelemetryData({
    required this.state,
    this.leftElbowAngle,
    this.rightElbowAngle,
    this.rawElbowAngle,
    this.smoothedElbowAngle,
    this.leftShoulderX,
    this.leftShoulderY,
    this.rightShoulderX,
    this.rightShoulderY,
    this.leftHipX,
    this.leftHipY,
    this.rightHipX,
    this.rightHipY,
    this.torsoLength,
    required this.averageConfidence,
    required this.hasEstablishedTopPlank,
    required this.blockingCondition,
    required this.lastTransitionLog,
    required this.timestamp,
  });

  factory PushUpTelemetryData.initial() => PushUpTelemetryData(
    state: PushUpState.top,
    averageConfidence: 0.0,
    hasEstablishedTopPlank: false,
    blockingCondition: 'Awaiting camera view & top plank setup',
    lastTransitionLog: 'INITIAL: Awaiting camera stream',
    timestamp: DateTime.now(),
  );
}

/// Active push-up thresholds currently in use.
class PushUpThresholds {
  final double topAngleThreshold;
  final double downAngleThreshold;
  final double bodyAlignmentThreshold;
  final double minLandmarkConfidence;
  final Duration minRepCooldown;

  const PushUpThresholds({
    required this.topAngleThreshold,
    required this.downAngleThreshold,
    required this.bodyAlignmentThreshold,
    required this.minLandmarkConfidence,
    required this.minRepCooldown,
  });
}

/// Simple, robust hackathon-MVP push-up detector.
///
/// Core logic:
/// TOP -> DOWN -> TOP = 1 REP
///
/// 1. TOP:
///    - Arms reasonably extended (elbowAngle >= topAngleThreshold).
///    - Body roughly aligned in plank (supporting check).
///    - Acceptable landmark confidence.
/// 2. DOWN:
///    - User bends elbows significantly (elbowAngle <= downAngleThreshold).
///    - Does not count yet.
/// 3. TOP:
///    - User extends elbows back to top position.
///    - Only upon returning to TOP from DOWN does rep count by +1 (with cooldown debounce).
class PushUpAnalysisService {
  /// Elbow angle threshold for extended top plank position (degrees).
  final double topAngleThreshold;

  /// Elbow angle threshold indicating down position (degrees).
  final double downAngleThreshold;

  /// Supporting body alignment threshold (degrees).
  final double bodyAlignmentThreshold;

  /// Smoothing factor (alpha) for Exponential Moving Average (0.0 < alpha <= 1.0).
  final double smoothingFactor;

  /// Minimum landmark confidence required (0.0 to 1.0).
  final double minLandmarkConfidence;

  /// Minimum duration between consecutive repetitions (debounce).
  final Duration minRepCooldown;

  /// Optional time provider for deterministic unit testing.
  final DateTime Function()? timeProvider;

  /// Optional callback invoked whenever a repetition is completed.
  void Function(int count)? onRepCompleted;

  /// Optional callback invoked whenever the push-up state transitions.
  void Function(PushUpState state)? onStateChanged;

  /// Optional callback invoked whenever form feedback changes.
  void Function(String feedback)? onFeedbackChanged;

  PushUpAnalysisService({
    this.topAngleThreshold = 150.0,
    double downAngleThreshold = 100.0,
    this.bodyAlignmentThreshold = 125.0,
    this.smoothingFactor = 0.50,
    this.minLandmarkConfidence = 0.35,
    this.minRepCooldown = const Duration(milliseconds: 800),
    this.timeProvider,
    this.onRepCompleted,
    this.onStateChanged,
    this.onFeedbackChanged,
    // Backwards-compatibility aliases for legacy parameters:
    double? bottomAngleThreshold,
    double? descendingAngleThreshold,
    double? returningAngleThreshold,
    double? minDepthThreshold,
    double? returnDepthThreshold,
    double? maxAngleSpike,
  }) : downAngleThreshold = bottomAngleThreshold ?? downAngleThreshold,
       assert(topAngleThreshold > (bottomAngleThreshold ?? downAngleThreshold)),
       assert(smoothingFactor > 0.0 && smoothingFactor <= 1.0);

  PushUpState _state = PushUpState.top;
  int _repCount = 0;
  double? _rawElbowAngle;
  double? _smoothedElbowAngle;
  double? _rawBodyAlignmentAngle;
  bool _hasEstablishedTop = false;
  DateTime? _lastRepTime;
  String _feedback = 'Get into position';

  // Telemetry variables
  double? _latestLeftElbowAngle;
  double? _latestRightElbowAngle;
  double? _latestLeftShoulderX;
  double? _latestLeftShoulderY;
  double? _latestRightShoulderX;
  double? _latestRightShoulderY;
  double? _latestLeftHipX;
  double? _latestLeftHipY;
  double? _latestRightHipX;
  double? _latestRightHipY;
  double? _latestTorsoLength;
  double _latestAvgConfidence = 0.0;
  String _lastTransitionLog = 'INITIAL: Awaiting camera stream';
  String _blockingCondition = 'Awaiting camera view & top plank setup';
  String? _previousLoggedTransition;

  final ValueNotifier<PushUpState> _stateNotifier = ValueNotifier<PushUpState>(
    PushUpState.top,
  );
  final ValueNotifier<int> _repCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _feedbackNotifier = ValueNotifier<String>(
    'Get into position',
  );
  final ValueNotifier<PushUpTelemetryData> _telemetryNotifier =
      ValueNotifier<PushUpTelemetryData>(PushUpTelemetryData.initial());

  // --- Public Getters ---

  /// Current movement state of the push-up (top or down).
  PushUpState get state => _state;

  /// Total number of completed repetitions.
  int get repCount => _repCount;

  /// Latest raw elbow angle before smoothing.
  double? get rawElbowAngle => _rawElbowAngle;

  /// Latest smoothed elbow angle after Exponential Moving Average (EMA).
  double? get smoothedElbowAngle => _smoothedElbowAngle;

  /// Latest raw body alignment angle (shoulder-hip-ankle).
  double? get rawBodyAlignmentAngle => _rawBodyAlignmentAngle;

  /// Whether the initial top plank position has been established.
  bool get hasEstablishedTop => _hasEstablishedTop;

  /// Alias for backwards compatibility.
  bool get hasEstablishedTopPlank => _hasEstablishedTop;

  /// Aliases for legacy threshold getters.
  double get bottomAngleThreshold => downAngleThreshold;
  double get descendingAngleThreshold =>
      (topAngleThreshold + downAngleThreshold) / 2.0;
  double get returningAngleThreshold =>
      (topAngleThreshold + downAngleThreshold) / 2.0;

  /// Current real-time form feedback message.
  String get feedback => _feedback;

  /// Notifier for listening to movement state changes.
  ValueNotifier<PushUpState> get stateNotifier => _stateNotifier;

  /// Notifier for listening to repetition count changes.
  ValueNotifier<int> get repCountNotifier => _repCountNotifier;

  /// Notifier for listening to real-time form feedback changes.
  ValueNotifier<String> get feedbackNotifier => _feedbackNotifier;

  /// Notifier for listening to real-time diagnostic telemetry stream.
  ValueNotifier<PushUpTelemetryData> get telemetryNotifier =>
      _telemetryNotifier;

  /// Current real-time diagnostic telemetry snapshot.
  PushUpTelemetryData get telemetry => _telemetryNotifier.value;

  /// Container exposing active push-up threshold values.
  PushUpThresholds get thresholds => PushUpThresholds(
    topAngleThreshold: topAngleThreshold,
    downAngleThreshold: downAngleThreshold,
    bodyAlignmentThreshold: bodyAlignmentThreshold,
    minLandmarkConfidence: minLandmarkConfidence,
    minRepCooldown: minRepCooldown,
  );

  // --- Landmark Extraction Helpers ---

  /// Robustly extracts the effective elbow angle from [PushUpLandmarks].
  ///
  /// Fixes selected-angle corruption:
  /// - Filters out physically implausible angles (< 45° or > 180°).
  /// - If both left and right arms are valid and reliable, computes their sensible average.
  /// - If one arm is low-confidence or corrupted, cleanly selects the reliable arm.
  double? extractElbowAngle(PushUpLandmarks landmarks) {
    final double? leftAngle = landmarks.leftElbowAngle;
    final double? rightAngle = landmarks.rightElbowAngle;

    final double leftConf = _armConfidence(
      landmarks.leftShoulder,
      landmarks.leftElbow,
      landmarks.leftWrist,
    );
    final double rightConf = _armConfidence(
      landmarks.rightShoulder,
      landmarks.rightElbow,
      landmarks.rightWrist,
    );

    final bool leftValid =
        leftAngle != null &&
        leftConf >= minLandmarkConfidence &&
        leftAngle >= 45.0 &&
        leftAngle <= 180.0;
    final bool rightValid =
        rightAngle != null &&
        rightConf >= minLandmarkConfidence &&
        rightAngle >= 45.0 &&
        rightAngle <= 180.0;

    if (leftValid && rightValid) {
      // Both arms reliable: robust average
      return (leftAngle + rightAngle) / 2.0;
    } else if (leftValid) {
      return leftAngle;
    } else if (rightValid) {
      return rightAngle;
    }

    // Fallback if confidence was borderline but valid angle exists
    if (leftAngle != null && rightAngle != null) {
      if (leftAngle >= 45.0 && rightAngle < 45.0) return leftAngle;
      if (rightAngle >= 45.0 && leftAngle < 45.0) return rightAngle;
      return (leftAngle + rightAngle) / 2.0;
    }
    return leftAngle ?? rightAngle;
  }

  /// Calculates average likelihood of arm keypoints.
  double _armConfidence(PoseLandmark? s, PoseLandmark? e, PoseLandmark? w) {
    if (s == null || e == null || w == null) return 0.0;
    return (s.likelihood + e.likelihood + w.likelihood) / 3.0;
  }

  /// Extracts the effective body alignment angle (shoulder-hip-ankle or knee).
  double? extractBodyAlignmentAngle(PushUpLandmarks landmarks) {
    final leftAngle = landmarks.leftBodyAlignmentAngle;
    final rightAngle = landmarks.rightBodyAlignmentAngle;

    if (leftAngle != null && rightAngle != null) {
      return (leftAngle + rightAngle) / 2.0;
    }
    return leftAngle ?? rightAngle;
  }

  /// Calculates the torso length (shoulder-to-hip distance) for diagnostics.
  double? extractTorsoLength(PushUpLandmarks landmarks) {
    final ls = landmarks.leftShoulder ?? landmarks.rightShoulder;
    final lh = landmarks.leftHip ?? landmarks.rightHip;
    if (ls == null || lh == null) return null;
    final dx = ls.x - lh.x;
    final dy = ls.y - lh.y;
    return (dx * dx + dy * dy > 0) ? (dx * dx + dy * dy) : null;
  }

  /// Extracts average confidence across all critical push-up landmarks.
  double extractAverageConfidence(PushUpLandmarks landmarks) {
    final keypoints = [
      landmarks.leftShoulder,
      landmarks.rightShoulder,
      landmarks.leftElbow,
      landmarks.rightElbow,
      landmarks.leftWrist,
      landmarks.rightWrist,
      landmarks.leftHip,
      landmarks.rightHip,
      landmarks.leftAnkle,
      landmarks.rightAnkle,
    ].whereType<PoseLandmark>().toList();

    if (keypoints.isEmpty) return 0.0;
    final sum = keypoints.fold<double>(0.0, (acc, lm) => acc + lm.likelihood);
    return sum / keypoints.length;
  }

  // --- Processing Methods ---

  /// Ingests a new set of [PushUpLandmarks] and updates state, rep counter, form feedback,
  /// and diagnostic telemetry.
  void processLandmarks(PushUpLandmarks? landmarks) {
    if (landmarks == null || !landmarks.hasSufficientPushUpPoints) {
      _updateFeedback('Move into camera view');
      _blockingCondition = 'Landmarks missing: Move full body into camera view';
      _lastTransitionLog = 'NO_LANDMARKS: Insufficient keypoints';
      _publishTelemetry();
      return;
    }

    final double avgConfidence = extractAverageConfidence(landmarks);
    _latestAvgConfidence = avgConfidence;

    if (avgConfidence < minLandmarkConfidence) {
      _updateFeedback('Move into camera view');
      _blockingCondition =
          'Low confidence: ${(avgConfidence * 100).toStringAsFixed(1)}% < ${(minLandmarkConfidence * 100).toStringAsFixed(0)}%';
      _lastTransitionLog =
          'LOW_CONFIDENCE: ${(avgConfidence * 100).toStringAsFixed(1)}%';
      _publishTelemetry();
      return;
    }

    _latestLeftElbowAngle = landmarks.leftElbowAngle;
    _latestRightElbowAngle = landmarks.rightElbowAngle;
    _latestLeftShoulderX = landmarks.leftShoulder?.x;
    _latestLeftShoulderY = landmarks.leftShoulder?.y;
    _latestRightShoulderX = landmarks.rightShoulder?.x;
    _latestRightShoulderY = landmarks.rightShoulder?.y;
    _latestLeftHipX = landmarks.leftHip?.x;
    _latestLeftHipY = landmarks.leftHip?.y;
    _latestRightHipX = landmarks.rightHip?.x;
    _latestRightHipY = landmarks.rightHip?.y;
    _latestTorsoLength = extractTorsoLength(landmarks);

    final double? rawElbow = extractElbowAngle(landmarks);
    if (rawElbow == null) {
      _updateFeedback('Move into camera view');
      _blockingCondition = 'Elbow angle could not be calculated';
      _lastTransitionLog = 'NO_ELBOW_ANGLE';
      _publishTelemetry();
      return;
    }

    final double? rawAlignment = extractBodyAlignmentAngle(landmarks);
    _rawBodyAlignmentAngle = rawAlignment;
    _rawElbowAngle = rawElbow;

    // Apply Exponential Moving Average (EMA) smoothing to elbow angle
    if (_smoothedElbowAngle == null) {
      _smoothedElbowAngle = rawElbow;
    } else {
      _smoothedElbowAngle =
          (_smoothedElbowAngle! * (1.0 - smoothingFactor)) +
          (rawElbow * smoothingFactor);
    }

    _processAngleInternal(
      _smoothedElbowAngle!,
      bodyAlignmentAngle: rawAlignment,
    );
  }

  /// Directly process an elbow angle (useful for testing, simulations, and unit tests).
  void processAngle(double elbowAngle, {double? bodyAlignmentAngle}) {
    _rawElbowAngle = elbowAngle;
    _rawBodyAlignmentAngle = bodyAlignmentAngle;
    _latestAvgConfidence = 1.0;

    if (_smoothedElbowAngle == null) {
      _smoothedElbowAngle = elbowAngle;
    } else {
      _smoothedElbowAngle =
          (_smoothedElbowAngle! * (1.0 - smoothingFactor)) +
          (elbowAngle * smoothingFactor);
    }

    _processAngleInternal(
      _smoothedElbowAngle!,
      bodyAlignmentAngle: bodyAlignmentAngle,
    );
  }

  /// Simple state machine: TOP -> DOWN -> TOP = 1 REP
  void _processAngleInternal(double angle, {double? bodyAlignmentAngle}) {
    // 1. Supporting body alignment check
    final bool isBodyMisaligned =
        bodyAlignmentAngle != null &&
        bodyAlignmentAngle < bodyAlignmentThreshold;

    if (isBodyMisaligned) {
      _updateFeedback('Keep your body aligned');
    }

    // 2. Initial TOP position setup requirement
    // Arms extended with reasonable body posture
    final bool isInTopStance =
        angle >= topAngleThreshold &&
        (bodyAlignmentAngle == null ||
            bodyAlignmentAngle >= (bodyAlignmentThreshold - 10.0));

    if (isInTopStance) {
      _hasEstablishedTop = true;
    }

    if (!_hasEstablishedTop) {
      if (!isBodyMisaligned) {
        _updateFeedback('Get into position');
      }
      _blockingCondition =
          'Top plank not established. Extend arms (>= ${topAngleThreshold.toStringAsFixed(0)}°) to start.';
      _lastTransitionLog = 'TOP -> DOWN: WAITING (Awaiting top position)';
      _publishTelemetry();
      return;
    }

    // 3. Simple State Machine Transitions
    // Cycle: TOP -> DOWN -> TOP = 1 REP
    switch (_state) {
      case PushUpState.top:
        if (angle <= downAngleThreshold) {
          _updateState(PushUpState.down);
          _lastTransitionLog =
              'TOP -> DOWN: ACCEPTED (Elbow ${angle.toStringAsFixed(1)}° <= ${downAngleThreshold.toStringAsFixed(1)}°)';
          _blockingCondition =
              'In DOWN position. Push back up to top (>= ${topAngleThreshold.toStringAsFixed(1)}°)';
        } else {
          _lastTransitionLog =
              'TOP -> DOWN: WAITING (Elbow ${angle.toStringAsFixed(1)}° > ${downAngleThreshold.toStringAsFixed(1)}°)';
          _blockingCondition =
              'In TOP position. Bend elbows <= ${downAngleThreshold.toStringAsFixed(1)}° (current: ${angle.toStringAsFixed(1)}°)';
        }
        break;

      case PushUpState.down:
        if (angle >= topAngleThreshold) {
          _lastTransitionLog =
              'DOWN -> TOP: ACCEPTED (Elbow ${angle.toStringAsFixed(1)}° >= ${topAngleThreshold.toStringAsFixed(1)}°)';
          _blockingCondition = 'Rep completed! Ready for next rep.';
          _handleRepCompletion();
        } else {
          _lastTransitionLog =
              'DOWN -> TOP: WAITING (Elbow ${angle.toStringAsFixed(1)}° < ${topAngleThreshold.toStringAsFixed(1)}°)';
          _blockingCondition =
              'In DOWN position. Push up to top >= ${topAngleThreshold.toStringAsFixed(1)}° (current: ${angle.toStringAsFixed(1)}°)';
        }
        break;
    }

    _publishTelemetry();

    // 4. Form feedback
    if (isBodyMisaligned) {
      _updateFeedback('Keep your body aligned');
    } else {
      switch (_state) {
        case PushUpState.top:
          if (_repCount > 0) {
            _updateFeedback('Good rep');
          } else {
            _updateFeedback('Ready');
          }
          break;

        case PushUpState.down:
          _updateFeedback('Push up');
          break;
      }
    }
  }

  /// Publishes updated telemetry to the telemetryNotifier and logs transitions.
  void _publishTelemetry() {
    _telemetryNotifier.value = PushUpTelemetryData(
      state: _state,
      leftElbowAngle: _latestLeftElbowAngle,
      rightElbowAngle: _latestRightElbowAngle,
      rawElbowAngle: _rawElbowAngle,
      smoothedElbowAngle: _smoothedElbowAngle,
      leftShoulderX: _latestLeftShoulderX,
      leftShoulderY: _latestLeftShoulderY,
      rightShoulderX: _latestRightShoulderX,
      rightShoulderY: _latestRightShoulderY,
      leftHipX: _latestLeftHipX,
      leftHipY: _latestLeftHipY,
      rightHipX: _latestRightHipX,
      rightHipY: _latestRightHipY,
      torsoLength: _latestTorsoLength,
      averageConfidence: _latestAvgConfidence,
      hasEstablishedTopPlank: _hasEstablishedTop,
      blockingCondition: _blockingCondition,
      lastTransitionLog: _lastTransitionLog,
      timestamp: _now(),
    );

    if (_previousLoggedTransition != _lastTransitionLog) {
      _previousLoggedTransition = _lastTransitionLog;
      debugPrint(
        '[PUSHUP TELEMETRY] $_lastTransitionLog | Blocking: $_blockingCondition',
      );
    }
  }

  /// Finalizes rep completion with cooldown debouncing.
  void _handleRepCompletion() {
    final now = _now();
    final bool isDebounced =
        _lastRepTime != null && now.difference(_lastRepTime!) < minRepCooldown;

    if (!isDebounced) {
      _repCount++;
      _lastRepTime = now;
      _repCountNotifier.value = _repCount;
      onRepCompleted?.call(_repCount);
    }

    _updateState(PushUpState.top);
    _updateFeedback('Good rep');
  }

  void _updateState(PushUpState newState) {
    if (_state != newState) {
      _state = newState;
      _stateNotifier.value = newState;
      onStateChanged?.call(newState);
    }
  }

  void _updateFeedback(String newFeedback) {
    if (_feedback != newFeedback) {
      _feedback = newFeedback;
      _feedbackNotifier.value = newFeedback;
      onFeedbackChanged?.call(newFeedback);
    }
  }

  DateTime _now() => timeProvider != null ? timeProvider!() : DateTime.now();

  /// Manually increments the rep count (e.g. for simulation/demo).
  void incrementRep() {
    _repCount++;
    _repCountNotifier.value = _repCount;
    _updateFeedback('Good rep');
    onRepCompleted?.call(_repCount);
  }

  /// Resets rep counter, movement state, smoothing history, form feedback, and telemetry.
  void reset() {
    _state = PushUpState.top;
    _stateNotifier.value = PushUpState.top;
    _repCount = 0;
    _repCountNotifier.value = 0;
    _smoothedElbowAngle = null;
    _rawElbowAngle = null;
    _rawBodyAlignmentAngle = null;
    _hasEstablishedTop = false;
    _lastRepTime = null;
    _latestLeftElbowAngle = null;
    _latestRightElbowAngle = null;
    _latestLeftShoulderX = null;
    _latestLeftShoulderY = null;
    _latestRightShoulderX = null;
    _latestRightShoulderY = null;
    _latestLeftHipX = null;
    _latestLeftHipY = null;
    _latestRightHipX = null;
    _latestRightHipY = null;
    _latestTorsoLength = null;
    _latestAvgConfidence = 0.0;
    _lastTransitionLog = 'RESET: Awaiting camera stream';
    _blockingCondition = 'Awaiting camera view & top plank establishment';
    _previousLoggedTransition = null;
    _telemetryNotifier.value = PushUpTelemetryData.initial();
    _updateFeedback('Get into position');
  }

  /// Disposes internal ValueNotifiers.
  void dispose() {
    _stateNotifier.dispose();
    _repCountNotifier.dispose();
    _feedbackNotifier.dispose();
    _telemetryNotifier.dispose();
  }
}
