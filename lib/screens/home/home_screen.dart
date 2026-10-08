import 'package:flutter/material.dart';

import '../../core/services/community_service.dart';
import '../../core/services/daily_stats_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/nutrition_service.dart';
import '../../core/services/recommendation_service.dart';
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
  }

  @override
  void dispose() {
    DailyStatsService.instance.removeListener(_onDailyStatsChanged);
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
    DailyStatsService.instance.addSteps(250, caloriesBurned: 12);
    setState(() {});
    _showSnackBar('👟 Logged +250 campus steps!');
  }

  void _handleChallengeCheckIn() async {
    final gamification = GamificationService.instance;
    final challenge = gamification.activeChallenge;
    if (challenge.isCompleted) return;

    final wasDone = challenge.isCompleted;
    await gamification.progressChallenge(challenge.id, delta: 300);
    final updated = gamification.getChallengeById(challenge.id);

    if (updated != null && updated.isCompleted && !wasDone) {
      _showSnackBar(
        '🎉 Quest Completed! +${updated.rewardXp} XP added to your profile!',
      );
    } else {
      _showSnackBar('⚡ Progress recorded for ${challenge.title}!');
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
