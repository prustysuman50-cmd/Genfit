import 'package:flutter/material.dart';

import '../../core/services/accountability_service.dart';
import '../../core/services/daily_stats_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/community/accountability_partner.dart';

/// Screen presenting the Accountability Partner dashboard,
/// mutual check-in action, side-by-side fitness comparison, and motivational feedback.
class AccountabilityPartnerScreen extends StatefulWidget {
  const AccountabilityPartnerScreen({super.key});

  @override
  State<AccountabilityPartnerScreen> createState() =>
      _AccountabilityPartnerScreenState();
}

class _AccountabilityPartnerScreenState
    extends State<AccountabilityPartnerScreen> {
  final AccountabilityService _service = AccountabilityService.instance;

  @override
  void initState() {
    super.initState();
    if (!_service.isInitialized) {
      _service.init();
    }
  }

  Future<void> _handleCheckIn() async {
    final success = await _service.checkInToday();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Checked in! +20 XP awarded. Streak protected!',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Already checked in for today!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.surfaceElevatedDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _sendNudge(AccountabilityPartner partner) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nudge sent to ${partner.name}! Keep each other consistent.',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Accountability Partner'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _service,
          UserService.instance,
          GamificationService.instance,
          DailyStatsService.instance,
        ]),
        builder: (context, _) {
          final user = UserService.instance.currentUser;
          final gamification = GamificationService.instance;
          final dailyStats = DailyStatsService.instance;
          final partner = _service.partner;

          final isUserDone = _service.isUserCheckedInToday();
          final isPartnerDone = _service.isPartnerCheckedInToday;

          final userSteps = dailyStats.todayStats.steps;
          final userWorkouts = dailyStats.todayStats.workoutsCompleted;
          final userStreak = gamification.streakDays;
          final userXp = gamification.xp;
          final userLevel = gamification.currentLevel;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Subtitle
                const Text(
                  'Train with a classmate. Never miss a day.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),

                // 2. Duo Partner Hero Card (You + Partner)
                _buildDuoHeroCard(
                  user: user,
                  partner: partner,
                  isUserDone: isUserDone,
                  isPartnerDone: isPartnerDone,
                ),
                const SizedBox(height: 16),

                // 3. Mutual Accountability Motivational Message Card
                _buildMotivationCard(_service.accountabilityMessage),
                const SizedBox(height: 20),

                // 4. Daily Check-in Action Box
                _buildDailyCheckInCard(isUserDone),
                const SizedBox(height: 24),

                // 5. Side-by-Side Comparison Section
                Text(
                  'Partner Comparison',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildComparisonCard(
                  userName: user.name,
                  partnerName: partner.name.split(' ').first,
                  userStreak: userStreak,
                  partnerStreak: partner.streakDays,
                  userSteps: userSteps,
                  partnerSteps: partner.todaySteps,
                  userWorkouts: userWorkouts,
                  partnerWorkouts: partner.todayWorkoutCompleted ? 1 : 0,
                  userXp: userXp,
                  partnerXp: partner.xp,
                  userLevel: userLevel,
                  partnerLevel: partner.level,
                ),
                const SizedBox(height: 24),

                // 6. Partner Details & Nudge Button
                _buildPartnerProfileCard(partner),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Top Duo Card showing both avatars, names, and mutual check-in badges
  Widget _buildDuoHeroCard({
    required dynamic user,
    required AccountabilityPartner partner,
    required bool isUserDone,
    required bool isPartnerDone,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // You Column
          Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.avatarInitials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    _buildCheckInIndicator(isUserDone),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusPill(isUserDone),
              ],
            ),
          ),

          // Handshake Connection Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevatedDark,
              border: Border.all(
                color: AppColors.dividerDark,
              ),
            ),
            child: const Icon(
              Icons.handshake_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          // Partner Column
          Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevatedDark,
                        border: Border.all(
                          color: AppColors.accentYellow,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          partner.avatarInitials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentYellow,
                          ),
                        ),
                      ),
                    ),
                    _buildCheckInIndicator(isPartnerDone),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  partner.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'PARTNER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentYellow,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusPill(isPartnerDone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInIndicator(bool isCheckedIn) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isCheckedIn ? const Color(0xFF4CAF50) : AppColors.cardBorderDark,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceDark, width: 2),
      ),
      child: Center(
        child: Icon(
          isCheckedIn ? Icons.check : Icons.close,
          size: 11,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isCheckedIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCheckedIn
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : AppColors.cardBorderDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isCheckedIn ? 'Checked in' : 'Pending',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isCheckedIn
              ? const Color(0xFF4CAF50)
              : AppColors.textSecondaryDark,
        ),
      ),
    );
  }

  /// Dynamic Motivation Card
  Widget _buildMotivationCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.accentYellow,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Daily Check-in Card & Action Button
  Widget _buildDailyCheckInCard(bool isUserDone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUserDone
              ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUserDone ? "Today's Check-in Complete!" : "Today's Mutual Check-in",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+20 XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isUserDone
                ? "You checked in for today! Consistency streak protected."
                : "Check in with your partner to confirm your training and keep each other motivated.",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isUserDone
                ? OutlinedButton.icon(
                    onPressed: () => _handleCheckIn(), // Will show "already checked in" feedback
                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
                    label: const Text(
                      'Checked In for Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4CAF50)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _handleCheckIn,
                    icon: const Icon(Icons.check_rounded, color: Colors.black),
                    label: const Text(
                      'Check In Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Side-by-side Progress Comparison Grid
  Widget _buildComparisonCard({
    required String userName,
    required String partnerName,
    required int userStreak,
    required int partnerStreak,
    required int userSteps,
    required int partnerSteps,
    required int userWorkouts,
    required int partnerWorkouts,
    required int userXp,
    required int partnerXp,
    required int userLevel,
    required int partnerLevel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        children: [
          // Header Row with column names
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'METRIC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'You ($userName)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentYellow,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.dividerDark, height: 1),
          const SizedBox(height: 10),

          _buildComparisonRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.accentOrange,
            title: 'Streak',
            userValue: '${userStreak}d',
            partnerValue: '${partnerStreak}d',
          ),
          _buildComparisonRow(
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFF64B5F6),
            title: "Today's Steps",
            userValue: userSteps.toString(),
            partnerValue: partnerSteps.toString(),
          ),
          _buildComparisonRow(
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF81C784),
            title: "Today's Workout",
            userValue: userWorkouts > 0 ? 'Completed' : 'Pending',
            partnerValue: partnerWorkouts > 0 ? 'Completed' : 'Pending',
          ),
          _buildComparisonRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.accentYellow,
            title: 'Total XP',
            userValue: '$userXp XP',
            partnerValue: '$partnerXp XP',
          ),
          _buildComparisonRow(
            icon: Icons.military_tech_rounded,
            iconColor: AppColors.primary,
            title: 'Level',
            userValue: 'LVL $userLevel',
            partnerValue: 'LVL $partnerLevel',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String userValue,
    required String partnerValue,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              userValue,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              partnerValue,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Partner Profile Summary Card with Send Motivation Button
  Widget _buildPartnerProfileCard(AccountabilityPartner partner) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentYellow.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.accentYellow, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    partner.avatarInitials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.accentYellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${partner.levelTitle} • LVL ${partner.level}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _sendNudge(partner),
                icon: const Icon(Icons.flash_on_rounded, size: 14),
                label: const Text('Nudge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentYellow,
                  side: const BorderSide(color: AppColors.accentYellow),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 12, color: AppColors.textSecondaryDark),
              const SizedBox(width: 4),
              Text(
                partner.college,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.apartment_rounded, size: 12, color: AppColors.textSecondaryDark),
              const SizedBox(width: 4),
              Text(
                partner.hostel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    partner.motivationalNote,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimaryDark,
                    ),
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
