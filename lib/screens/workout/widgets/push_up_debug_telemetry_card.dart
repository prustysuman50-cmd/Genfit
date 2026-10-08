import 'package:flutter/material.dart';

import '../../../core/services/push_up_analysis_service.dart';
import '../../../core/theme/app_colors.dart';

/// Temporary real-time diagnostic telemetry HUD card for Push-Up AI detection.
///
/// Easily removable after debugging. Displays live angles, coordinates, torso displacement,
/// plank status, blocking conditions, transition attempts, and active thresholds.
class PushUpDebugTelemetryCard extends StatefulWidget {
  final PushUpAnalysisService service;

  const PushUpDebugTelemetryCard({super.key, required this.service});

  @override
  State<PushUpDebugTelemetryCard> createState() =>
      _PushUpDebugTelemetryCardState();
}

class _PushUpDebugTelemetryCardState extends State<PushUpDebugTelemetryCard> {
  bool _isThresholdsExpanded = false;

  Color _stateColor(PushUpState state) {
    switch (state) {
      case PushUpState.top:
        return AppColors.accentCyan;
      case PushUpState.down:
        return AppColors.success;
    }
  }

  String _formatCoord(double? x, double? y) {
    if (x == null || y == null) return 'N/A';
    return '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
  }

  @override
  Widget build(BuildContext context) {
    final thresholds = widget.service.thresholds;

    return ValueListenableBuilder<PushUpTelemetryData>(
      valueListenable: widget.service.telemetryNotifier,
      builder: (context, data, _) {
        final stateColor = _stateColor(data.state);
        final bool isAccepted = data.lastTransitionLog.contains('ACCEPTED');
        final bool isAborted =
            data.lastTransitionLog.contains('ABORTED') ||
            data.lastTransitionLog.contains('RE-SANK');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF090E17),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentCyan.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.8),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PUSH-UP AI DIAGNOSTICS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.cardBorderDark,
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'REAL-TIME DEBUG',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. State & Plank Status Badges
              Row(
                children: [
                  // Current PushUpState
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: stateColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT STATE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.state.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: stateColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Top-Plank Prerequisite Status
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (data.hasEstablishedTopPlank
                                    ? AppColors.success
                                    : AppColors.accentOrange)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              (data.hasEstablishedTopPlank
                                      ? AppColors.success
                                      : AppColors.accentOrange)
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOP PLANK READY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.hasEstablishedTopPlank
                                ? 'ESTABLISHED'
                                : 'AWAITING PLANK',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: data.hasEstablishedTopPlank
                                  ? AppColors.success
                                  : AppColors.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Transition Attempt Evaluation Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.success.withValues(alpha: 0.08)
                      : (isAborted
                            ? AppColors.accentOrange.withValues(alpha: 0.08)
                            : const Color(0xFF131D30)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAccepted
                        ? AppColors.success.withValues(alpha: 0.3)
                        : (isAborted
                              ? AppColors.accentOrange.withValues(alpha: 0.3)
                              : AppColors.cardBorderDark),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAST TRANSITION ATTEMPT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.lastTransitionLog,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: isAccepted
                            ? AppColors.success
                            : (isAborted
                                  ? AppColors.accentOrange
                                  : AppColors.textPrimaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 4. Blocking Condition Callout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT BLOCKING CONDITION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.blockingCondition,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimaryDark,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 5. Real-Time Telemetry Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1728),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    // Row A: Elbow Angles
                    _buildTelemetryRow(
                      label1: 'Left Elbow',
                      val1: data.leftElbowAngle != null
                          ? '${data.leftElbowAngle!.toStringAsFixed(1)}°'
                          : 'N/A',
                      label2: 'Right Elbow',
                      val2: data.rightElbowAngle != null
                          ? '${data.rightElbowAngle!.toStringAsFixed(1)}°'
                          : 'N/A',
                    ),
                    const Divider(color: AppColors.cardBorderDark, height: 12),

                    // Row B: Selected / Smoothed Angles
                    _buildTelemetryRow(
                      label1: 'Selected Angle',
                      val1: data.rawElbowAngle != null
                          ? '${data.rawElbowAngle!.toStringAsFixed(1)}°'
                          : 'N/A',
                      label2: 'Smoothed EMA',
                      val2: data.smoothedElbowAngle != null
                          ? '${data.smoothedElbowAngle!.toStringAsFixed(1)}°'
                          : 'N/A',
                    ),
                    const Divider(color: AppColors.cardBorderDark, height: 12),

                    // Row C: Torso Length & Body Alignment
                    _buildTelemetryRow(
                      label1: 'Torso Length',
                      val1: data.torsoLength != null
                          ? '${data.torsoLength!.toStringAsFixed(1)} px'
                          : 'N/A',
                      label2: 'Body Alignment',
                      val2: widget.service.rawBodyAlignmentAngle != null
                          ? '${widget.service.rawBodyAlignmentAngle!.toStringAsFixed(1)}°'
                          : 'N/A',
                      val2Color:
                          (widget.service.rawBodyAlignmentAngle ?? 0) >=
                              thresholds.bodyAlignmentThreshold
                          ? AppColors.success
                          : AppColors.accentOrange,
                    ),
                    const Divider(color: AppColors.cardBorderDark, height: 12),

                    // Row D: Confidence & State
                    _buildTelemetryRow(
                      label1: 'Avg Confidence',
                      val1:
                          '${(data.averageConfidence * 100).toStringAsFixed(1)}%',
                      val1Color:
                          data.averageConfidence >=
                              thresholds.minLandmarkConfidence
                          ? AppColors.success
                          : AppColors.accentOrange,
                      label2: 'Phase',
                      val2: data.state.displayName.toUpperCase(),
                    ),
                    const Divider(color: AppColors.cardBorderDark, height: 12),

                    // Row E: Coordinates
                    _buildTelemetryRow(
                      label1: 'Left Shoulder',
                      val1: _formatCoord(
                        data.leftShoulderX,
                        data.leftShoulderY,
                      ),
                      label2: 'Right Shoulder',
                      val2: _formatCoord(
                        data.rightShoulderX,
                        data.rightShoulderY,
                      ),
                    ),
                    const Divider(color: AppColors.cardBorderDark, height: 12),

                    _buildTelemetryRow(
                      label1: 'Left Hip',
                      val1: _formatCoord(data.leftHipX, data.leftHipY),
                      label2: 'Right Hip',
                      val2: _formatCoord(data.rightHipX, data.rightHipY),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 6. Active Thresholds Reference Drawer (Collapsible)
              InkWell(
                onTap: () {
                  setState(() {
                    _isThresholdsExpanded = !_isThresholdsExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: AppColors.accentCyan,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ACTIVE THRESHOLDS REFERENCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isThresholdsExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.textMutedDark,
                      ),
                    ],
                  ),
                ),
              ),

              if (_isThresholdsExpanded) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1322),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: Column(
                    children: [
                      _buildThresholdRow(
                        'Top Elbow Angle (Extended)',
                        '>= ${thresholds.topAngleThreshold.toStringAsFixed(0)}°',
                      ),
                      _buildThresholdRow(
                        'Down Elbow Angle (Bent)',
                        '<= ${thresholds.downAngleThreshold.toStringAsFixed(0)}°',
                      ),
                      _buildThresholdRow(
                        'Body Alignment (Plank)',
                        '>= ${thresholds.bodyAlignmentThreshold.toStringAsFixed(0)}°',
                      ),
                      _buildThresholdRow(
                        'Min Landmark Confidence',
                        '>= ${(thresholds.minLandmarkConfidence * 100).toStringAsFixed(0)}%',
                      ),
                      _buildThresholdRow(
                        'Min Rep Cooldown Debounce',
                        '${thresholds.minRepCooldown.inMilliseconds} ms',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTelemetryRow({
    required String label1,
    required String val1,
    Color? val1Color,
    required String label2,
    required String val2,
    Color? val2Color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                val1,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: val1Color ?? AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                val2,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: val2Color ?? AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondaryDark,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: AppColors.accentCyan,
            ),
          ),
        ],
      ),
    );
  }
}
