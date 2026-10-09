import 'package:flutter/material.dart';

import '../../../core/services/step_tracking_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/daily_metric.dart';
import '../../../models/daily_stats.dart';

class DailyProgressCard extends StatelessWidget {
  final DailyStats? stats;
  final DailyMetrics? metrics;
  final VoidCallback? onAddWater;
  final VoidCallback? onLogSteps;

  const DailyProgressCard({
    super.key,
    this.stats,
    this.metrics,
    this.onAddWater,
    this.onLogSteps,
  }) : assert(
         stats != null || metrics != null,
         'Either stats or metrics must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final int overallPercent;
    final int waterMl;
    final int waterGoalMl;
    final double waterProgress;
    final int steps;
    final int stepsGoal;
    final double stepsProgress;
    final int caloriesBurned;
    final int caloriesGoal;
    final double caloriesProgress;
    final int activeMinutes;
    final int activeMinutesGoal;
    final double activeProgress;

    if (stats != null) {
      overallPercent = (stats!.overallProgress * 100).toInt();
      waterMl = stats!.waterMl;
      waterGoalMl = stats!.waterGoalMl;
      waterProgress = stats!.waterProgress;
      steps = stats!.steps;
      stepsGoal = stats!.stepsGoal;
      stepsProgress = stats!.stepsProgress;
      caloriesBurned = stats!.caloriesBurned;
      caloriesGoal = stats!.caloriesBurnedGoal;
      caloriesProgress = stats!.caloriesBurnedProgress;
      activeMinutes = stats!.activeMinutes;
      activeMinutesGoal = stats!.activeMinutesGoal;
      activeProgress = stats!.activeMinutesProgress;
    } else {
      final m = metrics!;
      overallPercent = (m.overallProgress * 100).toInt();
      waterMl = (m.waterLiters * 1000).toInt();
      waterGoalMl = (m.waterGoalLiters * 1000).toInt();
      waterProgress = m.waterProgress;
      steps = m.steps;
      stepsGoal = m.stepsGoal;
      stepsProgress = m.stepsProgress;
      caloriesBurned = m.caloriesBurned;
      caloriesGoal = m.caloriesGoal;
      caloriesProgress = m.caloriesProgress;
      activeMinutes = m.activeMinutes;
      activeMinutesGoal = m.activeMinutesGoal;
      activeProgress = m.activeProgress;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryDark,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Campus activity & wellness targets',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brightPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$overallPercent% TARGET',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brightPurple,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Asymmetric Dashboard Layout:
        // Left: Large Radial Card for Steps with Circular Gauge
        // Right: 2 Stacked Modern Cards for Water and Calories
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Hero Metric: STEPS (with Radial Gauge)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorderDark, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.brightPurple.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            size: 16,
                            color: AppColors.brightPurple,
                          ),
                        ),
                        if (onLogSteps != null)
                          GestureDetector(
                            onTap: onLogSteps,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.cardBorderDark,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 12,
                                color: AppColors.brightPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Centered Circular Gauge
                    Center(
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 86,
                              height: 86,
                              child: CircularProgressIndicator(
                                value: stepsProgress.clamp(0.0, 1.0),
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                backgroundColor: AppColors.surfaceElevatedDark,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brightPurple,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$steps',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimaryDark,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'STEPS',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondaryDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Target $stepsGoal',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: _buildSensorStatusBadge(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right Column: Water, Calories, Active Time
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // Water Card
                  _buildSideMetricTile(
                    title: 'WATER',
                    value: '$waterMl ml',
                    target: 'Target $waterGoalMl ml',
                    progress: waterProgress,
                    icon: Icons.water_drop_rounded,
                    accentColor: AppColors.accentCyan,
                    onAdd: onAddWater,
                  ),
                  const SizedBox(height: 10),

                  // Calories Card
                  _buildSideMetricTile(
                    title: 'CALORIES',
                    value: '$caloriesBurned kcal',
                    target: 'Target $caloriesGoal kcal',
                    progress: caloriesProgress,
                    icon: Icons.local_fire_department_rounded,
                    accentColor: AppColors.accentOrange,
                  ),
                  const SizedBox(height: 10),

                  // Active Time Card
                  _buildSideMetricTile(
                    title: 'ACTIVE TIME',
                    value: '$activeMinutes min',
                    target: 'Target $activeMinutesGoal min',
                    progress: activeProgress,
                    icon: Icons.timer_rounded,
                    accentColor: AppColors.softPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSideMetricTile({
    required String title,
    required String value,
    required String target,
    required double progress,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: accentColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ Log',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                flex: 4,
                child: Text(
                  target,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMutedDark,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surfaceElevatedDark,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatusBadge(BuildContext context) {
    final tracker = StepTrackingService.instance;
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final String label;
        final Color color;
        final IconData icon;

        if (tracker.currentMode == StepTrackingMode.demoSimulation) {
          label = '⚡ Demo Mode';
          color = const Color(0xFFFFB74D);
          icon = Icons.bolt_rounded;
        } else if (!tracker.isSensorAvailable) {
          label = '⚠ Sensor Unavailable';
          color = const Color(0xFFEF5350);
          icon = Icons.warning_amber_rounded;
        } else if (tracker.sensorStatus == StepSensorStatus.permissionDenied ||
            tracker.sensorStatus ==
                StepSensorStatus.permissionPermanentlyDenied) {
          label = '🔒 Permission Needed';
          color = const Color(0xFFFFB74D);
          icon = Icons.lock_outline_rounded;
        } else {
          label = '🟢 Live Sensor';
          color = const Color(0xFF4CAF50);
          icon = Icons.sensors_rounded;
        }

        return GestureDetector(
          onTap: onLogSteps,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 9, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
