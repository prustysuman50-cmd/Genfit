import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_detection_service.dart';

/// The distinct phases / movement states of a squat repetition.
enum SquatState {
  /// Standing upright with straight or nearly straight legs.
  standing,

  /// Bending knees and lowering body downward.
  descending,

  /// Reached full squat depth (inflection point).
  bottom,

  /// Extending knees and rising upward back to standing.
  returning,
}

/// User-friendly display names for squat movement states.
extension SquatStateExtension on SquatState {
  String get displayName {
    switch (this) {
      case SquatState.standing:
        return 'Standing';
      case SquatState.descending:
        return 'Descending';
      case SquatState.bottom:
        return 'Bottom position';
      case SquatState.returning:
        return 'Returning to standing';
    }
  }
}

/// Modular service responsible for detecting squat movement states,
/// counting completed repetitions, and providing real-time form feedback
/// using detected body landmarks and joint angles.
///
/// Cycle required for 1 repetition:
/// `standing` -> `descending` -> `bottom` -> `returning` -> `standing`
///
/// Form Feedback Rules:
/// 1. SQUAT DEPTH:
///    - "Go a little lower": When descending but has not reached bottom depth
///    - "Good depth": When appropriate squat depth is achieved (knee angle <= bottomAngleThreshold)
/// 2. FULL STAND:
///    - "Stand fully": When returning upward before reaching upright standing
///    - "Good rep": Upon completing full return to standing
/// 3. BODY POSITION / VISIBILITY:
///    - "Move into camera view": When required landmarks are not reliably visible
///    - "Keep your full body visible": When only partial body landmarks are visible
/// 4. BASIC STABILITY:
///    - "Keep your movement controlled": When landmark positions or joint angles fluctuate significantly
class SquatAnalysisService {
  /// Upright knee angle threshold (degrees).
  final double standingAngleThreshold;

  /// Knee angle below which descent is detected (degrees).
  final double descendingAngleThreshold;

  /// Knee angle indicating squat depth / bottom position (degrees).
  final double bottomAngleThreshold;

  /// Knee angle above which return / ascent is detected (degrees).
  final double returningAngleThreshold;

  /// Smoothing factor (alpha) for Exponential Moving Average (0.0 < alpha <= 1.0).
  final double smoothingFactor;

  /// Minimum duration between consecutive repetitions (cooldown debounce).
  final Duration minRepCooldown;

  /// Threshold for detecting angular movement fluctuation / instability (degrees).
  final double instabilityAngleDelta;

  /// Threshold for detecting lateral landmark shift instability (pixels).
  final double lateralInstabilityDelta;

  /// Optional time provider for deterministic unit testing.
  final DateTime Function()? timeProvider;

  /// Optional callback invoked whenever a repetition is completed.
  void Function(int count)? onRepCompleted;

  /// Optional callback invoked whenever the squat state transitions.
  void Function(SquatState state)? onStateChanged;

  /// Optional callback invoked whenever form feedback changes.
  void Function(String feedback)? onFeedbackChanged;

  SquatAnalysisService({
    this.standingAngleThreshold = 160.0,
    this.descendingAngleThreshold = 145.0,
    this.bottomAngleThreshold = 105.0,
    this.returningAngleThreshold = 115.0,
    this.smoothingFactor = 0.45,
    this.minRepCooldown = const Duration(milliseconds: 800),
    this.instabilityAngleDelta = 15.0,
    this.lateralInstabilityDelta = 30.0,
    this.timeProvider,
    this.onRepCompleted,
    this.onStateChanged,
    this.onFeedbackChanged,
  }) : assert(standingAngleThreshold > descendingAngleThreshold),
       assert(descendingAngleThreshold > returningAngleThreshold),
       assert(returningAngleThreshold > bottomAngleThreshold),
       assert(smoothingFactor > 0.0 && smoothingFactor <= 1.0);

  SquatState _state = SquatState.standing;
  int _repCount = 0;
  double? _rawKneeAngle;
  double? _smoothedKneeAngle;
  double? _previousRawAngle;
  PoseLandmark? _previousKnee;
  DateTime? _lastRepTime;
  String _feedback = 'Ready';

  final ValueNotifier<SquatState> _stateNotifier = ValueNotifier<SquatState>(
    SquatState.standing,
  );
  final ValueNotifier<int> _repCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _feedbackNotifier = ValueNotifier<String>(
    'Ready',
  );

  // --- Public Getters ---

  /// Current movement state of the squat.
  SquatState get state => _state;

  /// Total number of completed repetitions.
  int get repCount => _repCount;

  /// Latest raw knee angle before smoothing.
  double? get rawKneeAngle => _rawKneeAngle;

  /// Latest smoothed knee angle after Exponential Moving Average (EMA).
  double? get smoothedKneeAngle => _smoothedKneeAngle;

  /// Current real-time form feedback message.
  String get feedback => _feedback;

  /// Notifier for listening to movement state changes.
  ValueNotifier<SquatState> get stateNotifier => _stateNotifier;

  /// Notifier for listening to repetition count changes.
  ValueNotifier<int> get repCountNotifier => _repCountNotifier;

  /// Notifier for listening to real-time form feedback changes.
  ValueNotifier<String> get feedbackNotifier => _feedbackNotifier;

  // --- Processing Methods ---

  /// Extracts the effective knee angle from the provided [SquatLandmarks].
  ///
  /// If both legs are visible, uses the average of both knee angles to reduce noise.
  /// If only one leg is visible (e.g. side profile view), uses that leg's knee angle.
  /// Returns `null` if neither leg has sufficient keypoints.
  double? extractKneeAngle(SquatLandmarks landmarks) {
    final leftAngle = landmarks.leftKneeAngle;
    final rightAngle = landmarks.rightKneeAngle;

    if (leftAngle != null && rightAngle != null) {
      return (leftAngle + rightAngle) / 2.0;
    }
    return leftAngle ?? rightAngle;
  }

