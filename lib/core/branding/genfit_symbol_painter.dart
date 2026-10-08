import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pure vector custom painter rendering the original GenFit symbol:
/// "A dynamic human athlete integrated into the letter G."
///
/// Geometric breakdown:
/// - The athlete's soaring, forward-leaping movement arc forms the sweeping outer perimeter of the "G".
/// - The athletic head and driving torso form the upper crest and apex of the "G".
/// - The trailing leg forms the lower sweeping bowl and foundation of the "G".
/// - The explosive forward knee-drive and outstretched arm form the iconic horizontal spur and crossbar of the "G".
/// - Precise negative-space channels create dynamic motion lines while keeping the letter G instantly recognizable at all scales.
class GenfitSymbolPainter extends CustomPainter {
  final Color primaryColor;
  final Color? secondaryColor;
  final double animationProgress;

  const GenfitSymbolPainter({
    this.primaryColor = AppColors.primary,
    this.secondaryColor,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final progress = animationProgress.clamp(0.0, 1.0);

    final Paint fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint accentPaint = Paint()
      ..color = secondaryColor ?? primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Apply animation transform (scale & reveal)
    canvas.save();
    if (progress < 1.0) {
      final double scale = 0.85 + (0.15 * progress);
      canvas.translate(w / 2, h / 2);
      canvas.scale(scale);
      canvas.translate(-w / 2, -h / 2);
    }

    // =========================================================================
    // 1. ATHLETE HEAD (Floating athletic circular apex at upper center)
    // =========================================================================
    final double headCenterX = w * 0.49;
    final double headCenterY = h * 0.17;
    final double headRadius =
        w * 0.078 * (progress < 0.3 ? progress / 0.3 : 1.0);

    canvas.drawCircle(
      Offset(headCenterX, headCenterY),
      headRadius,
      accentPaint,
    );

    // =========================================================================
    // 2. MAIN "G" + ATHLETE TORSO & UPPER MOVEMENT ARC
    // The upper curve of the G sweeping over the athlete's shoulders down to the left flank
    // =========================================================================
    final Path upperGPath = Path();
    upperGPath.moveTo(w * 0.82, h * 0.20);
    // Outer upper sweep of the G
    upperGPath.cubicTo(
      w * 0.65,
      h * 0.05,
      w * 0.35,
      h * 0.06,
      w * 0.17,
      h * 0.24,
    );
    // Outer left flank
    upperGPath.cubicTo(
      w * 0.07,
      h * 0.36,
      w * 0.07,
      h * 0.58,
      w * 0.15,
      h * 0.70,
    );
    // Left inner tuck
    upperGPath.lineTo(w * 0.26, h * 0.62);
    // Inner left curve
    upperGPath.cubicTo(
      w * 0.20,
      h * 0.52,
      w * 0.21,
      h * 0.38,
      w * 0.28,
      h * 0.30,
    );
    // Athlete's muscular arched back & shoulders
    upperGPath.cubicTo(
      w * 0.37,
      h * 0.21,
      w * 0.55,
      h * 0.18,
      w * 0.70,
      h * 0.27,
    );
    // Upper aerodynamic fin cut
    upperGPath.lineTo(w * 0.82, h * 0.20);
    upperGPath.close();

    canvas.drawPath(upperGPath, fillPaint);

    // =========================================================================
    // 3. LOWER "G" BOWL & ATHLETE'S POWERFUL TRAILING LEG
    // Sweeps from the core through the lower foundation curve to the right upright
    // =========================================================================
    final Path lowerGPath = Path();
    lowerGPath.moveTo(w * 0.18, h * 0.68);
    // Outer bottom sweep
    lowerGPath.cubicTo(
      w * 0.25,
      h * 0.84,
      w * 0.44,
      h * 0.94,
      w * 0.68,
      h * 0.93,
    );
    // Curve into the right upright base
    lowerGPath.cubicTo(
      w * 0.82,
      h * 0.92,
      w * 0.90,
      h * 0.82,
      w * 0.91,
      h * 0.68,
    );
    // Outer right upright ascending
    lowerGPath.lineTo(w * 0.91, h * 0.48);
    // Top right edge of the G upright
    lowerGPath.lineTo(w * 0.79, h * 0.48);
    // Inner right corner
    lowerGPath.lineTo(w * 0.79, h * 0.66);
    // Inner bottom curve
    lowerGPath.cubicTo(
      w * 0.78,
      h * 0.76,
      w * 0.66,
      h * 0.82,
      w * 0.52,
      h * 0.81,
    );
    // Inner sweep towards the trailing leg kick
    lowerGPath.cubicTo(
      w * 0.38,
      h * 0.80,
      w * 0.28,
      h * 0.73,
      w * 0.25,
      h * 0.63,
    );
    lowerGPath.close();

    canvas.drawPath(lowerGPath, fillPaint);

    // =========================================================================
    // 4. THE ATHLETE'S FORWARD KNEE-DRIVE & "G" CROSSBAR SPUR
    // A bold, aerodynamic wedge driving horizontally inward and upward
    // =========================================================================
    final Path spurPath = Path();
    // Athlete's core hip hinge
    spurPath.moveTo(w * 0.38, h * 0.48);
    // Driving leg / torso thrust angled toward the G center
    spurPath.lineTo(w * 0.52, h * 0.40);
    // Crossbar top horizontal edge
    spurPath.lineTo(w * 0.88, h * 0.40);
    // Right cap angled back
    spurPath.lineTo(w * 0.84, h * 0.53);
    // Crossbar bottom edge returning inward
    spurPath.lineTo(w * 0.54, h * 0.53);
    // Inner knee tuck
    spurPath.lineTo(w * 0.42, h * 0.58);
    spurPath.close();

    canvas.drawPath(spurPath, accentPaint);

    // =========================================================================
    // 5. ATHLETIC ENERGY SLASH (Negative space & speed accent)
    // Small dynamic diamond / chevron between the torso and crossbar
    // =========================================================================
    final Path dynamicWing = Path();
    dynamicWing.moveTo(w * 0.48, h * 0.28);
    dynamicWing.lineTo(w * 0.56, h * 0.34);
    dynamicWing.lineTo(w * 0.46, h * 0.37);
    dynamicWing.close();

    canvas.drawPath(dynamicWing, accentPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GenfitSymbolPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.animationProgress != animationProgress;
  }
}
