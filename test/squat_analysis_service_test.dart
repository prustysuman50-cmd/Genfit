import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/pose_detection_service.dart';
import 'package:genfit/core/services/squat_analysis_service.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('SquatAnalysisService Unit Tests', () {
    late SquatAnalysisService service;
    late DateTime simulatedTime;

    setUp(() {
      simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
      service = SquatAnalysisService(
        standingAngleThreshold: 160.0,
        descendingAngleThreshold: 145.0,
        bottomAngleThreshold: 105.0,
        returningAngleThreshold: 115.0,
        smoothingFactor: 1.0, // 1.0 = direct pass-through for exact angle tests
        minRepCooldown: const Duration(milliseconds: 800),
        timeProvider: () => simulatedTime,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with standing state and 0 reps', () {
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(0));
      expect(service.rawKneeAngle, isNull);
      expect(service.smoothedKneeAngle, isNull);
    });

    test('counts exactly ONE repetition after a complete cycle: standing -> descending -> bottom -> returning -> standing', () {
      final List<SquatState> stateHistory = [];
      service.onStateChanged = (state) => stateHistory.add(state);

      // 1. Standing upright (170°)
      service.processAngle(170.0);
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(0));

      // 2. Descending (< 145°)
      service.processAngle(135.0);
      expect(service.state, equals(SquatState.descending));
      expect(service.repCount, equals(0));

      // 3. Reaching bottom depth (<= 100°)
      service.processAngle(90.0);
      expect(service.state, equals(SquatState.bottom));
      expect(service.repCount, equals(0));

      // 4. Returning / ascending (> 115°)
      service.processAngle(125.0);
      expect(service.state, equals(SquatState.returning));
      expect(service.repCount, equals(0));

      // Advance time to pass rep cooldown
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));

      // 5. Returned to standing (>= 160°)
      service.processAngle(165.0);
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(1));

      // Verify state sequence
      expect(stateHistory, [
        SquatState.descending,
        SquatState.bottom,
        SquatState.returning,
        SquatState.standing,
      ]);
    });

    test('does NOT count when user remains at bottom position', () {
      service.processAngle(170.0);
      service.processAngle(130.0); // descending
      service.processAngle(90.0); // bottom
      expect(service.state, equals(SquatState.bottom));
      expect(service.repCount, equals(0));

      // User pauses at bottom across multiple frames
      for (int i = 0; i < 20; i++) {
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 100));
        service.processAngle(88.0 + (i % 5));
        expect(service.state, equals(SquatState.bottom));
        expect(service.repCount, equals(0));
      }
    });

    test('does NOT count when user remains in standing position', () {
      for (int i = 0; i < 30; i++) {
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 100));
        service.processAngle(165.0 + (i % 10));
        expect(service.state, equals(SquatState.standing));
        expect(service.repCount, equals(0));
      }
    });

    test('does NOT count incomplete descent (standing -> descending -> standing without hitting bottom)', () {
      service.processAngle(170.0); // standing
      service.processAngle(135.0); // descending
      expect(service.state, equals(SquatState.descending));

      // User goes down to 110° (does not reach <= 105° bottom threshold)
      service.processAngle(110.0);
      expect(service.state, equals(SquatState.descending));

      // User stands back up to 165°
      service.processAngle(165.0);
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(0)); // Incomplete squat, 0 reps
    });

    test('movement with bottom angle slightly above 100 degrees (104.0°) counts as a valid repetition', () {
      service.processAngle(170.0); // standing
      service.processAngle(135.0); // descending
      expect(service.state, equals(SquatState.descending));

      // Bottom inflection at 104.0° (<= 105.0° adjusted bottom threshold)
      service.processAngle(104.0);
      expect(service.state, equals(SquatState.bottom));
      expect(service.repCount, equals(0));

      // Returning / ascending (> 115.0°)
      service.processAngle(125.0);
      expect(service.state, equals(SquatState.returning));
      expect(service.repCount, equals(0));

      simulatedTime = simulatedTime.add(const Duration(seconds: 1));

      // Standing lockout (>= 160.0°)
      service.processAngle(165.0);
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(1));
    });

    test('shallow squat movement (115.0°) does NOT count and aborts to standing', () {
      service.processAngle(170.0); // standing
      service.processAngle(135.0); // descending
      expect(service.state, equals(SquatState.descending));

      // Shallow dip only reaching 115.0° (fails to reach <= 105.0° bottom threshold)
      service.processAngle(115.0);
      expect(service.state, equals(SquatState.descending));

      // User stands back up without completing bottom depth
      service.processAngle(165.0);
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(0)); // Discarded as aborted descent
    });

    test('incomplete return from bottom (reaches 150.0° but not 160.0°) does NOT count repetition', () {
      service.processAngle(170.0); // standing
      service.processAngle(130.0); // descending
      service.processAngle(104.0); // bottom
      expect(service.state, equals(SquatState.bottom));

      // Starts returning
      service.processAngle(125.0);
      expect(service.state, equals(SquatState.returning));

      // Pauses or partially ascends to 150.0° (< 160.0° standing threshold)
      service.processAngle(150.0);
      expect(service.state, equals(SquatState.returning));
      expect(service.repCount, equals(0));
    });

    test('counts multiple complete repetitions sequentially', () {
      // Rep 1
      service.processAngle(170.0);
      service.processAngle(130.0);
      service.processAngle(90.0);
      service.processAngle(120.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(165.0);
      expect(service.repCount, equals(1));

      // Rep 2
      service.processAngle(130.0);
      service.processAngle(85.0);
      service.processAngle(120.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(165.0);
      expect(service.repCount, equals(2));

      // Rep 3
      service.processAngle(130.0);
      service.processAngle(92.0);
      service.processAngle(120.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(165.0);
      expect(service.repCount, equals(3));
    });

    test('debounces rapid triggers within minRepCooldown duration', () {
      // Rep 1
      service.processAngle(170.0);
      service.processAngle(130.0);
      service.processAngle(90.0);
      service.processAngle(120.0);
      service.processAngle(165.0);
      expect(service.repCount, equals(1));

      // Attempt immediate second rep completion only 200ms later (unrealistic glitch)
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 200));
      service.processAngle(130.0);
      service.processAngle(90.0);
      service.processAngle(120.0);
      service.processAngle(165.0);

      // Debounced: Rep count remains 1
      expect(service.repCount, equals(1));

      // Advance past 800ms cooldown and complete another rep
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 900));
      service.processAngle(130.0);
      service.processAngle(90.0);
      service.processAngle(120.0);
      service.processAngle(165.0);

      expect(service.repCount, equals(2));
    });

    test('handles re-sinking to bottom from returning phase', () {
      service.processAngle(170.0);
      service.processAngle(130.0); // descending
      service.processAngle(90.0); // bottom
      service.processAngle(120.0); // returning
      expect(service.state, equals(SquatState.returning));

      // User sinks back down to bottom
      service.processAngle(95.0);
      expect(service.state, equals(SquatState.bottom));
      expect(service.repCount, equals(0));

      // Ascends again and completes
      service.processAngle(120.0); // returning
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(165.0); // standing
      expect(service.repCount, equals(1));
    });

    test('reset clears rep count, state, and smoothing', () {
      service.processAngle(170.0);
      service.processAngle(130.0);
      service.processAngle(90.0);
      service.processAngle(120.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(165.0);
      expect(service.repCount, equals(1));

      service.reset();
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(0));
      expect(service.smoothedKneeAngle, isNull);
      expect(service.rawKneeAngle, isNull);
    });

    test('manual incrementRep increases count and triggers notifiers', () {
      int callbackCount = 0;
      service.onRepCompleted = (count) => callbackCount = count;

      service.incrementRep();
      expect(service.repCount, equals(1));
      expect(callbackCount, equals(1));
      expect(service.repCountNotifier.value, equals(1));
    });

    test('EMA smoothing dampens single-frame angle spikes', () {
      final smoothedService = SquatAnalysisService(
        standingAngleThreshold: 160.0,
        descendingAngleThreshold: 145.0,
        bottomAngleThreshold: 100.0,
        returningAngleThreshold: 115.0,
        smoothingFactor: 0.4, // EMA smoothing enabled
      );

      // Frame 1: Standing upright
      smoothedService.processAngle(170.0);
      expect(smoothedService.smoothedKneeAngle, equals(170.0));
      expect(smoothedService.state, equals(SquatState.standing));

      // Single frame noisy spike dipping to 140°
      smoothedService.processAngle(140.0);
      // Smoothed: 170 * 0.6 + 140 * 0.4 = 102 + 56 = 158.0°
      expect(smoothedService.smoothedKneeAngle, equals(158.0));
      // 158.0° is >= 145.0°, so state remains standing (noise filtered out!)
      expect(smoothedService.state, equals(SquatState.standing));

      smoothedService.dispose();
    });
  });

  group('SquatAnalysisService Landmark Integration Tests', () {
    late SquatAnalysisService service;

    setUp(() {
      service = SquatAnalysisService(
        standingAngleThreshold: 160.0,
        descendingAngleThreshold: 145.0,
        bottomAngleThreshold: 100.0,
        returningAngleThreshold: 115.0,
        smoothingFactor: 1.0,
        minRepCooldown: Duration.zero,
      );
    });

    tearDown(() {
      service.dispose();
    });

    PoseLandmark lm(PoseLandmarkType type, double x, double y) {
      return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: 0.95);
    }

    test('processes both legs by averaging angles', () {
      // Left leg straight (~180°): hip(100, 100), knee(100, 200), ankle(100, 300)
      // Right leg straight (~180°): hip(200, 100), knee(200, 200), ankle(200, 300)
      final straight = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 100, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
        rightHip: lm(PoseLandmarkType.rightHip, 200, 100),
        rightKnee: lm(PoseLandmarkType.rightKnee, 200, 200),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 200, 300),
      );

      final angle = service.extractKneeAngle(straight);
      expect(angle, isNotNull);
      expect(angle!, closeTo(180.0, 0.1));

      service.processLandmarks(straight);
      expect(service.state, equals(SquatState.standing));
    });

    test('processes left leg only (side profile)', () {
      // Left leg bent at 90°: hip(0, 100), knee(100, 100), ankle(100, 200)
      final leftOnly = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 0, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 100),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 200),
      );

      final angle = service.extractKneeAngle(leftOnly);
      expect(angle, isNotNull);
      expect(angle!, closeTo(90.0, 0.1));

      service.processLandmarks(leftOnly);
      expect(service.rawKneeAngle, closeTo(90.0, 0.1));
    });

    test('processes right leg only (side profile)', () {
      // Right leg bent at 90°
      final rightOnly = SquatLandmarks(
        rightHip: lm(PoseLandmarkType.rightHip, 0, 100),
        rightKnee: lm(PoseLandmarkType.rightKnee, 100, 100),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 100, 200),
      );

      final angle = service.extractKneeAngle(rightOnly);
      expect(angle, isNotNull);
      expect(angle!, closeTo(90.0, 0.1));

      service.processLandmarks(rightOnly);
      expect(service.rawKneeAngle, closeTo(90.0, 0.1));
    });

    test('ignores landmarks when neither leg is sufficiently detected', () {
      const empty = SquatLandmarks();
      expect(service.extractKneeAngle(empty), isNull);

      service.processLandmarks(empty);
      expect(service.rawKneeAngle, isNull);
      expect(service.state, equals(SquatState.standing));
    });

    test('completes full repetition using SquatLandmarks sequence', () {
      // 1. Standing (180°)
      final standingLm = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 100, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
      );
      service.processLandmarks(standingLm);
      expect(service.state, equals(SquatState.standing));

      // 2. Descending (135°): hip(0, 100), knee(100, 200), ankle(100, 300)
      // Angle: atan2(300-200, 100-100) = 90°, atan2(100-200, 0-100) = -135° -> diff = 225° -> 360-225 = 135°
      final descendingLm = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 0, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
      );
      service.processLandmarks(descendingLm);
      expect(service.state, equals(SquatState.descending));

      // 3. Bottom (90°): hip(0, 200), knee(100, 200), ankle(100, 300)
      final bottomLm = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 0, 200),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
      );
      service.processLandmarks(bottomLm);
      expect(service.state, equals(SquatState.bottom));

      // 4. Returning (135°)
      service.processLandmarks(descendingLm);
      expect(service.state, equals(SquatState.returning));

      // 5. Standing (180°)
      service.processLandmarks(standingLm);
      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(1));
    });
  });

  group('Squat Form Feedback Tests', () {
    late SquatAnalysisService service;

    setUp(() {
      service = SquatAnalysisService(
        standingAngleThreshold: 160.0,
        descendingAngleThreshold: 145.0,
        bottomAngleThreshold: 100.0,
        returningAngleThreshold: 115.0,
        smoothingFactor: 1.0,
        minRepCooldown: Duration.zero,
        instabilityAngleDelta: 15.0,
        lateralInstabilityDelta: 30.0,
      );
    });

    tearDown(() {
      service.dispose();
    });

    PoseLandmark lm(PoseLandmarkType type, double x, double y) {
      return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: 0.95);
    }

    test('insufficient squat depth -> "Go a little lower"', () {
      service.processAngle(170.0); // standing
      service.processAngle(130.0); // descending, but > 100°

      expect(service.state, equals(SquatState.descending));
      expect(service.feedback, equals('Go a little lower'));
    });

    test('sufficient depth -> "Good depth"', () {
      service.processAngle(170.0); // standing
      service.processAngle(130.0); // descending
      service.processAngle(90.0); // bottom <= 100°

      expect(service.state, equals(SquatState.bottom));
      expect(service.feedback, equals('Good depth'));
    });

    test('incomplete return to standing -> "Stand fully"', () {
      service.processAngle(170.0); // standing
      service.processAngle(130.0); // descending
      service.processAngle(90.0); // bottom
      service.processAngle(125.0); // returning > 115° but < 160°

      expect(service.state, equals(SquatState.returning));
      expect(service.feedback, equals('Stand fully'));
    });

    test('complete rep -> "Good rep"', () {
      service.processAngle(170.0); // standing
      service.processAngle(130.0); // descending
      service.processAngle(90.0); // bottom
      service.processAngle(125.0); // returning
      service.processAngle(165.0); // standing >= 160°

      expect(service.state, equals(SquatState.standing));
      expect(service.repCount, equals(1));
      expect(service.feedback, equals('Good rep'));
    });

    test('insufficient landmarks -> "Move into camera view"', () {
      // Missing landmarks completely
      service.processLandmarks(null);
      expect(service.feedback, equals('Move into camera view'));

      // Empty landmarks
      const empty = SquatLandmarks();
      service.processLandmarks(empty);
      expect(service.feedback, equals('Move into camera view'));
    });

    test('partial body visibility -> "Keep your full body visible"', () {
      // Only left leg visible while standing
      final leftOnly = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 100, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
      );
      service.processLandmarks(leftOnly);
      expect(service.feedback, equals('Keep your full body visible'));
    });

    test('stable movement -> no stability warning', () {
      service.processAngle(170.0);
      expect(service.feedback, isNot(equals('Keep your movement controlled')));

      service.processAngle(140.0); // smooth descent
      expect(service.feedback, isNot(equals('Keep your movement controlled')));
      expect(service.feedback, equals('Go a little lower'));

      service.processAngle(95.0); // smooth bottom
      expect(service.feedback, isNot(equals('Keep your movement controlled')));
      expect(service.feedback, equals('Good depth'));

      service.processAngle(130.0); // smooth return
      expect(service.feedback, isNot(equals('Keep your movement controlled')));
      expect(service.feedback, equals('Stand fully'));
    });

    test('unstable landmark movement (angular wobble) -> "Keep your movement controlled"', () {
      service.processAngle(170.0);
      service.processAngle(130.0); // descending
      expect(service.feedback, equals('Go a little lower'));

      // Sudden 25° upward wobble while in descending phase
      service.processAngle(155.0);
      expect(service.feedback, equals('Keep your movement controlled'));
    });

    test('unstable landmark movement (lateral shift) -> "Keep your movement controlled"', () {
      final lm1 = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 100, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 100, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
      );

      // Knee shifts laterally by 50px between frames
      final lm2 = SquatLandmarks(
        leftHip: lm(PoseLandmarkType.leftHip, 100, 100),
        leftKnee: lm(PoseLandmarkType.leftKnee, 150, 200),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 100, 300),
      );

      service.processLandmarks(lm1);
      service.processLandmarks(lm2);
      expect(service.feedback, equals('Keep your movement controlled'));
    });

    test('reset restores feedback to "Ready"', () {
      service.processAngle(170.0);
      service.processAngle(130.0);
      service.processAngle(90.0);
      service.processAngle(125.0);
      service.processAngle(165.0);
      expect(service.feedback, equals('Good rep'));

      service.reset();
      expect(service.feedback, equals('Ready'));
      expect(service.repCount, equals(0));
    });
  });
}