  /// Ingests a new set of [SquatLandmarks] and updates state, rep counter, and form feedback.
  void processLandmarks(SquatLandmarks? landmarks) {
    if (landmarks == null || !landmarks.hasSufficientSquatPoints) {
      _updateFeedback('Move into camera view');
      return;
    }

    // Check if partial visibility while standing
    if (_state == SquatState.standing &&
        (!landmarks.hasLeftLeg || !landmarks.hasRightLeg)) {
      _updateFeedback('Keep your full body visible');
    }

    // Check lateral landmark stability
    final currentKnee = landmarks.leftKnee ?? landmarks.rightKnee;
    bool isLaterallyUnstable = false;
    if (_previousKnee != null && currentKnee != null) {
      final dx = (currentKnee.x - _previousKnee!.x).abs();
      if (dx >= lateralInstabilityDelta) {
        isLaterallyUnstable = true;
      }
    }
    _previousKnee = currentKnee;

    final double? rawAngle = extractKneeAngle(landmarks);
    if (rawAngle == null) {
      _updateFeedback('Move into camera view');
      return;
    }

    _rawKneeAngle = rawAngle;

    // Apply Exponential Moving Average (EMA) smoothing
    if (_smoothedKneeAngle == null) {
      _smoothedKneeAngle = rawAngle;
    } else {
      _smoothedKneeAngle =
          (_smoothedKneeAngle! * (1.0 - smoothingFactor)) +
          (rawAngle * smoothingFactor);
    }

    _processAngleInternal(
      _smoothedKneeAngle!,
      isLaterallyUnstable: isLaterallyUnstable,
    );
  }

  /// Directly process a knee angle (useful for testing and simulations).
  void processAngle(double angle) {
    _rawKneeAngle = angle;
    if (_smoothedKneeAngle == null) {
      _smoothedKneeAngle = angle;
    } else {
      _smoothedKneeAngle =
          (_smoothedKneeAngle! * (1.0 - smoothingFactor)) +
          (angle * smoothingFactor);
    }
    _processAngleInternal(_smoothedKneeAngle!);
  }

  /// Internal state machine transitions and form feedback evaluation.
  void _processAngleInternal(double angle, {bool isLaterallyUnstable = false}) {
    // 1. Check for angular instability / fluctuation during movement
    bool isAngleUnstable = false;
    if (_previousRawAngle != null) {
      final double delta = angle - _previousRawAngle!;
      // Descending should be decreasing. A large positive delta is an upward wobble.
      if (_state == SquatState.descending && delta >= instabilityAngleDelta) {
        isAngleUnstable = true;
      }
      // Returning should be increasing. A large negative delta is a downward wobble.
      else if (_state == SquatState.returning &&
          delta <= -instabilityAngleDelta) {
        isAngleUnstable = true;
      }
    }

    final bool isUnstable = isLaterallyUnstable || isAngleUnstable;

    // 2. Perform state machine transitions
    switch (_state) {
      case SquatState.standing:
        if (angle < descendingAngleThreshold) {
          _updateState(SquatState.descending);
        }
        break;

      case SquatState.descending:
        if (angle <= bottomAngleThreshold) {
          _updateState(SquatState.bottom);
        } else if (angle >= standingAngleThreshold) {
          // Aborted descent: returned to standing without reaching bottom depth
          _updateState(SquatState.standing);
        }
        break;

      case SquatState.bottom:
        if (angle > returningAngleThreshold) {
          _updateState(SquatState.returning);
        }
        break;

      case SquatState.returning:
        if (angle <= bottomAngleThreshold) {
          // Re-sank to bottom before completing full ascent
          _updateState(SquatState.bottom);
        } else if (angle >= standingAngleThreshold) {
          // Complete cycle achieved: standing -> descending -> bottom -> returning -> standing
          _handleRepCompletion();
        }
        break;
    }

    // 3. Evaluate real-time form feedback
    if (isUnstable) {
      _updateFeedback('Keep your movement controlled');
    } else {
      switch (_state) {
        case SquatState.descending:
          if (angle <= bottomAngleThreshold) {
            _updateFeedback('Good depth');
          } else {
            _updateFeedback('Go a little lower');
          }
          break;

        case SquatState.bottom:
          _updateFeedback('Good depth');
          break;

        case SquatState.returning:
          if (angle >= standingAngleThreshold) {
            _updateFeedback('Good rep');
          } else {
            _updateFeedback('Stand fully');
          }
          break;

        case SquatState.standing:
          if (_repCount > 0) {
            _updateFeedback('Good rep');
          } else if (_feedback == 'Move into camera view' ||
              _feedback == 'Keep your full body visible') {
            // Keep visibility prompt active
          } else {
            _updateFeedback('Ready');
          }
          break;
      }
    }

    _previousRawAngle = angle;
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

    _updateState(SquatState.standing);
    _updateFeedback('Good rep');
  }

  void _updateState(SquatState newState) {
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

  /// Resets rep counter, movement state, smoothing history, and form feedback.
  void reset() {
    _state = SquatState.standing;
    _stateNotifier.value = SquatState.standing;
    _repCount = 0;
    _repCountNotifier.value = 0;
    _smoothedKneeAngle = null;
    _rawKneeAngle = null;
    _previousRawAngle = null;
    _previousKnee = null;
    _lastRepTime = null;
    _updateFeedback('Ready');
  }

  /// Disposes internal ValueNotifiers.
  void dispose() {
    _stateNotifier.dispose();
    _repCountNotifier.dispose();
    _feedbackNotifier.dispose();
  }
}
