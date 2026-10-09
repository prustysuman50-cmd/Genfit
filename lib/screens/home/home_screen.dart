import 'package:flutter/material.dart';

import '../../core/services/community_service.dart';
import '../../core/services/daily_stats_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/nutrition_service.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/step_tracking_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../models/challenge.dart';
import '../../models/daily_metric.dart';
import '../../models/progress/recommendation_item.dart';
import '../../models/user_profile.dart';
import '../../models/workout.dart';
import 'widgets/coach_recommendation_card.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/daily_progress_card.dart';
import 'widgets/greeting_header.dart';
import 'widgets/hostel_fuel_preview.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/streak_xp_banner.dart';
import 'widgets/todays_workout_card.dart';
import '../gamification/widgets/weekly_quest_board_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Workout _workout;

  @override
  void initState() {
    super.initState();
    _workout = MockData.todaysWorkout;
    DailyStatsService.instance.addListener(_onDailyStatsChanged);
    StepTrackingService.instance.addListener(_onDailyStatsChanged);
    if (!StepTrackingService.instance.isInitialized) {
      StepTrackingService.instance.init();
    }
  }

  @override
  void dispose() {
    DailyStatsService.instance.removeListener(_onDailyStatsChanged);
    StepTrackingService.instance.removeListener(_onDailyStatsChanged);
    super.dispose();
  }

  void _onDailyStatsChanged() {
    if (mounted) setState(() {});
  }

  UserProfile get _user {
    final g = GamificationService.instance;
    final u = UserService.instance.currentUser;
    return u.copyWith(
      xp: g.xp,
      level: g.currentLevel,
      levelTitle: g.levelTitle,
      streakDays: g.streakDays,
      nextLevelXp: g.nextLevelXp,
      customLevelProgress: g.levelProgress,
    );
  }

  Challenge get _challenge => GamificationService.instance.activeChallenge;

  DailyMetrics get _effectiveMetrics =>
      DailyMetrics.fromDailyStats(DailyStatsService.instance.todayStats);

  void _handleAddWater() {
    DailyStatsService.instance.addWater(250);
    setState(() {});
    _showSnackBar('💧 Logged +250ml water! Stay hydrated for your workouts.');
  }

  void _handleLogSteps() {
    final tracker = StepTrackingService.instance;
    if (tracker.currentMode == StepTrackingMode.demoSimulation) {
      tracker.injectDemoSteps(250);
      setState(() {});
      _showSnackBar('⚡ [DEMO] Logged +250 simulated campus steps!');
    } else {
      _showStepTrackingDialog();
    }
  }

  void _showStepTrackingDialog() {
    final tracker = StepTrackingService.instance;
    final stats = DailyStatsService.instance.todayStats;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDemo =
                tracker.currentMode == StepTrackingMode.demoSimulation;

            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    isDemo ? Icons.bolt_rounded : Icons.sensors_rounded,
                    color: isDemo
                        ? const Color(0xFFFFB74D)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDemo ? 'Step Demo Mode' : 'Hardware Step Tracking',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDemo
                        ? 'Demo simulation mode is active. You can inject simulated steps for hackathon demonstrations without physically walking.'
                        : 'Steps are automatically counted by your device hardware sensor (TYPE_STEP_COUNTER). Arbitrary manual step entry is disabled in Live Sensor Mode.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dividerDark),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Today\'s Steps:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                            Text(
                              '${stats.steps} / ${stats.stepsGoal}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tracking Mode:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                            Text(
                              tracker.currentMode.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDemo
                                    ? const Color(0xFFFFB74D)
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isDemo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await tracker.injectDemoSteps(250);
                              setDialogState(() {});
                            },
                            child: const Text('+250 Steps'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await tracker.injectDemoSteps(1000);
                              setDialogState(() {});
                            },
                            child: const Text('+1,000 Steps'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final nextMode = isDemo
                        ? StepTrackingMode.liveSensor
                        : StepTrackingMode.demoSimulation;
                    await tracker.setMode(nextMode);
                    setDialogState(() {});
                  },
                  child: Text(
                    isDemo ? 'Switch to Live Sensor' : 'Switch to Demo Mode',
                    style: TextStyle(
                      color: isDemo
                          ? AppColors.primary
                          : const Color(0xFFFFB74D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleChallengeCheckIn() async {
    final gamification = GamificationService.instance;
    final challenge = gamification.activeChallenge;
    if (challenge.isCompleted) return;

    final wasDone = challenge.isCompleted;
    await gamification.syncChallengesFromDailyStats(
      DailyStatsService.instance.todayStats,
    );
    final updated = gamification.getChallengeById(challenge.id);

    if (updated != null && updated.isCompleted && !wasDone) {
      _showSnackBar(
        '🎉 Quest Completed! +${updated.rewardXp} XP added to your profile!',
      );
    } else {
      _showSnackBar('⚡ Progress synced for ${challenge.title}!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
        backgroundColor: AppColors.surfaceElevatedDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorderDark),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            GamificationService.instance,
            UserService.instance,
            NutritionService.instance,
            RecommendationService.instance,
            CommunityService.instance,
            DailyStatsService.instance,
          ]),
          builder: (context, _) {
            final user = _user;
            final challenge = _challenge;
            final recs = RecommendationService.instance.getRecommendations();
            final topRecommendation = recs.isNotEmpty
                ? recs.first
                : const RecommendationItem(
                    id: 'rec_default',
                    title: 'Keep Up The Momentum',
                    message: 'Consistency in your campus workouts builds lasting fitness habit.',
                    category: 'Consistency',
                    actionLabel: 'Explore Workouts',
                    iconIdentifier: 'fitness',
                    priority: 1,
                  );

            return RefreshIndicator(
              color: AppColors.brightPurple,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 300));
                await DailyStatsService.instance.syncNutritionFromService();
                if (mounted) setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Header (Greeting, Avatar, Notification Bell)
                    GreetingHeader(
                      user: user,
                      onProfileTap: () => widget.onNavigateToTab?.call(4),
                    ),
                    const SizedBox(height: 20),

                    // 2. Large Visual Hero Training Card (Photo + Radial Progress + CTA)
                    TodaysWorkoutCard(
                      workout: _workout,
                      onStart: () => widget.onNavigateToTab?.call(1),
                    ),
                    const SizedBox(height: 20),

                    // 3. Quick Action Feature Tiles (AI Workout, Log Meal, Water, Progress)
                    QuickActionsRow(
                      onAiWorkoutTap: () => widget.onNavigateToTab?.call(1),
                      onLogMealTap: () => widget.onNavigateToTab?.call(2),
                      onAddWaterTap: _handleAddWater,
                      onProgressTap: () => widget.onNavigateToTab?.call(4),
                    ),
                    const SizedBox(height: 22),

                    // 4. Daily Activity Dashboard Section (Asymmetric + Radial Gauge)
                    DailyProgressCard(
                      stats: DailyStatsService.instance.todayStats,
                      metrics: _effectiveMetrics,
                      onAddWater: _handleAddWater,
                      onLogSteps: _handleLogSteps,
                    ),
                    const SizedBox(height: 20),

                    // 5. Streak & XP Progression Hero Banner
                    StreakXpBanner(
                      user: user,
                      onTap: () => widget.onNavigateToTab?.call(3),
                    ),
                    const SizedBox(height: 20),

                    // 6. Today's Challenge Card
                    DailyChallengeCard(
                      challenge: challenge,
                      onComplete: _handleChallengeCheckIn,
                      onWeeklyQuestsTap: () =>
                          WeeklyQuestBoardSheet.show(context),
                    ),
                    const SizedBox(height: 20),

                    // 7. Coach Recommendation Card
                    CoachRecommendationCard(
                      recommendation: topRecommendation,
                      onAction: () {
                        final cat = topRecommendation.category.toLowerCase();
                        if (cat.contains('nutrition') ||
                            cat.contains('protein')) {
                          widget.onNavigateToTab?.call(2);
                        } else if (cat.contains('journey') ||
                            cat.contains('odisha')) {
                          widget.onNavigateToTab?.call(3);
                        } else {
                          widget.onNavigateToTab?.call(1);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 8. Hostel Fuel Preview
                    HostelFuelPreview(
                      onOpenMenu: () => widget.onNavigateToTab?.call(2),
                    ),
                    const SizedBox(height: 20),

                    // 9. Recent Campus Activity
                    RecentActivitySection(
                      onOpenCommunity: () => widget.onNavigateToTab?.call(5),
                    ),
                    const SizedBox(height: 80), // Padding for floating nav bar
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
