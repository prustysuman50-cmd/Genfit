import 'package:flutter/material.dart';

import '../../core/services/gamification_service.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/leaderboard/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _leaderboardService,
          UserService.instance,
          GamificationService.instance,
        ]),
        builder: (context, _) {
          final filter = _leaderboardService.currentFilter;
          final allEntries = _leaderboardService.getEntries(filter: filter);
          final topThree = _leaderboardService.getTopThree(filter: filter);
          final remaining = _leaderboardService.getRemainingEntries(
            filter: filter,
          );
          final currentUserEntry = _leaderboardService.getCurrentUserEntry(
            filter: filter,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Subtitle
                const Text(
                  'Train together. Climb together.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 14),

                // 2. Filter Tabs (Campus / Friends / Weekly)
                _buildFilterTabs(filter),
                const SizedBox(height: 18),

                // 3. Current User's Featured Rank Card
                _buildCurrentUserCard(currentUserEntry, filter),
                const SizedBox(height: 22),

                // 4. Top 3 Podium Section
                if (topThree.isNotEmpty) ...[
                  Text(
                    'Campus Champions',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPodiumSection(topThree, filter),
                  const SizedBox(height: 24),
                ],

                // 5. Ranked Student List (Rank 4+)
                if (remaining.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student Rankings',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${allEntries.length} Students',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...remaining.map((entry) => _buildRankedRow(entry, filter)),
                ] else if (topThree.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No students found in this category.',
                        style: TextStyle(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Segmented Tab Switcher (Campus, Friends, Weekly)
  Widget _buildFilterTabs(LeaderboardFilter activeFilter) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          _buildFilterChip('Campus', LeaderboardFilter.campus, activeFilter),
          _buildFilterChip('Friends', LeaderboardFilter.friends, activeFilter),
          _buildFilterChip('Weekly', LeaderboardFilter.weekly, activeFilter),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    LeaderboardFilter filter,
    LeaderboardFilter activeFilter,
  ) {
    final isSelected = filter == activeFilter;
    return Expanded(
      child: GestureDetector(
        onTap: () => _leaderboardService.setFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : AppColors.textSecondaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Current User's Highlighted Rank Card
  Widget _buildCurrentUserCard(
    LeaderboardEntry userEntry,
    LeaderboardFilter filter,
  ) {
    final scoreText = filter == LeaderboardFilter.weekly
        ? '${userEntry.weeklyXp} Weekly XP'
        : '${userEntry.xp} XP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${userEntry.rank}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User Avatar & Info
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Center(
              child: Text(
                userEntry.avatarInitials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
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
                    Flexible(
                      child: Text(
                        userEntry.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${userEntry.levelTitle} • LVL ${userEntry.level}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Score & Streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentYellow,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.accentOrange,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${userEntry.streakDays}d streak',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Top 3 Podium Component (2nd on Left, 1st in Center, 3rd on Right)
  Widget _buildPodiumSection(
    List<LeaderboardEntry> topThree,
    LeaderboardFilter filter,
  ) {
    LeaderboardEntry? first;
    LeaderboardEntry? second;
    LeaderboardEntry? third;

    for (final e in topThree) {
      if (e.rank == 1) first = e;
      if (e.rank == 2) second = e;
      if (e.rank == 3) third = e;
    }

    // Fallbacks if list has fewer entries
    first ??= topThree.isNotEmpty ? topThree[0] : null;
    second ??= topThree.length > 1 ? topThree[1] : null;
    third ??= topThree.length > 2 ? topThree[2] : null;

    if (first == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          Expanded(
            child: second != null
                ? _buildPodiumPillar(
                    entry: second,
                    rank: 2,
                    pedestalHeight: 88,
                    color: const Color(0xFFC0C0C0), // Silver
                    filter: filter,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 1st Place (Gold - Tallest)
          Expanded(
            child: _buildPodiumPillar(
              entry: first,
              rank: 1,
              pedestalHeight: 118,
              color: const Color(0xFFFFD700), // Gold
              isFirst: true,
              filter: filter,
            ),
          ),
          const SizedBox(width: 8),

          // 3rd Place (Bronze)
          Expanded(
            child: third != null
                ? _buildPodiumPillar(
                    entry: third,
                    rank: 3,
                    pedestalHeight: 72,
                    color: const Color(0xFFCD7F32), // Bronze
                    filter: filter,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required LeaderboardEntry entry,
    required int rank,
    required double pedestalHeight,
    required Color color,
    bool isFirst = false,
    required LeaderboardFilter filter,
  }) {
    final avatarSize = isFirst ? 58.0 : 46.0;
    final score = filter == LeaderboardFilter.weekly
        ? '${entry.weeklyXp} XP'
        : '${entry.xp} XP';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (isFirst)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFFFD700),
              size: 26,
            ),
          )
        else
          const SizedBox(height: 12),

        // Avatar with colored ring
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: isFirst ? 2.5 : 1.8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  entry.avatarInitials,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: isFirst ? 18 : 14,
                  ),
                ),
              ),
            ),
            // Rank circular pill
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name & You Tag
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                entry.name.split(' ').first,
                style: TextStyle(
                  fontSize: isFirst ? 13 : 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.isCurrentUser) ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),

        // Score
        Text(
          score,
          style: TextStyle(
            fontSize: isFirst ? 12 : 10,
            fontWeight: FontWeight.w700,
            color: isFirst
                ? AppColors.accentYellow
                : AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 8),

        // Pedestal Column
        Container(
          width: double.infinity,
          height: pedestalHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isFirst ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 11,
                    color: AppColors.accentOrange,
                  ),
                  Text(
                    '${entry.streakDays}d',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Individual Row for Students ranked 4+
  Widget _buildRankedRow(LeaderboardEntry entry, LeaderboardFilter filter) {
    final isUser = entry.isCurrentUser;
    final score = filter == LeaderboardFilter.weekly
        ? '${entry.weeklyXp} XP'
        : '${entry.xp} XP';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.dividerDark,
          width: isUser ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isUser ? AppColors.primary : AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Avatar Initials
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.surfaceElevatedDark,
              border: Border.all(
                color: isUser ? AppColors.primary : AppColors.cardBorderDark,
              ),
            ),
            child: Center(
              child: Text(
                entry.avatarInitials,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isUser ? AppColors.primary : AppColors.textPrimaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isUser
                              ? AppColors.primary
                              : AppColors.textPrimaryDark,
                          fontWeight: isUser
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LVL ${entry.level}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        entry.levelTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Streak and XP Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentYellow,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.accentOrange,
                    size: 13,
                  ),
                  Text(
                    '${entry.streakDays}d',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
