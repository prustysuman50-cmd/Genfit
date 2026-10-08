import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'genfit_symbol.dart';

/// The official GenFit App Icon component.
///
/// Specifications:
/// - Dark background (#0B0F14 Deep Midnight)
/// - Crisp GenFit Lime (#B8F35A) Athlete + G symbol centered
/// - Restrained 1px #29313A border
/// - Athletic squircle curvature
/// - Strictly NO wordmark inside the app icon
class GenfitAppIcon extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool hasBorder;

  const GenfitAppIcon({
    super.key,
    this.size = 64.0,
    this.borderRadius,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? (size * 0.22);
    final symbolSize = size * 0.58;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: hasBorder
            ? Border.all(color: AppColors.dividerDark, width: 1.0)
            : null,
      ),
      alignment: Alignment.center,
      child: GenfitSymbol(
        size: symbolSize,
        color: AppColors.primary,
        secondaryColor: AppColors.primaryDark,
      ),
    );
  }
}
