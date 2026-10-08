import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/challenge.dart';

class DailyChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onComplete;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: challenge.isCompleted
              ? AppColors.brightPurple.withValues(alpha: 0.4)
              : AppColors.cardBorderDark,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brightPurple.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: AppColors.brightPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Today's Challenge",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentYellow.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '+${challenge.rewardXp} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Progress Row & Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${challenge.progress} / ${challenge.target} ${challenge.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(challenge.progressRatio * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brightPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: challenge.progressRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevatedDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brightPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          GestureDetector(
            onTap: challenge.isCompleted ? null : onComplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: challenge.isCompleted
                    ? AppColors.surfaceElevatedDark
                    : AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: challenge.isCompleted
                      ? AppColors.cardBorderDark
                      : AppColors.primary,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    challenge.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.bolt_rounded,
                    size: 16,
                    color: challenge.isCompleted
                        ? AppColors.brightPurple
                        : AppColors.brightPurple,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      challenge.isCompleted
                          ? 'Challenge Completed'
                          : 'Check In (+50 Steps)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: challenge.isCompleted
                            ? AppColors.textMutedDark
                            : AppColors.brightPurple,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
