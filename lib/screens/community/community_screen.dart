import 'package:flutter/material.dart';

import '../../core/services/community_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'accountability_partner_screen.dart';
import 'widgets/activity_card.dart';
import 'widgets/community_user_summary_card.dart';
import 'widgets/student_card.dart';
import '../../core/services/accountability_service.dart';
import '../../core/services/heritage_service.dart';
import '../../core/services/local_activity_service.dart';
import '../heritage/heritage_challenge_screen.dart';
import 'local_activity_spots_screen.dart';

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
    if (!AccountabilityService.instance.isInitialized) {
      AccountabilityService.instance.init();
    }
    if (!HeritageService.instance.isInitialized) {
      HeritageService.instance.init();
    }
    if (!LocalActivityService.instance.isInitialized) {
      LocalActivityService.instance.init();
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
            icon: const Icon(Icons.handshake_rounded),
            tooltip: 'Accountability Partner',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountabilityPartnerScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.explore_rounded),
            tooltip: 'Heritage Challenges',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HeritageChallengeScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.place_rounded),
            tooltip: 'Local Activity Spots',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LocalActivitySpotsScreen(),
                ),
              );
            },
          ),
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
                const SizedBox(height: 14),

                // 3. Accountability Partner Feature Banner
                _buildAccountabilityPartnerCard(context),
                const SizedBox(height: 12),

                // 4. Odisha Heritage Challenge Feature Banner
                _buildHeritageChallengeCard(context),
                const SizedBox(height: 12),

                // 5. Local Activity Spots Feature Banner
                _buildLocalSpotsCard(context),
                const SizedBox(height: 16),

                // 6. Three Filters/Tabs: Friends, Campus, Activity
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

  Widget _buildAccountabilityPartnerCard(BuildContext context) {
    final accountability = AccountabilityService.instance;
    return ListenableBuilder(
      listenable: accountability,
      builder: (context, _) {
        final partner = accountability.partner;
        final isUserDone = accountability.isUserCheckedInToday();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountabilityPartnerScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.handshake_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Accountability Partner',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isUserDone
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                                  : AppColors.accentOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUserDone ? 'Checked in ✅' : 'Check-in pending',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isUserDone
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.accentOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Paired with ${partner.name.split(' ').first} • ${partner.streakDays}d streak',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryDark,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeritageChallengeCard(BuildContext context) {
    final heritage = HeritageService.instance;
    return ListenableBuilder(
      listenable: heritage,
      builder: (context, _) {
        final journey = heritage.activeJourney;
        final currentDist = heritage.currentDistanceKm;
        final totalDist = heritage.totalRouteDistanceKm;
        final percent = heritage.progressPercent;
        final isDone = heritage.isCompleted;
        final target = heritage.currentTargetMilestone;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HeritageChallengeScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: isDone ? const Color(0xFF4CAF50) : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.temple_hindu_rounded,
                          color: isDone ? const Color(0xFF4CAF50) : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Odisha Heritage Challenge',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                                      : AppColors.brightPurple.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDone ? 'Completed 🏆' : '${(percent * 100).toInt()}% done',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isDone
                                        ? const Color(0xFF4CAF50)
                                        : AppColors.brightPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            journey.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryDark,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceElevatedDark,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? const Color(0xFF4CAF50) : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentDist / ${totalDist.toInt()} km virtual trail',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    Text(
                      isDone
                          ? 'Finisher Badge Unlocked!'
                          : 'Next: ${target?.name ?? "Finish"}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDone ? const Color(0xFF4CAF50) : AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalSpotsCard(BuildContext context) {
    final spotsService = LocalActivityService.instance;
    return ListenableBuilder(
      listenable: spotsService,
      builder: (context, _) {
        final totalCount = spotsService.allSpots.length;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LocalActivitySpotsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.place_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Local Activity Spots',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$totalCount spots',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nearby open gyms, tracks & campus fitness spots',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryDark,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryDark,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
