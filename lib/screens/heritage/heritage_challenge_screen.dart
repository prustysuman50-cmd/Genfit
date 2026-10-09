import 'package:flutter/material.dart';

import '../../core/services/heritage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/heritage/heritage_journey.dart';
import '../../models/heritage/heritage_milestone.dart';

class HeritageChallengeScreen extends StatefulWidget {
  const HeritageChallengeScreen({super.key});

  @override
  State<HeritageChallengeScreen> createState() =>
      _HeritageChallengeScreenState();
}

class _HeritageChallengeScreenState extends State<HeritageChallengeScreen> {
  final HeritageService _service = HeritageService.instance;

  @override
  void initState() {
    super.initState();
    if (!_service.isInitialized) {
      _service.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Odisha Heritage Challenges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Virtual Trail Mechanics',
            onPressed: () => _showMechanicsDialog(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final journey = _service.activeJourney;
          final currentDist = _service.currentDistanceKm;
          final totalDist = _service.totalRouteDistanceKm;
          final percent = _service.progressPercent;
          final isDone = _service.isCompleted;
          final targetMilestone = _service.currentTargetMilestone;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Journey Card
                _buildHeroJourneyCard(
                  journey: journey,
                  currentDist: currentDist,
                  totalDist: totalDist,
                  percent: percent,
                  isDone: isDone,
                ),
                const SizedBox(height: 16),

                // 2. Current Progress / Next Landmark Banner
                _buildCurrentProgressBanner(
                  journey: journey,
                  targetMilestone: targetMilestone,
                  isDone: isDone,
                ),
                const SizedBox(height: 20),

                // 3. Section Header for Timeline
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Trail Expedition Milestones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Stylized Vertical Journey Timeline
                _buildJourneyTimeline(journey, currentDist),
                const SizedBox(height: 24),

                // 5. Cultural Badges Showcase
                _buildBadgesShowcase(journey),
                const SizedBox(height: 24),

                // 6. Available Routes Switcher
                _buildRouteSwitcher(),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. Hero Journey Card with progress ring and stats
  Widget _buildHeroJourneyCard({
    required HeritageJourney journey,
    required double currentDist,
    required double totalDist,
    required double percent,
    required bool isDone,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone
              ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tag Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.temple_hindu_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ODISHA HERITAGE TRAIL',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                        : AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF4CAF50)
                          : AppColors.dividerDark,
                    ),
                  ),
                  child: Text(
                    isDone ? 'Completed 🏆' : 'Active Challenge',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? const Color(0xFF4CAF50)
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Route Title
            Text(
              journey.title,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              journey.region,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar and Percentage
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceElevatedDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? const Color(0xFF4CAF50) : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDone
                        ? const Color(0xFF4CAF50)
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Quick Stats Grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.dividerDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    label: 'Virtual Distance',
                    value: '$currentDist / ${totalDist.toInt()} km',
                    icon: Icons.route_rounded,
                    color: AppColors.primary,
                  ),
                  _buildStatDivider(),
                  _buildStatColumn(
                    label: 'Campus Steps',
                    value: '${_service.totalSteps}',
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.brightPurple,
                  ),
                  _buildStatDivider(),
                  _buildStatColumn(
                    label: "Today's Boost",
                    value: '+${_service.todayContributionKm} km',
                    icon: Icons.bolt_rounded,
                    color: AppColors.accentOrange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.dividerDark,
    );
  }

  /// 2. Current Status / Next Milestone Banner
  Widget _buildCurrentProgressBanner({
    required HeritageJourney journey,
    required HeritageMilestone? targetMilestone,
    required bool isDone,
  }) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heritage Trail Conquered!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You reached ${journey.destinationLandmark} and unlocked ${journey.completionBadgeName ?? "Odisha Champion"} (+${journey.completionRewardXp} XP)!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final target = targetMilestone;
    final remainingKm = target != null ? _service.remainingDistanceTo(target) : 0.0;
    final remainingSteps = target != null ? _service.remainingStepsTo(target) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppColors.accentOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Landmark: ${target?.name ?? "Destination"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${remainingKm.toStringAsFixed(1)} km ($remainingSteps steps) remaining to unlock milestone',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Stylized Vertical Journey Timeline
  Widget _buildJourneyTimeline(HeritageJourney journey, double currentDist) {
    final milestones = journey.milestones;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: milestones.length,
      separatorBuilder: (context, index) {
        final isCompleted = milestones[index].isCompleted;
        return Padding(
          padding: const EdgeInsets.only(left: 23),
          child: Container(
            width: 2,
            height: 24,
            color: isCompleted
                ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
                : AppColors.dividerDark,
          ),
        );
      },
      itemBuilder: (context, index) {
        final m = milestones[index];
        return _buildMilestoneNode(m, index == 0, index == milestones.length - 1);
      },
    );
  }

  Widget _buildMilestoneNode(
    HeritageMilestone milestone,
    bool isFirst,
    bool isLast,
  ) {
    final isDone = milestone.isCompleted;
    final isUnlocked = milestone.isUnlocked;

    Color nodeColor = AppColors.surfaceElevatedDark;
    IconData nodeIcon = Icons.lock_outline_rounded;
    Color iconColor = AppColors.textSecondaryDark;

    if (isDone) {
      nodeColor = const Color(0xFF4CAF50);
      nodeIcon = Icons.check_rounded;
      iconColor = Colors.black;
    } else if (isUnlocked) {
      nodeColor = AppColors.accentOrange;
      nodeIcon = Icons.navigation_rounded;
      iconColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.surfaceDark : AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : (isUnlocked
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.dividerDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Node Indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(nodeIcon, size: 18, color: iconColor),
            ),
          ),
          const SizedBox(width: 14),

          // Milestone Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isUnlocked
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            milestone.landmark,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDone
                                  ? const Color(0xFF4CAF50)
                                  : (isUnlocked
                                      ? AppColors.primary
                                      : AppColors.textSecondaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Distance Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Text(
                        '${milestone.requiredDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  milestone.shortDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                // Reward & Status Chips
                Row(
                  children: [
                    if (milestone.rewardXp > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${milestone.rewardXp} XP',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (milestone.badgeName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brightPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              size: 11,
                              color: AppColors.brightPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              milestone.badgeName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brightPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      isDone
                          ? 'Unlocked ✅'
                          : (isUnlocked ? 'Current Target 🎯' : 'Locked 🔒'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? const Color(0xFF4CAF50)
                            : (isUnlocked
                                ? AppColors.accentOrange
                                : AppColors.textSecondaryDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Cultural Badges Showcase Card
  Widget _buildBadgesShowcase(HeritageJourney journey) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.brightPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Cultural Heritage Badges',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: journey.milestones
                .where((m) => m.badgeName != null)
                .map((m) {
                  final isUnlocked = m.isCompleted;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.brightPurple.withValues(alpha: 0.15)
                          : AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUnlocked
                            ? AppColors.brightPurple
                            : AppColors.dividerDark,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked
                              ? Icons.stars_rounded
                              : Icons.lock_outline_rounded,
                          size: 14,
                          color: isUnlocked
                              ? AppColors.brightPurple
                              : AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          m.badgeName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isUnlocked
                                ? AppColors.textPrimaryDark
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  /// 6. Available Routes Switcher
  Widget _buildRouteSwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Heritage Route',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: _service.journeys.map((j) {
            final isSelected = j.id == _service.activeJourneyId;
            return GestureDetector(
              onTap: () => _service.setActiveJourney(j.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.dividerDark,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            j.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${j.totalDistanceKm.toInt()} km • ${j.milestones.length} milestones • +${j.completionRewardXp} XP bonus',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showMechanicsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.directions_walk_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'How It Works',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• 1,000 campus steps = 1.0 virtual km.\n'
              '• Steps automatically sync from your daily activity telemetry.\n'
              '• Reach historic Odisha landmarks to unlock XP and cultural badges.\n'
              '• Completely offline and battery-friendly—no GPS tracking required.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
