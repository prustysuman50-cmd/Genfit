import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// An elegant, athletic circular or open-arc meter for visualizing
/// fitness metrics (Calories, Steps, Water, Active Time, Progress).
class MetricArcMeter extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String valueText;
  final String label;
  final String? unit;
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;
  final bool isOpenArc; // If true, renders a 240-degree open gauge
  final Widget? customCenter;

  const MetricArcMeter({
    super.key,
    required this.progress,
    required this.valueText,
    required this.label,
    this.unit,
    this.size = 110.0,
    this.strokeWidth = 7.0,
    this.activeColor = AppColors.brightPurple,
    this.trackColor = AppColors.surfaceElevatedDark,
    this.isOpenArc = true,
    this.customCenter,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0.0, end: clampedProgress),
            builder: (context, val, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _ArcPainter(
                  progress: val,
                  strokeWidth: strokeWidth,
                  activeColor: activeColor,
                  trackColor: trackColor,
                  isOpenArc: isOpenArc,
                ),
              );
            },
          ),
          if (customCenter != null)
            customCenter!
          else
            Padding(
              padding: EdgeInsets.only(top: isOpenArc ? strokeWidth * 0.5 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    valueText,
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryDark,
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      unit!,
                      style: TextStyle(
                        fontSize: size * 0.09,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                        height: 1.0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: size * 0.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;
  final bool isOpenArc;

  const _ArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
    required this.isOpenArc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final startAngle = isOpenArc ? (math.pi * 0.75) : -math.pi / 2;
    final totalSweep = isOpenArc ? (math.pi * 1.5) : (math.pi * 2);
    final activeSweep = totalSweep * progress;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Active progress arc
    if (activeSweep > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
