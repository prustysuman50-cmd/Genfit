import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'genfit_symbol_painter.dart';

/// The official GenFit symbol widget:
/// "A dynamic human athlete integrated into the letter G."
///
/// Features:
/// - Scalable vector geometry via CustomPainter
/// - Supports brand palette (#B8F35A / #7ED957), white, or custom monochrome
/// - Crisp and recognizable at 20px, 48px, 96px, and 256px
class GenfitSymbol extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final bool isMonochrome;
  final double animationProgress;

  const GenfitSymbol({
    super.key,
    this.size = 48.0,
    this.color,
    this.secondaryColor,
    this.isMonochrome = false,
    this.animationProgress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = color ?? AppColors.primary;
    final effectiveSecondary = isMonochrome
        ? effectivePrimary
        : (secondaryColor ?? AppColors.primaryDark);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: GenfitSymbolPainter(
          primaryColor: effectivePrimary,
          secondaryColor: effectiveSecondary,
          animationProgress: animationProgress,
        ),
      ),
    );
  }
}
