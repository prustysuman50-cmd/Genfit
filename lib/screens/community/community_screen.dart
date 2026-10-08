import 'package:flutter/material.dart';

import '../../core/services/community_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'widgets/activity_card.dart';
import 'widgets/community_user_summary_card.dart';
import 'widgets/student_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedTabIndex =
      1; // Default to Campus tab (0: Friends, 1: Campus, 2: Activity)

  @override
  void initState() {
    super.initState();
    if (!CommunityService.instance.isInitialized) {
      CommunityService.instance.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CommunityService.instance;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Campus Leaderboard',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'GCEK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Subtitle
                const Text(
                  'Train together. Stay accountable.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 14),

                // 2. Current User's Community Summary
                const CommunityUserSummaryCard(),
                const SizedBox(height: 18),

                // 3. Three Filters/Tabs: Friends, Campus, Activity
                _buildSegmentedFilter(service),
                const SizedBox(height: 16),

                // 4. Tab Content
                if (_selectedTabIndex == 0)
                  _buildFriendsTab(service)
                else if (_selectedTabIndex == 1)
                  _buildCampusTab(service)
                else
                  _buildActivityTab(service),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSegmentedFilter(CommunityService service) {
    final tabs = [
      {'label': 'Friends', 'count': '${service.friendsCount}'},
      {'label': 'Campus', 'count': '${service.campusCount}'},
      {'label': 'Activity', 'count': ''},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final tab = tabs[index];

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.black
                            : AppColors.textSecondaryDark,
                      ),
                    ),
                    if (tab['count']!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black.withValues(alpha: 0.2)
                              : AppColors.surfaceElevatedDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tab['count']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.black
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFriendsTab(CommunityService service) {
    final friends = service.friends;

    if (friends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: AppColors.textMutedDark,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Connected Friends Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect with peers in the Campus tab to track and motivate each other.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 1; // Switch to Campus
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Explore GCEK Campus'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Fitness Circle',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${friends.length} active',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final student = friends[index];
            return StudentCard(
              student: student,
              onToggleConnect: () => service.toggleConnection(student.id),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCampusTab(CommunityService service) {
    final students = service.campusStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campus Section Heading
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_city_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GCEK Fitness Community',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    'Government College of Engineering, Kalahandi',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Students list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return StudentCard(
              student: student,
              onToggleConnect: () => service.toggleConnection(student.id),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityTab(CommunityService service) {
    final activities = service.activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Campus Activity',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 12, color: AppColors.primary),
                  SizedBox(width: 2),
                  Text(
                    'Real-time',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ActivityCard(activity: activity);
          },
        ),
      ],
    );
  }
}
