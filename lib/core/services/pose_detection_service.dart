import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Body landmarks specifically extracted for Squat tracking and analysis.
class SquatLandmarks {
  final PoseLandmark? leftShoulder;
  final PoseLandmark? rightShoulder;
  final PoseLandmark? leftHip;
  final PoseLandmark? rightHip;
  final PoseLandmark? leftKnee;
  final PoseLandmark? rightKnee;
  final PoseLandmark? leftAnkle;
  final PoseLandmark? rightAnkle;

  const SquatLandmarks({
    this.leftShoulder,
    this.rightShoulder,
    this.leftHip,
    this.rightHip,
    this.leftKnee,
    this.rightKnee,
    this.leftAnkle,
    this.rightAnkle,
  });

  bool get hasLeftLeg =>
      leftHip != null && leftKnee != null && leftAnkle != null;
  bool get hasRightLeg =>
      rightHip != null && rightKnee != null && rightAnkle != null;

  /// Whether sufficient keypoints are visible to track a squat.
  bool get hasSufficientSquatPoints => hasLeftLeg || hasRightLeg;

  /// Calculate the angle (in degrees) at the knee joint between hip, knee, and ankle.
  double? get leftKneeAngle {
    if (!hasLeftLeg) return null;
    return _calculateAngle(leftHip!, leftKnee!, leftAnkle!);
  }

  double? get rightKneeAngle {
    if (!hasRightLeg) return null;
    return _calculateAngle(rightHip!, rightKnee!, rightAnkle!);
  }

  /// Calculate the angle (in degrees) at the hip joint between shoulder, hip, and knee.
  double? get leftHipAngle {
    if (leftShoulder == null || leftHip == null || leftKnee == null) {
      return null;
    }
    return _calculateAngle(leftShoulder!, leftHip!, leftKnee!);
  }

  double? get rightHipAngle {
    if (rightShoulder == null || rightHip == null || rightKnee == null) {
      return null;
    }
    return _calculateAngle(rightShoulder!, rightHip!, rightKnee!);
  }

  static double _calculateAngle(
    PoseLandmark first,
    PoseLandmark mid,
    PoseLandmark last,
  ) {
    final double radians =
        math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);
    double degrees = radians * (180.0 / math.pi);
    degrees = degrees.abs();
    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  }
}

/// Body landmarks specifically extracted for Push-up tracking and form analysis.
class PushUpLandmarks {
  final PoseLandmark? leftShoulder;
  final PoseLandmark? rightShoulder;
  final PoseLandmark? leftElbow;
  final PoseLandmark? rightElbow;
  final PoseLandmark? leftWrist;
  final PoseLandmark? rightWrist;
  final PoseLandmark? leftHip;
  final PoseLandmark? rightHip;
  final PoseLandmark? leftKnee;
  final PoseLandmark? rightKnee;
  final PoseLandmark? leftAnkle;
  final PoseLandmark? rightAnkle;

  const PushUpLandmarks({
    this.leftShoulder,
    this.rightShoulder,
    this.leftElbow,
    this.rightElbow,
    this.leftWrist,
    this.rightWrist,
    this.leftHip,
    this.rightHip,
    this.leftKnee,
    this.rightKnee,
    this.leftAnkle,
    this.rightAnkle,
  });

  bool get hasLeftArm =>
      leftShoulder != null && leftElbow != null && leftWrist != null;

  bool get hasRightArm =>
      rightShoulder != null && rightElbow != null && rightWrist != null;

  bool get hasArm => hasLeftArm || hasRightArm;

  bool get hasHip => leftHip != null || rightHip != null;

  bool get hasLowerBody =>
      leftAnkle != null ||
      rightAnkle != null ||
      leftKnee != null ||
      rightKnee != null;

  /// Whether sufficient keypoints are visible to track a push-up.
  bool get hasSufficientPushUpPoints => hasArm && hasHip && hasLowerBody;

  /// Calculate the angle (in degrees) at the left elbow joint between shoulder, elbow, and wrist.
  double? get leftElbowAngle {
    if (!hasLeftArm) return null;
    return _calculateAngle(leftShoulder!, leftElbow!, leftWrist!);
  }

  /// Calculate the angle (in degrees) at the right elbow joint between shoulder, elbow, and wrist.
  double? get rightElbowAngle {
    if (!hasRightArm) return null;
    return _calculateAngle(rightShoulder!, rightElbow!, rightWrist!);
  }

  /// Calculate the angle (in degrees) representing left body alignment between shoulder, hip, and ankle (or knee).
  double? get leftBodyAlignmentAngle {
    if (leftShoulder == null || leftHip == null) return null;
    final lower = leftAnkle ?? leftKnee;
    if (lower == null) return null;
    return _calculateAngle(leftShoulder!, leftHip!, lower);
  }

