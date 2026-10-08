import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/services/pose_detection_service.dart';
import '../../../core/theme/app_colors.dart';
import '../models/exercise.dart';

class AiViewfinderPreview extends StatelessWidget {
  final bool isTracking;
  final Exercise exercise;
  final String formStatus;
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final bool isPermissionDenied;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onFlipCamera;
  final SquatLandmarks? squatLandmarks;
  final PushUpLandmarks? pushUpLandmarks;

  const AiViewfinderPreview({
    super.key,
    required this.isTracking,
    required this.exercise,
    required this.formStatus,
    this.cameraController,
    this.isCameraInitialized = false,
    this.isPermissionDenied = false,
    this.onRequestPermission,
    this.onFlipCamera,
    this.squatLandmarks,
    this.pushUpLandmarks,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLiveCamera =
        isCameraInitialized &&
        cameraController != null &&
        cameraController!.value.isInitialized;

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1424),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTracking
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.cardBorderDark,
          width: isTracking ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isTracking)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Live Camera Preview with synchronized Skeleton Overlay
            if (hasLiveCamera)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.previewSize?.height ?? 240,
                  height: cameraController!.value.previewSize?.width ?? 240,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(cameraController!),
                      if (exercise.id == 'ex_pushups' &&
                          pushUpLandmarks != null)
                        CustomPaint(
                          painter: _PushUpSkeletonPainter(
                            landmarks: pushUpLandmarks!,
                            previewSize: cameraController!.value.previewSize,
                            isFrontCamera:
                                cameraController!.description.lensDirection ==
                                CameraLensDirection.front,
                          ),
                        )
                      else if (squatLandmarks != null)
                        CustomPaint(
                          painter: _SquatSkeletonPainter(
                            landmarks: squatLandmarks!,
                            previewSize: cameraController!.value.previewSize,
                            isFrontCamera:
                                cameraController!.description.lensDirection ==
                                CameraLensDirection.front,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else if (isPermissionDenied)
              _buildPermissionDeniedView(context)
            else
              _buildStandbyGraphic(),

            // 2. Real-time Squat Landmarks Skeleton Overlay (handled inside FittedBox above)

            // 3. Subtle Viewfinder Grid lines (when in standby or tracking)
            if (!hasLiveCamera && !isPermissionDenied)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ViewfinderGridPainter(isTracking: isTracking),
                ),
              ),

