import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/community/community_activity.dart';

class ActivityCard extends StatelessWidget {
  final CommunityActivity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Icon container
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activity.iconColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: activity.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      TextSpan(
                        text: ' ${activity.actionText}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Detail Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.cardBorderDark.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    activity.activityDetail,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: activity.iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Time ago
          Text(activity.timeAgo, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