  /// Calculate the angle (in degrees) representing right body alignment between shoulder, hip, and ankle (or knee).
  double? get rightBodyAlignmentAngle {
    if (rightShoulder == null || rightHip == null) return null;
    final lower = rightAnkle ?? rightKnee;
    if (lower == null) return null;
    return _calculateAngle(rightShoulder!, rightHip!, lower);
  }

  static double _calculateAngle(
    PoseLandmark first,
    PoseLandmark mid,
    PoseLandmark last,
  ) {
    final double radians =
        math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);
    double degrees = radians * (180.0 / math.pi);
    degrees = degrees.abs();
    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  }
}

/// Dedicated modular service for on-device ML Kit pose detection.
class PoseDetectionService {
  PoseDetectionService({PoseDetectorOptions? options})
    : _poseDetector = PoseDetector(
        options:
            options ??
            PoseDetectorOptions(
              mode: PoseDetectionMode.stream,
              model: PoseDetectionModel.base,
            ),
      );

  final PoseDetector _poseDetector;
  bool _isBusy = false;
  int _frameCount = 0;

  final ValueNotifier<SquatLandmarks?> squatLandmarksNotifier =
      ValueNotifier<SquatLandmarks?>(null);

  final ValueNotifier<PushUpLandmarks?> pushUpLandmarksNotifier =
      ValueNotifier<PushUpLandmarks?>(null);

  final ValueNotifier<String> poseStatusNotifier = ValueNotifier<String>(
    'Ready',
  );

  bool get isBusy => _isBusy;

