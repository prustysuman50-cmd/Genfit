import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'genfit_symbol.dart';
import 'genfit_wordmark.dart';

/// The official GenFit combined logo lockup widget.
/// Combines the Athlete+G Symbol, Wordmark ("GenFit"), and optional Tagline.
class GenfitLogo extends StatelessWidget {
  final Axis axis;
  final double symbolSize;
  final double wordmarkSize;
  final bool showTagline;
  final bool isMonochrome;
  final Color? symbolColor;
  final Color? textColor;
  final double spacing;
  final double animationProgress;

  static const String officialTagline =
      'Smarter Fitness. Local Fuel. Stronger Campus.';

  const GenfitLogo({
    super.key,
    this.axis = Axis.horizontal,
    this.symbolSize = 36.0,
    this.wordmarkSize = 22.0,
    this.showTagline = false,
    this.isMonochrome = false,
    this.symbolColor,
    this.textColor,
    this.spacing = 10.0,
    this.animationProgress = 1.0,
  });

  /// Convenient vertical lockup for splash and welcome screens
  const GenfitLogo.vertical({
    super.key,
    this.symbolSize = 76.0,
    this.wordmarkSize = 34.0,
    this.showTagline = true,
    this.isMonochrome = false,
    this.symbolColor,
    this.textColor,
    this.spacing = 16.0,
    this.animationProgress = 1.0,
  }) : axis = Axis.vertical;

  /// Convenient compact horizontal lockup for app headers and navigation
  const GenfitLogo.horizontal({
    super.key,
    this.symbolSize = 28.0,
    this.wordmarkSize = 20.0,
    this.showTagline = false,
    this.isMonochrome = false,
    this.symbolColor,
    this.textColor,
    this.spacing = 8.0,
    this.animationProgress = 1.0,
  }) : axis = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final symbol = GenfitSymbol(
      size: symbolSize,
      color: symbolColor,
      isMonochrome: isMonochrome,
      animationProgress: animationProgress,
    );

    final wordmark = GenfitWordmark(fontSize: wordmarkSize, color: textColor);

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          symbol,
          SizedBox(width: spacing),
          wordmark,
        ],
      );
    }

    // Vertical lockup
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        symbol,
        SizedBox(height: spacing),
        wordmark,
        if (showTagline) ...[
          const SizedBox(height: 8),
          const Text(
            officialTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.2,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
