import 'package:flutter/material.dart';

import '../../../core/services/weekly_quest_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/gamification/weekly_quest.dart';

/// Polished Weekly Quest Board card presenting ISO-week challenges and factual progress.
///
/// Features:
/// - Displays current ISO week key, number, and full date range.
/// - Shows overall completion ratio and visual progress track.
/// - Shows individual objective cards with verified telemetry, target, and +XP badge.
/// - Clear visual distinction between Completed (green checkmark) and In-Progress quests.
/// - Completely read-only with respect to activity metrics; XP is awarded through verified triggers.
class WeeklyQuestBoardCard extends StatelessWidget {
  final WeeklyQuestService? questService;

  const WeeklyQuestBoardCard({super.key, this.questService});

  WeeklyQuestService get _service => questService ?? WeeklyQuestService.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final week = _service.currentWeek;
        final quests = _service.getQuestsForWeek();
        final totalCount = quests.length;
        final completedCount = quests.where((q) => q.isCompleted).length;
        final completionFraction =
            totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
        final completionPercent = (completionFraction * 100).toInt();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.dividerDark),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card: Week Info & Date Range
              _buildWeekHeader(week.label, week.dateRangeLabel),
              const SizedBox(height: 14),

              // 2. Weekly Completion Summary
              _buildCompletionSummary(
                completedCount,
                totalCount,
                completionFraction,
                completionPercent,
              ),
              const SizedBox(height: 16),

              // 3. Quests List
              Column(
                children: quests
                    .map((quest) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildQuestTile(quest),
                        ))
                    .toList(),
              ),

              // 4. Honest Reset Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.softPurple,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quests reset every Monday. XP rewards are granted once per week upon completion.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekHeader(String weekLabel, String dateRange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppColors.brightPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Quest Board',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brightPurple.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            weekLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.softPurple,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSummary(
    int completedCount,
    int totalCount,
    double fraction,
    int percent,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26194A), Color(0xFF161426)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brightPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalCount Quests Completed',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '$percent% Done',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevatedDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTile(WeeklyQuest quest) {
    final isDone = quest.isCompleted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.surfaceElevatedDark.withValues(alpha: 0.7)
            : AppColors.surfaceElevatedDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.cardBorderDark,
          width: isDone ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon, Title, and XP Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.primaryContainer,
                  border: Border.all(
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.cardBorderDark,
                  ),
                ),
                child: Center(
                  child: Icon(
                    quest.icon,
                    size: 18,
                    color: isDone
                        ? AppColors.success
                        : AppColors.softPurple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryDark,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // XP Reward Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentYellow.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 12,
                      color: AppColors.accentYellow,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${quest.rewardXp} XP',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Progress indicator & status label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quest.progressLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDone
                      ? AppColors.success
                      : AppColors.textSecondaryDark,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.timelapse_rounded,
                    size: 12,
                    color: isDone
                        ? AppColors.success
                        : AppColors.textMutedDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDone ? 'COMPLETED' : 'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDone
                          ? AppColors.success
                          : AppColors.textMutedDark,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: quest.fraction,
              minHeight: 5,
              backgroundColor: AppColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.success : AppColors.brightPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
