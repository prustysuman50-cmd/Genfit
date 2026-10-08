import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/pose_detection_service.dart';
import 'package:genfit/core/services/push_up_analysis_service.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('PushUpAnalysisService Unit Tests', () {
    late PushUpAnalysisService service;
    late DateTime simulatedTime;

    setUp(() {
      simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
      service = PushUpAnalysisService(
        topAngleThreshold: 150.0,
        downAngleThreshold: 100.0,
        bodyAlignmentThreshold: 125.0,
        smoothingFactor: 1.0, // 1.0 = direct pass-through for exact angle tests
        minRepCooldown: const Duration(milliseconds: 800),
        timeProvider: () => simulatedTime,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test(
      'initializes with top state, 0 reps, and "Get into position" feedback',
      () {
        expect(service.state, equals(PushUpState.top));
        expect(service.repCount, equals(0));
        expect(service.feedback, equals('Get into position'));
        expect(service.rawElbowAngle, isNull);
        expect(service.smoothedElbowAngle, isNull);
        expect(service.rawBodyAlignmentAngle, isNull);
        expect(service.hasEstablishedTop, isFalse);
      },
    );

    test('requires valid top plank position before down transition can be accepted', () {
      // 1. Arm is bent before top position is established
      service.processAngle(90.0);
      expect(service.state, equals(PushUpState.top));
      expect(service.hasEstablishedTop, isFalse);
      expect(service.repCount, equals(0));
      expect(service.feedback, equals('Get into position'));

      // 2. User establishes top plank position (arms extended >= 150°)
      service.processAngle(160.0);
      expect(service.hasEstablishedTop, isTrue);
      expect(service.state, equals(PushUpState.top));
      expect(service.feedback, equals('Ready'));

      // 3. Now flexing arms <= 100° transitions to down
      service.processAngle(90.0);
      expect(service.state, equals(PushUpState.down));
      expect(service.feedback, equals('Push up'));
    });

    test('normal push-up cycle: TOP -> DOWN -> TOP = exactly 1 rep', () {
      final List<PushUpState> stateHistory = [];
      service.onStateChanged = (state) => stateHistory.add(state);

      // 1. TOP: Arms extended in plank (160°)
      service.processAngle(160.0);
      expect(service.state, equals(PushUpState.top));
      expect(service.repCount, equals(0));

      // 2. DOWN: User bends elbows significantly (90° <= 100°)
      service.processAngle(90.0);
      expect(service.state, equals(PushUpState.down));
      expect(service.feedback, equals('Push up'));
      expect(service.repCount, equals(0)); // Do not count yet

      // Advance time past cooldown
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));

      // 3. TOP: User pushes back up (155° >= 150°)
      service.processAngle(155.0);
      expect(service.state, equals(PushUpState.top));
      expect(service.repCount, equals(1)); // Exactly 1 rep
      expect(service.feedback, equals('Good rep'));

      // Verified state history
      expect(stateHistory, [PushUpState.down, PushUpState.top]);
    });

    test('partial movement without reaching DOWN threshold -> 0 reps', () {
      // 1. Establish top position (160°)
      service.processAngle(160.0);
      expect(service.state, equals(PushUpState.top));

      // 2. Partial bend: elbows only reach 115° (> 100° threshold)
      service.processAngle(115.0);
      expect(service.state, equals(PushUpState.top)); // Still in top state
      expect(service.repCount, equals(0));

      // 3. Extend arms back to 160°
      service.processAngle(160.0);
      expect(service.state, equals(PushUpState.top));
      expect(service.repCount, equals(0)); // 0 reps!
    });

    test('incomplete return from DOWN position -> 0 reps', () {
      // 1. Establish top position
      service.processAngle(160.0);

      // 2. Descend to DOWN position (90°)
      service.processAngle(90.0);
      expect(service.state, equals(PushUpState.down));

      // 3. Push up partially (130°, does not reach >= 150° TOP threshold)
      service.processAngle(130.0);
      expect(service.state, equals(PushUpState.down)); // Still in down state
      expect(service.repCount, equals(0));

      // 4. Sink back down to 85°
      service.processAngle(85.0);
      expect(service.state, equals(PushUpState.down));
      expect(service.repCount, equals(0)); // 0 reps!
    });

    test('holding the DOWN position does not repeatedly count reps', () {
      service.processAngle(160.0);
      service.processAngle(90.0);
      expect(service.state, equals(PushUpState.down));
      expect(service.repCount, equals(0));

      // Hold down across multiple frames
      for (int i = 0; i < 20; i++) {
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 100));
        service.processAngle(85.0 + (i % 8));
        expect(service.state, equals(PushUpState.down));
        expect(service.repCount, equals(0));
        expect(service.feedback, equals('Push up'));
      }
    });

    test('holding the TOP position does not repeatedly count reps', () {
      for (int i = 0; i < 25; i++) {
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 100));
        service.processAngle(160.0 + (i % 10));
        expect(service.state, equals(PushUpState.top));
        expect(service.repCount, equals(0));
      }
    });

    test('poor body alignment produces "Keep your body aligned" feedback', () {
      // 1. In top position with aligned body (160° hip angle >= 125°)
      service.processAngle(160.0, bodyAlignmentAngle: 160.0);
      expect(service.feedback, equals('Ready'));

      // 2. Sagging hips / poor alignment (110° < 125°)
      service.processAngle(160.0, bodyAlignmentAngle: 110.0);
      expect(service.feedback, equals('Keep your body aligned'));

      // 3. Posture corrected (150° >= 125°)
      service.processAngle(160.0, bodyAlignmentAngle: 150.0);
      expect(service.feedback, equals('Ready'));
    });

    test('counts multiple consecutive push-up repetitions', () {
      // Rep 1
      service.processAngle(160.0);
      service.processAngle(88.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(160.0);
      expect(service.repCount, equals(1));
      expect(service.feedback, equals('Good rep'));

      // Rep 2
      service.processAngle(85.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(160.0);
      expect(service.repCount, equals(2));
      expect(service.feedback, equals('Good rep'));

      // Rep 3
      service.processAngle(90.0);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));
      service.processAngle(160.0);
      expect(service.repCount, equals(3));
      expect(service.feedback, equals('Good rep'));
    });

    test('debounces rapid triggers within minRepCooldown duration', () {
      // Rep 1 completes
      service.processAngle(160.0);
      service.processAngle(90.0);
      service.processAngle(160.0);
      expect(service.repCount, equals(1));

      // Attempt rapid second rep only 200ms later (< 800ms cooldown)
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 200));
      service.processAngle(90.0);
      service.processAngle(160.0);
      // Debounced: Rep count remains 1
      expect(service.repCount, equals(1));

      // Advance past 800ms cooldown and complete rep 2
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 900));
      service.processAngle(90.0);
      service.processAngle(160.0);
      expect(service.repCount, equals(2));
    });

    test(
      'reset clears rep count, state, angles, and restores initial feedback',
      () {
        service.processAngle(160.0);
        service.processAngle(90.0);
        simulatedTime = simulatedTime.add(const Duration(seconds: 1));
        service.processAngle(160.0);
        expect(service.repCount, equals(1));

        service.reset();
        expect(service.state, equals(PushUpState.top));
        expect(service.repCount, equals(0));
        expect(service.feedback, equals('Get into position'));
        expect(service.smoothedElbowAngle, isNull);
        expect(service.rawElbowAngle, isNull);
        expect(service.rawBodyAlignmentAngle, isNull);
        expect(service.hasEstablishedTop, isFalse);
      },
    );

    test('manual incrementRep increases count and triggers notifiers', () {
      int callbackCount = 0;
      service.onRepCompleted = (count) => callbackCount = count;

      service.incrementRep();
      expect(service.repCount, equals(1));
      expect(callbackCount, equals(1));
      expect(service.repCountNotifier.value, equals(1));
      expect(service.feedback, equals('Good rep'));
    });

    test('EMA smoothing dampens single-frame elbow angle dips', () {
      final smoothedService = PushUpAnalysisService(
        topAngleThreshold: 150.0,
        downAngleThreshold: 100.0,
        smoothingFactor: 0.5, // EMA smoothing
      );

      // Frame 1: Top extended arms (160°)
      smoothedService.processAngle(160.0);
      expect(smoothedService.smoothedElbowAngle, equals(160.0));
      expect(smoothedService.state, equals(PushUpState.top));

      // Single-frame noisy dip to 70°
      smoothedService.processAngle(70.0);
      // Smoothed: 160 * 0.5 + 70 * 0.5 = 115.0°
      expect(smoothedService.smoothedElbowAngle, equals(115.0));
      // 115° is > 100° (down threshold), so single-frame dip is ignored!
      expect(smoothedService.state, equals(PushUpState.top));

      smoothedService.dispose();
    });
  });

  group('PushUpAnalysisService Landmark & Angle Selection Tests', () {
    late PushUpAnalysisService service;
    late DateTime simulatedTime;

    setUp(() {
      simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
      service = PushUpAnalysisService(
        topAngleThreshold: 150.0,
        downAngleThreshold: 100.0,
        bodyAlignmentThreshold: 125.0,
        smoothingFactor: 1.0,
        minRepCooldown: const Duration(milliseconds: 800),
        timeProvider: () => simulatedTime,
      );
    });

    tearDown(() {
      service.dispose();
    });

    PoseLandmark lm(
      PoseLandmarkType type,
      double x,
      double y, {
      double likelihood = 0.95,
    }) {
      return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: likelihood);
    }

    test('robust elbow angle selection: Left = 156°, Right = 166° produces sensible average (161°), never 31°', () {
      // Left arm: 156°
      // Right arm: 166°
      // Both arms have high confidence
      // Vector geometry:
      // Left: shoulder(100, 100), elbow(100, 200), wrist(140, 290) -> ~156°
      // Right: shoulder(100, 100), elbow(100, 200), wrist(125, 296) -> ~166°
      final landmarks = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 140, 290),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        rightWrist: lm(PoseLandmarkType.rightWrist, 125, 296),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
      );

      final leftAngle = landmarks.leftElbowAngle;
      final rightAngle = landmarks.rightElbowAngle;
      expect(leftAngle, isNotNull);
      expect(rightAngle, isNotNull);

      final selectedAngle = service.extractElbowAngle(landmarks);
      expect(selectedAngle, isNotNull);
      // Robust average: (left + right) / 2
      final expectedAverage = (leftAngle! + rightAngle!) / 2.0;
      expect(selectedAngle, closeTo(expectedAverage, 0.001));
      // Must NOT be an unrelated/corrupted value like 31°
      expect(selectedAngle!, greaterThan(150.0));
      expect(selectedAngle, isNot(closeTo(31.0, 5.0)));
    });

    test('ignores glitched arm (< 45°) and cleanly selects reliable arm', () {
      // Left arm is normal extended (~160°)
      // Right arm has noisy wrist creating an impossible acute angle (~30° < 45°)
      final landmarks = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 134, 294),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        rightWrist: lm(
          PoseLandmarkType.rightWrist,
          105,
          110,
        ), // Glitched acute angle
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
      );

      final leftAngle = landmarks.leftElbowAngle;
      final rightAngle = landmarks.rightElbowAngle;
      expect(leftAngle, isNotNull);
      expect(leftAngle!, greaterThan(150.0));
      expect(rightAngle, isNotNull);
      expect(rightAngle!, lessThan(45.0));

      final selectedAngle = service.extractElbowAngle(landmarks);
      expect(selectedAngle, isNotNull);
      // Cleanly selects reliable left arm, discarding the 30° glitch!
      expect(selectedAngle, equals(leftAngle));
    });

    test('ignores low-confidence arm and uses reliable arm', () {
      // Left arm has high confidence (0.95)
      // Right arm has very low confidence (0.10)
      final landmarks = PushUpLandmarks(
        leftShoulder: lm(
          PoseLandmarkType.leftShoulder,
          100,
          100,
          likelihood: 0.95,
        ),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200, likelihood: 0.95),
        leftWrist: lm(PoseLandmarkType.leftWrist, 100, 300, likelihood: 0.95),
        rightShoulder: lm(
          PoseLandmarkType.rightShoulder,
          100,
          100,
          likelihood: 0.10,
        ),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200, likelihood: 0.10),
        rightWrist: lm(PoseLandmarkType.rightWrist, 200, 200, likelihood: 0.10),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
      );

      final selectedAngle = service.extractElbowAngle(landmarks);
      expect(selectedAngle, isNotNull);
      // Selected angle is from the reliable left arm (180.0°)
      expect(selectedAngle, closeTo(180.0, 0.1));
    });

    test('valid full-body push-up with landmarks -> exactly 1 rep', () {
      // 1. TOP: Arms extended (180°), aligned plank
      final topLm = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 100, 300),
        rightWrist: lm(PoseLandmarkType.rightWrist, 100, 300),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
      );
      service.processLandmarks(topLm);
      expect(service.state, equals(PushUpState.top));
      expect(service.hasEstablishedTop, isTrue);
      expect(service.repCount, equals(0));

      // 2. DOWN: Elbows bent to 90° (<= 100°)
      final downLm = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 200, 200), // 90°
        rightWrist: lm(PoseLandmarkType.rightWrist, 200, 200),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
      );
      service.processLandmarks(downLm);
      expect(service.state, equals(PushUpState.down));
      expect(service.feedback, equals('Push up'));
      expect(service.repCount, equals(0));

      // Advance time past cooldown
      simulatedTime = simulatedTime.add(const Duration(seconds: 1));

      // 3. TOP: Return to top extended position (180°)
      service.processLandmarks(topLm);
      expect(service.state, equals(PushUpState.top));
      expect(service.repCount, equals(1));
      expect(service.feedback, equals('Good rep'));
    });

    test('repeated valid push-ups with landmarks -> correct rep count', () {
      final topLm = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 100, 300),
        rightWrist: lm(PoseLandmarkType.rightWrist, 100, 300),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
      );
      final downLm = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 200, 200),
        rightWrist: lm(PoseLandmarkType.rightWrist, 200, 200),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
      );

      for (int i = 1; i <= 3; i++) {
        service.processLandmarks(topLm);
        service.processLandmarks(downLm);
        simulatedTime = simulatedTime.add(const Duration(seconds: 1));
        service.processLandmarks(topLm);
        expect(service.repCount, equals(i));
        expect(service.feedback, equals('Good rep'));
      }
    });

    test(
      'circular/arm waving movement without entering DOWN state -> 0 reps',
      () {
        // 1. Establish top plank
        final topLm = PushUpLandmarks(
          leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
          rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
          leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
          rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
          leftWrist: lm(PoseLandmarkType.leftWrist, 100, 300),
          rightWrist: lm(PoseLandmarkType.rightWrist, 100, 300),
          leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
          rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
          leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
          rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
        );
        service.processLandmarks(topLm);

        // 2. Arm circular/waving gestures where elbow angle only changes slightly (130° - 170°),
        // never completing TOP -> DOWN -> TOP
        for (int i = 0; i < 10; i++) {
          final wavingLm = PushUpLandmarks(
            leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
            rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
            leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
            rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
            // Wrist positions oscillate slightly without reaching down depth
            leftWrist: lm(PoseLandmarkType.leftWrist, 140, 280),
            rightWrist: lm(PoseLandmarkType.rightWrist, 140, 280),
            leftHip: lm(PoseLandmarkType.leftHip, 300, 100),
            rightHip: lm(PoseLandmarkType.rightHip, 300, 100),
            leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
            rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
          );
          service.processLandmarks(wavingLm);
          expect(service.state, equals(PushUpState.top));
          expect(service.repCount, equals(0));
        }

        expect(service.repCount, equals(0));
      },
    );

    test('noisy/low-confidence frame is rejected -> 0 reps', () {
      // Low confidence (0.15 < minLandmarkConfidence of 0.35)
      final lowConfLm = PushUpLandmarks(
        leftShoulder: lm(
          PoseLandmarkType.leftShoulder,
          100,
          100,
          likelihood: 0.15,
        ),
        rightShoulder: lm(
          PoseLandmarkType.rightShoulder,
          100,
          100,
          likelihood: 0.15,
        ),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200, likelihood: 0.15),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200, likelihood: 0.15),
        leftWrist: lm(PoseLandmarkType.leftWrist, 100, 300, likelihood: 0.15),
        rightWrist: lm(PoseLandmarkType.rightWrist, 100, 300, likelihood: 0.15),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 100, likelihood: 0.15),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 100, likelihood: 0.15),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100, likelihood: 0.15),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100, likelihood: 0.15),
      );

      service.processLandmarks(lowConfLm);
      expect(service.state, equals(PushUpState.top));
      expect(service.feedback, equals('Move into camera view'));
      expect(service.repCount, equals(0));
    });

    test('flags poor body alignment during landmark processing', () {
      // Sagging hips: hip drops to y=250 while shoulder & ankle are y=100 -> angle ~108° (< 125°)
      final saggingLm = PushUpLandmarks(
        leftShoulder: lm(PoseLandmarkType.leftShoulder, 100, 100),
        rightShoulder: lm(PoseLandmarkType.rightShoulder, 100, 100),
        leftElbow: lm(PoseLandmarkType.leftElbow, 100, 200),
        rightElbow: lm(PoseLandmarkType.rightElbow, 100, 200),
        leftWrist: lm(PoseLandmarkType.leftWrist, 100, 300),
        rightWrist: lm(PoseLandmarkType.rightWrist, 100, 300),
        leftHip: lm(PoseLandmarkType.leftHip, 300, 250),
        rightHip: lm(PoseLandmarkType.rightHip, 300, 250),
        leftAnkle: lm(PoseLandmarkType.leftAnkle, 500, 100),
        rightAnkle: lm(PoseLandmarkType.rightAnkle, 500, 100),
      );

      service.processLandmarks(saggingLm);
      expect(service.feedback, equals('Keep your body aligned'));
    });
  });
}
