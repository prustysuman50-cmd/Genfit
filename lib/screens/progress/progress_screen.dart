import 'package:flutter/material.dart';

import '../../core/services/daily_stats_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/journey_service.dart';
import '../../core/services/nutrition_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/progress/progress_summary.dart';
import '../../models/progress/recommendation_item.dart';
import '../gamification/widgets/achievement_gallery_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Your Progress'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ProgressService.instance,
          DailyStatsService.instance,
          RecommendationService.instance,
          GamificationService.instance,
          NutritionService.instance,
          JourneyService.instance,
          UserService.instance,
        ]),
        builder: (context, _) {
          final summary = ProgressService.instance.getSummary();
          final recommendations = RecommendationService.instance
              .getRecommendations();
          final recentActivities = ProgressService.instance
              .getRecentActivities();
          final gamification = GamificationService.instance;

          // Compute overall weekly progress percentage from real active days
          final activeDays = summary.weeklyActivity
              .where((d) => d.activeMinutes > 0 || d.steps > 0)
              .length;
          final calculatedPercent = summary.weeklyActivity.isNotEmpty
              ? ((activeDays / 7.0) * 100).round()
              : 0;
          final weeklyPercent = calculatedPercent;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Header Subtitle
                const Text(
                  'Small steps. Consistent progress.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),

                // 1. HERO WEEKLY PROGRESS RADIAL CARD
                _buildHeroProgressCard(weeklyPercent, summary),
                const SizedBox(height: 20),

                // 2. TOP PERSONALIZED RECOMMENDATION CARD
                if (recommendations.isNotEmpty) ...[
                  _buildRecommendationCard(context, recommendations.first),
                  const SizedBox(height: 22),
                ],

                // 3. WEEKLY OVERVIEW (4-Metric Asymmetric / 2x2 Grid)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brightPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildWeeklyOverviewGrid(summary),
                const SizedBox(height: 24),

                // 4. 7-DAY ACTIVITY VISUALIZATION (Chart)
                Text(
                  '7-Day Activity Chart',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Real activity telemetry across the current calendar week.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                _buildWeeklyChart(summary.weeklyActivity),
                const SizedBox(height: 24),

                // 5. FITNESS MILESTONES & CONSISTENCY
                Text(
                  'Fitness Milestones & Consistency',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFitnessProgressCards(summary),
                const SizedBox(height: 24),

                // 6. ACHIEVEMENTS & BADGES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Achievements & Badges',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${summary.badgesUnlocked} of ${summary.totalBadges} Unlocked',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentYellow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBadgesSection(gamification),
                const SizedBox(height: 24),

                // 7. RECENT ACTIVITY (Timeline style)
                Text(
                  'Recent Activity',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentActivitySection(recentActivities),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. HERO WEEKLY PROGRESS RADIAL CARD
  Widget _buildHeroProgressCard(int weeklyPercent, ProgressSummary summary) {
    final progressFraction = (weeklyPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF22193B), Color(0xFF14141D), Color(0xFF0D0D13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.purpleGlow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Radial progress ring
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progressFraction,
                    strokeWidth: 10,
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
                      '$weeklyPercent%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryDark,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.softPurple,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brightPurple.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: AppColors.brightPurple,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'WEEKLY PROGRESS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brightPurple,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  weeklyPercent >= 70
                      ? 'Great momentum!'
                      : 'Keep pushing daily!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.workoutsCompleted} workouts & ${summary.activeMinutes} mins logged this week.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Personalized Recommendation Card
  Widget _buildRecommendationCard(
    BuildContext context,
    RecommendationItem item,
  ) {
    IconData icon;
    Color accentColor;

    switch (item.iconIdentifier) {
      case 'flame':
        icon = Icons.local_fire_department_rounded;
        accentColor = AppColors.accentOrange;
        break;
      case 'fitness':
        icon = Icons.fitness_center_rounded;
        accentColor = AppColors.primary;
        break;
      case 'nutrition':
        icon = Icons.restaurant_rounded;
        accentColor = AppColors.primary;
        break;
      case 'explore':
        icon = Icons.explore_rounded;
        accentColor = AppColors.accentYellow;
        break;
      default:
        icon = Icons.auto_awesome_rounded;
        accentColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Adaptive Tip',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
          if (item.actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Action: ${item.actionLabel}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  item.actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Weekly 4-Metric Grid (Workouts, Steps, Active Calories, Active Minutes)
  Widget _buildWeeklyOverviewGrid(ProgressSummary summary) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildOverviewCard(
                title: 'Workouts',
                value: '${summary.workoutsCompleted}',
                unit: 'completed',
                icon: Icons.fitness_center_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _buildOverviewCard(
                title: 'Active Calories',
                value: '${summary.activeCalories}',
                unit: 'kcal burned',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accentOrange,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildOverviewCard(
                title: 'Steps',
                value: summary.steps >= 1000
                    ? '${(summary.steps / 1000).toStringAsFixed(1)}k'
                    : '${summary.steps}',
                unit: 'total steps',
                icon: Icons.directions_walk_rounded,
                color: AppColors.accentCyan,
              ),
              const SizedBox(height: 10),
              _buildOverviewCard(
                title: 'Active Minutes',
                value: '${summary.activeMinutes}',
                unit: 'mins trained',
                icon: Icons.timer_rounded,
                color: AppColors.accentYellow,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. 7-Day Activity Chart
  Widget _buildWeeklyChart(List<DailyActivitySummary> weekDays) {
    final maxMinutes = weekDays.fold<int>(
      60,
      (prev, d) => d.activeMinutes > prev ? d.activeMinutes : prev,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekDays.map((day) {
              final heightFraction = maxMinutes > 0
                  ? (day.activeMinutes / maxMinutes).clamp(0.08, 1.0)
                  : 0.08;
              final isToday = day.isToday;
              final hasActivity = day.activeMinutes > 0 || day.steps > 0;

              return Column(
                children: [
                  Text(
                    day.activeMinutes > 0 ? '${day.activeMinutes}m' : '-',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textMutedDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 100,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 20,
                      height: 100 * heightFraction,
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? AppColors.primaryGradient
                            : hasActivity
                            ? const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: hasActivity
                            ? null
                            : AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(color: Colors.white, width: 1.2)
                            : null,
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: AppColors.purpleGlow.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: isToday
                        ? BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Text(
                      day.dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorderDark),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Rest Day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMutedDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 5. Fitness Progress Details (Streak, XP, Level, Journey, Meals)
  Widget _buildFitnessProgressCards(ProgressSummary summary) {
    return Column(
      children: [
        _buildProgressMilestoneRow(
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.accentOrange,
          title: 'Fitness Streak',
          subtitle: '${summary.currentStreak} consecutive active days',
          trailing: '${summary.currentStreak} Days',
          trailingColor: AppColors.accentOrange,
        ),
        const SizedBox(height: 10),
        _buildProgressMilestoneRow(
          icon: Icons.bolt_rounded,
          iconColor: AppColors.accentYellow,
          title: 'Level ${summary.level} • ${summary.levelTitle}',
          subtitle: '${summary.xp} total XP accumulated',
          trailing: '${summary.xp} XP',
          trailingColor: AppColors.accentYellow,
        ),
        const SizedBox(height: 10),
        _buildProgressMilestoneRow(
          icon: Icons.explore_rounded,
          iconColor: AppColors.primary,
          title: 'Odisha Trail Progress',
          subtitle:
              '${(summary.journeyCompletionPercent * 100).toInt()}% of route completed',
          trailing: '${summary.journeyProgressKm.toStringAsFixed(1)} km',
          trailingColor: AppColors.primary,
        ),
        const SizedBox(height: 10),
        _buildProgressMilestoneRow(
          icon: Icons.restaurant_rounded,
          iconColor: AppColors.primary,
          title: 'Mess Nutrition Meals',
          subtitle: 'Logged through mess food database',
          trailing: '${summary.nutritionMealsLogged} Meals',
          trailingColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildProgressMilestoneRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
    required Color trailingColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: trailingColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Achievements Badges Section
  Widget _buildBadgesSection(GamificationService gamification) {
    return AchievementGalleryCard(gamification: gamification);
  }

  /// 7. Recent Activity Timeline Section
  Widget _buildRecentActivitySection(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: const Center(
          child: Text(
            'No activities recorded yet. Complete a workout or log a meal!',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final act = entry.value;
        final isLast = index == activities.length - 1;

        final iconType = act['icon'] as String? ?? 'fitness';
        IconData iconData;
        Color iconColor;

        if (iconType == 'workout' || iconType == 'fitness') {
          iconData = Icons.fitness_center_rounded;
          iconColor = AppColors.primary;
        } else if (iconType == 'nutrition') {
          iconData = Icons.restaurant_rounded;
          iconColor = AppColors.primary;
        } else if (iconType == 'challenge') {
          iconData = Icons.emoji_events_rounded;
          iconColor = AppColors.accentYellow;
        } else {
          iconData = Icons.explore_rounded;
          iconColor = AppColors.accentOrange;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline vertical indicator
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(iconData, color: iconColor, size: 16),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.dividerDark,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Activity content card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            Text(
                              act['subtitle'] as String,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${act['xp']} XP',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
