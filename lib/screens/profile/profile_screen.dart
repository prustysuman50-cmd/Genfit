import 'package:flutter/material.dart';

import '../../core/branding/genfit_app_icon.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../gamification/widgets/campus_rank_roadmap_sheet.dart';
import '../progress/progress_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        UserService.instance,
        GamificationService.instance,
      ]),
      builder: (context, _) {
        final rawUser = UserService.instance.currentUser;
        final g = GamificationService.instance;
        final user = rawUser.copyWith(
          xp: g.xp,
          level: g.currentLevel,
          levelTitle: g.levelTitle,
          streakDays: g.streakDays,
        );

        final levelProgress = g.levelProgress;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: const Text('Athlete Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.insights_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProgressScreen(),
                    ),
                  );
                },
                tooltip: 'Your Progress',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
                tooltip: 'Settings',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              children: [
                // 1. TOP ATHLETE HEADER CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.purpleGlow.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with Glowing Purple Ring
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevatedDark,
                          border: Border.all(
                            color: AppColors.brightPurple,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purpleGlow.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.avatarInitials,
                            style: const TextStyle(
                              color: AppColors.brightPurple,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: AppColors.brightPurple,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.campus.isNotEmpty &&
                                      !user.college.contains(user.campus)
                                  ? '${user.college} • ${user.campus}'
                                  : user.college,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 2. LARGE PROGRESSION SECTION (Tappable to view Campus Rank Roadmap)
                      InkWell(
                        onTap: () => CampusRankRoadmapSheet.show(context),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22173B), Color(0xFF14141D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.brightPurple.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'LEVEL ${user.level}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.brightPurple,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.levelTitle.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimaryDark,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${user.xp} XP',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.accentYellow,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        '${user.streakDays} Day Streak',
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
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: levelProgress,
                                  minHeight: 7,
                                  backgroundColor: AppColors.surfaceElevatedDark,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.brightPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    g.isMaxRank
                                        ? 'Max Campus Rank Achieved'
                                        : '${g.xpRequiredForNextLevel} XP to Level ${user.level + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondaryDark,
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'Campus Ranks',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brightPurple,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 14,
                                        color: AppColors.brightPurple,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. PHYSICAL VITALS ROW
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevatedDark.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cardBorderDark.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildVitalItem(
                              'Age',
                              '${user.age} yrs',
                              Icons.cake_outlined,
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: AppColors.cardBorderDark,
                            ),
                            _buildVitalItem(
                              'Height',
                              '${user.heightCm.toInt()} cm',
                              Icons.height_rounded,
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: AppColors.cardBorderDark,
                            ),
                            _buildVitalItem(
                              'Weight',
                              '${user.weightKg.toInt()} kg',
                              Icons.scale_rounded,
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: AppColors.cardBorderDark,
                            ),
                            _buildVitalItem(
                              'BMI',
                              user.bmi.toStringAsFixed(1),
                              Icons.monitor_weight_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. PERSONALIZED FITNESS & LIFESTYLE PROFILE
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                            Icons.tune_rounded,
                            size: 16,
                            color: AppColors.brightPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FITNESS & LIFESTYLE PROFILE',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.brightPurple,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildPreferenceRow(
                        icon: Icons.track_changes_rounded,
                        label: 'Fitness Goal',
                        value: user.fitnessGoal,
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildPreferenceRow(
                        icon: Icons.fitness_center_rounded,
                        label: 'Fitness Level',
                        value: user.fitnessLevel,
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildPreferenceRow(
                        icon: Icons.restaurant_rounded,
                        label: 'Diet Preference',
                        value: user.dietPreference,
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildPreferenceRow(
                        icon: Icons.savings_rounded,
                        label: 'Budget Preference',
                        value: user.budgetPreference,
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildPreferenceRow(
                        icon: Icons.location_city_rounded,
                        label: 'Campus',
                        value: user.campus,
                      ),
                    ],
                  ),
                ),

                // 5. PROGRESS & SETTINGS ACTION TILES
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.insights_rounded,
                        title: 'Your Progress & Recommendations',
                        subtitle:
                            'Weekly overview • 7-day chart • Adaptive tips',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProgressScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildSettingTile(
                        icon: Icons.track_changes_rounded,
                        title: 'Daily Fitness Goals',
                        subtitle: '10,000 steps • 3.0L water • 650 kcal',
                        onTap: () {},
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildSettingTile(
                        icon: Icons.shield_outlined,
                        title: 'AI Camera & Privacy',
                        subtitle: 'Local on-device inference • No cloud upload',
                        onTap: () {},
                      ),
                      const Divider(color: AppColors.dividerDark),
                      _buildSettingTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Campus & Class Reminders',
                        subtitle: 'Hydration and post-class walk alerts',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // 6. ABOUT GENFIT BRAND CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Row(
                    children: [
                      const GenfitAppIcon(size: 42, hasBorder: false),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GenFit v1.0.0',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Smarter Fitness. Local Fuel. Stronger Campus.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryDark,
                                fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.brightPurple),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMutedDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brightPurple, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMutedDark,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.brightPurple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
