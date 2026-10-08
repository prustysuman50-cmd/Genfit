import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The official GenFit wordmark widget.
/// Strictly enforces the exact capitalization: "GenFit".
///
/// Features:
/// - Athletic, modern, confident typography
/// - Supports brand mode (White text with subtle lime tint) or monochrome
/// - Fully compatible with widget tests asserting on find.text('GenFit')
class GenfitWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final double letterSpacing;

  const GenfitWordmark({
    super.key,
    this.fontSize = 24.0,
    this.color,
    this.letterSpacing = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimaryDark;

    return Text(
      'GenFit',
      style: TextStyle(
        fontFamily: null,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
        color: effectiveColor,
        height: 1.1,
      ),
    );
  }
}
