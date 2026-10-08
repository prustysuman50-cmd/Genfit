import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/community/student_profile.dart';

class StudentCard extends StatelessWidget {
  final StudentProfile student;
  final VoidCallback onToggleConnect;

  const StudentCard({
    super.key,
    required this.student,
    required this.onToggleConnect,
  });

  Color _getAvatarColor(int level) {
    switch (level % 4) {
      case 0:
        return const Color(0xFF06B6D4); // Cyan
      case 1:
        return const Color(0xFF22C55E); // Green
      case 2:
        return const Color(0xFFF97316); // Orange
      case 3:
      default:
        return const Color(0xFFA855F7); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(student.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: student.isConnected
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.dividerDark,
          width: student.isConnected ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Name, Level, and Connect Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    student.avatarInitials,
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & XP/Level
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevatedDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Lvl ${student.level}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${student.xp} XP',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 13,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${student.streakDays}d streak',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Connect / Added Button
              FilledButton.tonal(
                onPressed: onToggleConnect,
                style: FilledButton.styleFrom(
                  backgroundColor: student.isConnected
                      ? AppColors.surfaceElevatedDark
                      : AppColors.primary.withValues(alpha: 0.15),
                  foregroundColor: student.isConnected
                      ? AppColors.primary
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: student.isConnected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      student.isConnected
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      student.isConnected ? 'Connected' : 'Connect',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status & Current Activity Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${student.fitnessStatus} • ${student.currentActivity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
