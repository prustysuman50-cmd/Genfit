import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../models/daily_metric.dart';

class MetricSummaryCards extends StatelessWidget {
  final DailyMetrics metrics;
  final VoidCallback? onAddWater;
  final VoidCallback? onLogSteps;

  const MetricSummaryCards({
    super.key,
    required this.metrics,
    this.onAddWater,
    this.onLogSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Steps Walked',
                value: metrics.steps.toString(),
                unit: '/ ${metrics.stepsGoal}',
                progress: metrics.stepsProgress,
                icon: Icons.directions_walk_rounded,
                accentColor: AppColors.primary,
                onQuickAdd: onLogSteps,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Active Calories',
                value: metrics.caloriesBurned.toString(),
                unit: '/ ${metrics.caloriesGoal} kcal',
                progress: metrics.caloriesProgress,
                icon: Icons.local_fire_department_rounded,
                accentColor: AppColors.accentOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Hydration',
                value: metrics.waterLiters.toStringAsFixed(1),
                unit: '/ ${metrics.waterGoalLiters.toStringAsFixed(1)} L',
                progress: metrics.waterProgress,
                icon: Icons.water_drop_rounded,
                accentColor: AppColors.accentCyan,
                onQuickAdd: onAddWater,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Active Time',
                value: metrics.activeMinutes.toString(),
                unit: '/ ${metrics.activeMinutesGoal} min',
                progress: metrics.activeProgress,
                icon: Icons.timer_rounded,
                accentColor: AppColors.accentPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