            // 4. Top Status Bar in Viewfinder
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tracking status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTracking
                            ? AppColors.primary
                            : (hasLiveCamera
                                  ? AppColors.accentCyan
                                  : AppColors.textMutedDark),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTracking
                                ? AppColors.primary
                                : (hasLiveCamera
                                      ? AppColors.accentCyan
                                      : Colors.grey),
                            boxShadow: isTracking
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isTracking
                              ? 'VISION AI TRACKING'
                              : (hasLiveCamera
                                    ? 'CAMERA READY'
                                    : 'PREVIEW MODE'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isTracking
                                ? AppColors.primary
                                : (hasLiveCamera
                                      ? AppColors.accentCyan
                                      : AppColors.textMutedDark),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Camera switch / flip button
                  if (onFlipCamera != null)
                    InkWell(
                      onTap: onFlipCamera,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorderDark),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flip_camera_ios_rounded,
                              size: 14,
                              color: AppColors.textPrimaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cameraController?.description.lensDirection ==
                                      CameraLensDirection.front
                                  ? 'Front'
                                  : 'Rear',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 5. Bottom Viewfinder Telemetry
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exercise.id == 'ex_pushups' &&
                              pushUpLandmarks != null &&
                              pushUpLandmarks!.hasSufficientPushUpPoints
                          ? 'Push-up Points: Shoulders, Arms, Hips, Ankles'
                          : (squatLandmarks != null &&
                                    squatLandmarks!.hasSufficientSquatPoints
                                ? 'Squat Points: Shoulders, Hips, Knees, Ankles'
                                : 'Target: ${exercise.targetMuscles}'),
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            (exercise.id == 'ex_pushups' &&
                                    pushUpLandmarks != null &&
                                    pushUpLandmarks!
                                        .hasSufficientPushUpPoints) ||
                                (squatLandmarks != null &&
                                    squatLandmarks!.hasSufficientSquatPoints)
                            ? AppColors.primary
                            : AppColors.textMutedDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark.withValues(
                        alpha: 0.85,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      '30 FPS • On-Device',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 6. HUD Viewfinder Corners
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HudCornersPainter(
                    color: isTracking
                        ? AppColors.primary
                        : AppColors.cardBorderDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandbyGraphic() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTracking
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceElevatedDark.withValues(alpha: 0.6),
              border: Border.all(
                color: isTracking
                    ? AppColors.primary
                    : AppColors.cardBorderDark,
                width: 1.5,
              ),
            ),
            child: Icon(
              exercise.icon,
              size: 38,
              color: isTracking
                  ? AppColors.primary
                  : AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isTracking
                ? 'AI Tracking Active: ${exercise.name}'
                : 'Camera Standby: ${exercise.name}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isTracking
                  ? AppColors.primary
                  : AppColors.textSecondaryDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: AppColors.accentOrange,
              size: 38,
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera Access Needed',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enable camera access for on-device AI pose tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 12),
            if (onRequestPermission != null)
              ElevatedButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Enable Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for real-time detected squat skeleton landmarks.
class _SquatSkeletonPainter extends CustomPainter {
  final SquatLandmarks landmarks;
  final Size? previewSize;
  final bool isFrontCamera;

  static int _paintLogCount = 0;

  _SquatSkeletonPainter({
    required this.landmarks,
    required this.previewSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double camWidth = previewSize?.height ?? size.width;
    final double camHeight = previewSize?.width ?? size.height;

    // Coordinate mapping helper
    Offset? mapPoint(PoseLandmark? lm) {
      if (lm == null) return null;

      double x = (lm.x / camWidth) * size.width;
      double y = (lm.y / camHeight) * size.height;

      // Mirror horizontally for front selfie camera
      if (isFrontCamera) {
        x = size.width - x;
      }

      return Offset(x.clamp(0.0, size.width), y.clamp(0.0, size.height));
    }

    void drawBone(Offset? p1, Offset? p2) {
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    void drawJoint(Offset? p) {
      if (p != null) {
        canvas.drawCircle(p, 9.0, jointFill);
        canvas.drawCircle(p, 9.0, jointBorder);
      }
    }

    final ls = mapPoint(landmarks.leftShoulder);
    final rs = mapPoint(landmarks.rightShoulder);
    final lh = mapPoint(landmarks.leftHip);
    final rh = mapPoint(landmarks.rightHip);
    final lk = mapPoint(landmarks.leftKnee);
    final rk = mapPoint(landmarks.rightKnee);
    final la = mapPoint(landmarks.leftAnkle);
    final ra = mapPoint(landmarks.rightAnkle);

    _paintLogCount++;
    if (_paintLogCount % 30 == 1) {
      debugPrint(
        '[GENFIT PAINTER] Case C check: CustomPainter rendering skeleton. '
        'Canvas=${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)}, '
        'camSize=${camWidth.toStringAsFixed(0)}x${camHeight.toStringAsFixed(0)}, '
        'LKnee=(${lk?.dx.toStringAsFixed(1)}, ${lk?.dy.toStringAsFixed(1)}), '
        'RKnee=(${rk?.dx.toStringAsFixed(1)}, ${rk?.dy.toStringAsFixed(1)}), '
        'isFront=$isFrontCamera',
      );
    }

    // Torso & Shoulders
    drawBone(ls, rs);
    drawBone(ls, lh);
    drawBone(rs, rh);
    drawBone(lh, rh);

    // Left Leg (Squat)
    drawBone(lh, lk);
    drawBone(lk, la);

    // Right Leg (Squat)
    drawBone(rh, rk);
    drawBone(rk, ra);

    // Joints
    drawJoint(ls);
    drawJoint(rs);
    drawJoint(lh);
    drawJoint(rh);
    drawJoint(lk);
    drawJoint(rk);
    drawJoint(la);
    drawJoint(ra);
  }

  @override
  bool shouldRepaint(covariant _SquatSkeletonPainter oldDelegate) {
    return true;
  }
}

/// Custom painter for real-time detected push-up skeleton landmarks.
class _PushUpSkeletonPainter extends CustomPainter {
  final PushUpLandmarks landmarks;
  final Size? previewSize;
  final bool isFrontCamera;

  _PushUpSkeletonPainter({
    required this.landmarks,
    required this.previewSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double camWidth = previewSize?.height ?? size.width;
    final double camHeight = previewSize?.width ?? size.height;

    // Coordinate mapping helper
    Offset? mapPoint(PoseLandmark? lm) {
      if (lm == null) return null;

      double x = (lm.x / camWidth) * size.width;
      double y = (lm.y / camHeight) * size.height;

      // Mirror horizontally for front selfie camera
      if (isFrontCamera) {
        x = size.width - x;
      }

      return Offset(x.clamp(0.0, size.width), y.clamp(0.0, size.height));
    }

    void drawBone(Offset? p1, Offset? p2) {
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    void drawJoint(Offset? p) {
      if (p != null) {
        canvas.drawCircle(p, 9.0, jointFill);
        canvas.drawCircle(p, 9.0, jointBorder);
      }
    }

    final ls = mapPoint(landmarks.leftShoulder);
    final rs = mapPoint(landmarks.rightShoulder);
    final le = mapPoint(landmarks.leftElbow);
    final re = mapPoint(landmarks.rightElbow);
    final lw = mapPoint(landmarks.leftWrist);
    final rw = mapPoint(landmarks.rightWrist);
    final lh = mapPoint(landmarks.leftHip);
    final rh = mapPoint(landmarks.rightHip);
    final lk = mapPoint(landmarks.leftKnee);
    final rk = mapPoint(landmarks.rightKnee);
    final la = mapPoint(landmarks.leftAnkle);
    final ra = mapPoint(landmarks.rightAnkle);

    // Torso & Shoulders
    drawBone(ls, rs);
    drawBone(ls, lh);
    drawBone(rs, rh);
    drawBone(lh, rh);

    // Left Arm (Push-up)
    drawBone(ls, le);
    drawBone(le, lw);

    // Right Arm (Push-up)
    drawBone(rs, re);
    drawBone(re, rw);

    // Body Line / Legs
    drawBone(lh, lk ?? la);
    drawBone(rh, rk ?? ra);
    if (lk != null && la != null) drawBone(lk, la);
    if (rk != null && ra != null) drawBone(rk, ra);

    // Joints
    drawJoint(ls);
    drawJoint(rs);
    drawJoint(le);
    drawJoint(re);
    drawJoint(lw);
    drawJoint(rw);
    drawJoint(lh);
    drawJoint(rh);
    drawJoint(lk);
    drawJoint(rk);
    drawJoint(la);
    drawJoint(ra);
  }

  @override
  bool shouldRepaint(covariant _PushUpSkeletonPainter oldDelegate) {
    return true;
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  final bool isTracking;

  _ViewfinderGridPainter({required this.isTracking});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isTracking
          ? AppColors.primary.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.8;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderGridPainter oldDelegate) {
    return oldDelegate.isTracking != isTracking;
  }
}

class _HudCornersPainter extends CustomPainter {
  final Color color;

  _HudCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const cornerLength = 16.0;
    const padding = 10.0;

    // Top Left
    canvas.drawLine(
      const Offset(padding, padding + cornerLength),
      const Offset(padding, padding),
      paint,
    );
    canvas.drawLine(
      const Offset(padding, padding),
      const Offset(padding + cornerLength, padding),
      paint,
    );

    // Top Right
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, padding),
      Offset(size.width - padding, padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding, padding + cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(padding, size.height - padding - cornerLength),
      Offset(padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + cornerLength, size.height - padding),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding - cornerLength),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HudCornersPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
