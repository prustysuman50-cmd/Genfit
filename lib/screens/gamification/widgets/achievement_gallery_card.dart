import 'package:flutter/material.dart';

import '../../../core/services/gamification_service.dart';
import '../../../core/services/heritage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/gamification/achievement_progress.dart';
import '../../../models/gamification/badge_item.dart';
import 'achievement_detail_sheet.dart';

/// Filter mode for the achievement gallery status.
enum AchievementStatusFilter { all, unlocked, locked }

/// Collectible Achievement Gallery card with reactive filters and verified progress.
///
/// Features:
/// - Summary counter and visual progress bar (Unlocked vs Total).
/// - Status filters: All, Unlocked, Locked.
/// - Category filters: All, Workouts, Nutrition, Consistency, Challenges, Odisha Heritage.
/// - Distinct visual cards for unlocked (glowing gold/purple) vs locked (muted dark with lock).
/// - Honest, verified progress indicators derived from [GamificationService] and [HeritageService].
/// - Interactive modal bottom sheet on tapping any badge for detailed views.
/// - Fully responsive layout adapting to narrow and standard screens.
class AchievementGalleryCard extends StatefulWidget {
  final GamificationService gamification;
  final HeritageService? heritageService;

  const AchievementGalleryCard({
    super.key,
    required this.gamification,
    this.heritageService,
  });

  @override
  State<AchievementGalleryCard> createState() => _AchievementGalleryCardState();
}

class _AchievementGalleryCardState extends State<AchievementGalleryCard> {
  AchievementStatusFilter _statusFilter = AchievementStatusFilter.all;
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Workouts',
    'Nutrition',
    'Consistency',
    'Challenges',
    'Odisha Heritage',
  ];

  @override
  Widget build(BuildContext context) {
    final allBadges = widget.gamification.badges;
    final totalCount = allBadges.length;
    final unlockedCount = allBadges.where((b) => b.isUnlocked).length;
    final lockedCount = totalCount - unlockedCount;
    final overallProgress = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    // Filter badges based on status and category selections
    final filteredBadges = allBadges.where((badge) {
      if (_statusFilter == AchievementStatusFilter.unlocked &&
          !badge.isUnlocked) {
        return false;
      }
      if (_statusFilter == AchievementStatusFilter.locked && badge.isUnlocked) {
        return false;
      }
      if (_selectedCategory != 'All' && badge.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

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
          // 1. Header Summary Card (Unlocked vs Total with progress bar)
          _buildSummaryHeader(unlockedCount, totalCount, overallProgress),
          const SizedBox(height: 16),

          // 2. Status Filter Chips (All, Unlocked, Locked)
          _buildStatusFilterRow(totalCount, unlockedCount, lockedCount),
          const SizedBox(height: 12),

          // 3. Category Filter Chips
          _buildCategoryFilterRow(),
          const SizedBox(height: 16),

          // 4. Badges List / Grid
          if (filteredBadges.isEmpty)
            _buildEmptyState()
          else
            _buildResponsiveBadgesList(filteredBadges),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(
    int unlockedCount,
    int totalCount,
    double progress,
  ) {
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF261A45), Color(0xFF181528)],
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.accentYellow,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievement Collection',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      '$unlockedCount of $totalCount Badges Unlocked',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.softPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent% Collected',
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
              value: progress,
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

  Widget _buildStatusFilterRow(
    int totalCount,
    int unlockedCount,
    int lockedCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusChip(
            label: 'All ($totalCount)',
            filter: AchievementStatusFilter.all,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusChip(
            label: 'Unlocked ($unlockedCount)',
            filter: AchievementStatusFilter.unlocked,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusChip(
            label: 'Locked ($lockedCount)',
            filter: AchievementStatusFilter.locked,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required AchievementStatusFilter filter,
  }) {
    final isSelected = _statusFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _statusFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.brightPurple
                  : AppColors.cardBorderDark,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? AppColors.textPrimaryDark
                  : AppColors.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brightPurple.withValues(alpha: 0.6)
                          : AppColors.cardBorderDark,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.softPurple
                          : AppColors.textMutedDark,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.military_tech_outlined,
            size: 40,
            color: AppColors.textMutedDark.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          const Text(
            'No achievements in this filter',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try selecting "All" or a different category',
            style: TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveBadgesList(List<BadgeItem> badges) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        if (isNarrow) {
          return Column(
            children: badges
                .map(
                  (badge) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildBadgeCard(badge, isFullWidth: true),
                  ),
                )
                .toList(),
          );
        }

        // Two-column layout
        final rows = <Widget>[];
        for (int i = 0; i < badges.length; i += 2) {
          final b1 = badges[i];
          final b2 = i + 1 < badges.length ? badges[i + 1] : null;

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBadgeCard(b1)),
                  const SizedBox(width: 10),
                  if (b2 != null)
                    Expanded(child: _buildBadgeCard(b2))
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

  Widget _buildBadgeCard(BadgeItem badge, {bool isFullWidth = false}) {
    final isUnlocked = badge.isUnlocked;
    final progress = AchievementProgress.compute(
      badge,
      widget.gamification,
      heritageService: widget.heritageService,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AchievementDetailSheet.show(
            context,
            badge: badge,
            gamification: widget.gamification,
            heritageService: widget.heritageService,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? const LinearGradient(
                    colors: [Color(0xFF26194A), Color(0xFF161426)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUnlocked
                ? null
                : AppColors.surfaceElevatedDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked
                  ? AppColors.brightPurple.withValues(alpha: 0.5)
                  : AppColors.cardBorderDark,
              width: isUnlocked ? 1.2 : 0.8,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: AppColors.purpleGlow.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category tag and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.softPurple,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Icon(
                    isUnlocked
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 13,
                    color: isUnlocked
                        ? AppColors.success
                        : AppColors.textMutedDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Emblem Icon & Title
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? AppColors.accentYellow.withValues(alpha: 0.15)
                          : AppColors.surfaceDark,
                      border: Border.all(
                        color: isUnlocked
                            ? AppColors.accentYellow.withValues(alpha: 0.6)
                            : AppColors.cardBorderDark,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        badge.icon,
                        size: 20,
                        color: isUnlocked
                            ? AppColors.accentYellow
                            : AppColors.textMutedDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isUnlocked
                                ? AppColors.textPrimaryDark
                                : AppColors.textSecondaryDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUnlocked ? 'Completed' : 'In Progress',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? AppColors.success
                                : AppColors.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar & Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progress.displayText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked
                          ? AppColors.accentYellow
                          : AppColors.textMutedDark,
                    ),
                  ),
                  Text(
                    '(${progress.percent}%)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked
                          ? AppColors.accentYellow
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceElevatedDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked
                        ? AppColors.accentYellow
                        : AppColors.brightPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
