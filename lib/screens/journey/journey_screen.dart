import 'package:flutter/material.dart';

import '../../core/services/journey_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../leaderboard/leaderboard_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final JourneyService _journeyService = JourneyService.instance;

  @override
  void initState() {
    super.initState();
    if (!_journeyService.isInitialized) {
      _journeyService.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Odisha Fitness Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
            tooltip: 'Campus Leaderboard',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _journeyService,
        builder: (context, _) {
          final destinations = _journeyService.destinations;
          final completedCount = _journeyService.completedDestinations.length;
          final totalCount = destinations.length;
          final progressPercent = _journeyService.progressPercent;
          final currentProgress = _journeyService.currentProgressKm;
          final totalDistance = _journeyService.totalRouteDistanceKm;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. JOURNEY HERO BANNER WITH PHOTOGRAPHY
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.purpleGlow.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background photography
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/journey/odisha_trail.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: AppColors.surfaceDark);
                            },
                          ),
                        ),

                        // Deep gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF09090D)
                                      .withValues(alpha: 0.92),
                                  const Color(0xFF14141D)
                                      .withValues(alpha: 0.88),
                                  const Color(0xFF211D2C)
                                      .withValues(alpha: 0.85),
                                  const Color(0xFF09090D)
                                      .withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.brightPurple
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.explore_rounded,
                                          size: 13,
                                          color: AppColors.brightPurple,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'ODISHA CULTURAL TRAIL',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.brightPurple,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevatedDark,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.dividerDark,
                                      ),
                                    ),
                                    child: Text(
                                      'Stage $completedCount of $totalCount',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Step Your Way Across Odisha',
                                          style: TextStyle(
                                            color: AppColors.textPrimaryDark,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Every step on campus converts into distance across legendary Odisha trails. Unlock historical monuments, earn cultural fitness badges, and dominate your college leaderboard.',
                                          style: TextStyle(
                                            color: AppColors.textSecondaryDark,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Circular percentage ring
                                  SizedBox(
                                    width: 76,
                                    height: 76,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: CircularProgressIndicator(
                                            value: progressPercent.clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            strokeWidth: 7,
                                            strokeCap: StrokeCap.round,
                                            backgroundColor:
                                                AppColors.surfaceElevatedDark,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(AppColors.brightPurple),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${(progressPercent * 100).toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    AppColors.textPrimaryDark,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const Text(
                                              'TRAIL',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.softPurple,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Metric Bar
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevatedDark
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.dividerDark,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.directions_walk_rounded,
                                          size: 16,
                                          color: AppColors.brightPurple,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${currentProgress.toStringAsFixed(1)} km completed',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.brightPurple,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${totalDistance.toStringAsFixed(1)} km total',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // 2. ROUTE PROGRESSION & DESTINATIONS
                Text(
                  'Route Progression & Milestones',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bhubaneswar → Cuttack → Konark → Puri route milestones.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 18),

                // Stylized Route Timeline Visualization
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final dest = destinations[index];
                    final isCompleted = dest.isCompleted;
                    final isUnlocked = dest.isUnlocked;
                    final isCurrentActive = isUnlocked && !isCompleted;
                    final isLast = index == destinations.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vertical timeline path column with glowing line
                          SizedBox(
                            width: 36,
                            child: Column(
                              children: [
                                // Node icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? AppColors.primary
                                        : (isCurrentActive
                                              ? AppColors.surfaceElevatedDark
                                              : AppColors.surfaceDark),
                                    border: Border.all(
                                      color: isCompleted
                                          ? AppColors.brightPurple
                                          : (isCurrentActive
                                                ? AppColors.brightPurple
                                                : AppColors.dividerDark),
                                      width: isCurrentActive ? 2.5 : 1.5,
                                    ),
                                    boxShadow: isCurrentActive
                                        ? [
                                            BoxShadow(
                                              color: AppColors.purpleGlow
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 12,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isCompleted
                                          ? Icons.check_rounded
                                          : (isCurrentActive
                                                ? Icons.near_me_rounded
                                                : Icons.lock_outline_rounded),
                                      size: 15,
                                      color: isCompleted
                                          ? Colors.white
                                          : (isCurrentActive
                                                ? AppColors.brightPurple
                                                : AppColors.textSecondaryDark),
                                    ),
                                  ),
                                ),
                                // Connecting vertical line
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 3,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppColors.primary.withValues(
                                                alpha: 0.7,
                                              )
                                            : AppColors.dividerDark,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Milestone Card
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrentActive
                                    ? const Color(0xFF1B1728)
                                    : AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isCurrentActive
                                      ? AppColors.brightPurple.withValues(
                                          alpha: 0.6,
                                        )
                                      : (isCompleted
                                            ? AppColors.primary.withValues(
                                                alpha: 0.3,
                                              )
                                            : AppColors.dividerDark),
                                  width: isCurrentActive ? 1.5 : 1.0,
                                ),
                                boxShadow: isCurrentActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.purpleGlow
                                              .withValues(alpha: 0.15),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dest.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: isUnlocked
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textSecondaryDark,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppColors.primary.withValues(
                                                  alpha: 0.15,
                                                )
                                              : (isCurrentActive
                                                    ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.25,
                                                          )
                                                    : AppColors.surfaceDark),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          isCompleted
                                              ? 'Completed'
                                              : (isCurrentActive
                                                    ? 'Active Milestone'
                                                    : 'Locked'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                isCompleted || isCurrentActive
                                                ? AppColors.brightPurple
                                                : AppColors.textSecondaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dest.requiredProgress.toStringAsFixed(0)} km • ${dest.shortDescription}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUnlocked
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryDark
                                                .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isCurrentActive) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.directions_walk_rounded,
                                          size: 14,
                                          color: AppColors.brightPurple,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(dest.requiredProgress - currentProgress).clamp(0.0, 999.0).toStringAsFixed(1)} km remaining to unlock',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.brightPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