  /// Process a camera stream frame and extract squat landmarks.
  Future<SquatLandmarks?> processCameraImage({
    required CameraImage image,
    required CameraDescription camera,
  }) async {
    if (_isBusy) return null;
    _isBusy = true;
    _frameCount++;
    final bool shouldLog = _frameCount % 30 == 1;

    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) {
        if (shouldLog) {
          debugPrint(
            '[GENFIT POSE ERROR] InputImage conversion returned null for '
            'format raw=${image.format.raw}, planes=${image.planes.length}',
          );
        }
        _isBusy = false;
        return null;
      }

      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        if (shouldLog) {
          debugPrint(
            '[GENFIT POSE] Case A: Camera frame #$_frameCount processed (${image.width}x${image.height}), '
            'but NO poses detected by ML Kit. Stand in full view of camera.',
          );
        }
        poseStatusNotifier.value = 'Step into frame';
        squatLandmarksNotifier.value = null;
        pushUpLandmarksNotifier.value = null;
        _isBusy = false;
        return null;
      }

      final Pose pose = poses.first;
      final squatLandmarks = extractSquatLandmarks(pose);
      final pushUpLandmarks = extractPushUpLandmarks(pose);
      squatLandmarksNotifier.value = squatLandmarks;
      pushUpLandmarksNotifier.value = pushUpLandmarks;

      if (shouldLog) {
        debugPrint(
          '[GENFIT POSE] Case B: Pose detected! Frame #$_frameCount. '
          'Has legs: L=${squatLandmarks.hasLeftLeg}, R=${squatLandmarks.hasRightLeg}, '
          'Sufficient=${squatLandmarks.hasSufficientSquatPoints}. Landmarks exposed to UI.',
        );
      }

      // Update descriptive pose status
      if (squatLandmarks.hasLeftLeg && squatLandmarks.hasRightLeg) {
        poseStatusNotifier.value = 'Full Body Detected • Ready';
      } else if (squatLandmarks.hasSufficientSquatPoints) {
        poseStatusNotifier.value = 'Side Profile Detected';
      } else {
        poseStatusNotifier.value = 'Position knees & hips in view';
      }

      _isBusy = false;
      return squatLandmarks;
    } catch (e, stack) {
      debugPrint(
        '[GENFIT POSE EXCEPTION] Error in processCameraImage: $e\n$stack',
      );
      _isBusy = false;
      return null;
    }
  }

  /// Extract only the relevant keypoints needed for squat detection.
  SquatLandmarks extractSquatLandmarks(Pose pose) {
    const minConfidence = 0.35;

    PoseLandmark? getValid(PoseLandmarkType type) {
      final landmark = pose.landmarks[type];
      if (landmark != null && landmark.likelihood >= minConfidence) {
        return landmark;
      }
      return null;
    }

    return SquatLandmarks(
      leftShoulder: getValid(PoseLandmarkType.leftShoulder),
      rightShoulder: getValid(PoseLandmarkType.rightShoulder),
      leftHip: getValid(PoseLandmarkType.leftHip),
      rightHip: getValid(PoseLandmarkType.rightHip),
      leftKnee: getValid(PoseLandmarkType.leftKnee),
      rightKnee: getValid(PoseLandmarkType.rightKnee),
      leftAnkle: getValid(PoseLandmarkType.leftAnkle),
      rightAnkle: getValid(PoseLandmarkType.rightAnkle),
    );
  }

  /// Extract keypoints needed for push-up detection and form feedback.
  PushUpLandmarks extractPushUpLandmarks(Pose pose) {
    const minConfidence = 0.35;

    PoseLandmark? getValid(PoseLandmarkType type) {
      final landmark = pose.landmarks[type];
      if (landmark != null && landmark.likelihood >= minConfidence) {
        return landmark;
      }
      return null;
    }

    return PushUpLandmarks(
      leftShoulder: getValid(PoseLandmarkType.leftShoulder),
      rightShoulder: getValid(PoseLandmarkType.rightShoulder),
      leftElbow: getValid(PoseLandmarkType.leftElbow),
      rightElbow: getValid(PoseLandmarkType.rightElbow),
      leftWrist: getValid(PoseLandmarkType.leftWrist),
      rightWrist: getValid(PoseLandmarkType.rightWrist),
      leftHip: getValid(PoseLandmarkType.leftHip),
      rightHip: getValid(PoseLandmarkType.rightHip),
      leftKnee: getValid(PoseLandmarkType.leftKnee),
      rightKnee: getValid(PoseLandmarkType.rightKnee),
      leftAnkle: getValid(PoseLandmarkType.leftAnkle),
      rightAnkle: getValid(PoseLandmarkType.rightAnkle),
    );
  }

  /// Converts a [CameraImage] into an [InputImage] for Google ML Kit.
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    if (image.planes.isEmpty) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(
      sensorOrientation,
    );
    rotation ??= (camera.lensDirection == CameraLensDirection.front
        ? InputImageRotation.rotation270deg
        : InputImageRotation.rotation90deg);

    if (Platform.isAndroid) {
      // Android ML Kit native fromByteArray requires NV21 format bytes.
      final Uint8List nv21Bytes;
      final int bytesPerRow;

      if (image.planes.length == 1) {
        // Direct single NV21 plane
        nv21Bytes = image.planes[0].bytes;
        bytesPerRow = image.planes[0].bytesPerRow;
      } else if (image.planes.length == 2) {
        // Semi-planar NV21: Plane 0 = Y, Plane 1 = VU
        final yPlane = image.planes[0];
        final uvPlane = image.planes[1];
        final combined = Uint8List(yPlane.bytes.length + uvPlane.bytes.length);
        combined.setRange(0, yPlane.bytes.length, yPlane.bytes);
        combined.setRange(yPlane.bytes.length, combined.length, uvPlane.bytes);
        nv21Bytes = combined;
        bytesPerRow = yPlane.bytesPerRow;
      } else {
        // 3 planes (Standard Android YUV_420_888): convert to contiguous NV21
        nv21Bytes = _convertYuv420ToNv21(image);
        bytesPerRow = image.width;
      }

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: bytesPerRow,
        ),
      );
    } else {
      // iOS BGRA8888 or YUV420
      final format =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.bgra8888;

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
  }

  /// Converts a multi-planar Android YUV_420_888 [CameraImage] into contiguous NV21 byte buffer.
  static Uint8List _convertYuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // 1. Copy Y plane, removing row padding if present
    final Plane yPlane = image.planes[0];
    final Uint8List yBuffer = yPlane.bytes;
    final int yRowStride = yPlane.bytesPerRow;

    int nv21Index = 0;
    for (int row = 0; row < height; row++) {
      final int rowStart = row * yRowStride;
      for (int col = 0; col < width; col++) {
        nv21[nv21Index++] = yBuffer[rowStart + col];
      }
    }

    // 2. Interleave V and U bytes (NV21 requires V then U)
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final Uint8List uBuffer = uPlane.bytes;
    final Uint8List vBuffer = vPlane.bytes;

    final int uRowStride = uPlane.bytesPerRow;
    final int vRowStride = vPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < height ~/ 2; row++) {
      final int uRowStart = row * uRowStride;
      final int vRowStart = row * vRowStride;
      for (int col = 0; col < width ~/ 2; col++) {
        final int uIndex = uRowStart + col * uPixelStride;
        final int vIndex = vRowStart + col * vPixelStride;
        nv21[nv21Index++] = vBuffer[vIndex];
        nv21[nv21Index++] = uBuffer[uIndex];
      }
    }

    return nv21;
  }

  void dispose() {
    _poseDetector.close();
    squatLandmarksNotifier.dispose();
    pushUpLandmarksNotifier.dispose();
    poseStatusNotifier.dispose();
  }
}
