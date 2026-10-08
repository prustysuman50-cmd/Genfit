import 'package:flutter/material.dart';

import '../../../core/services/community_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/community/community_activity.dart';

class RecentActivitySection extends StatelessWidget {
  final VoidCallback? onOpenCommunity;

  const RecentActivitySection({super.key, this.onOpenCommunity});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CommunityService.instance,
      builder: (context, _) {
        final activities = CommunityService.instance.activities
            .take(3)
            .toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorderDark, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Campus Activity',
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onOpenCommunity,
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'Community →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brightPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Recent fitness updates from campus peers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 14),

              // Activity Feed Items
              for (int i = 0; i < activities.length; i++) ...[
                _buildActivityItem(activities[i]),
                if (i < activities.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(CommunityActivity activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.brightPurple.withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              activity.studentInitials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.brightPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondaryDark,
                    ),
                    children: [
                      TextSpan(
                        text: activity.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      TextSpan(text: ' ${activity.actionText} '),
                      TextSpan(
                        text: activity.activityDetail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brightPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.timeAgo,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
