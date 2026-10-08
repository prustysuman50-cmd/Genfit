import 'package:flutter/material.dart';

import '../../../core/branding/genfit_symbol.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Official GenFit Athlete+G Symbol
          const GenfitSymbol(size: 78),
          const SizedBox(height: 18),
          // App Title
          const Text(
            'GenFit',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          // Tagline
          const Text(
            'Smarter Fitness. Local Fuel. Stronger Campus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          // Short Explanation
          Text(
            'A hyper-personalized fitness & nutrition companion built for college students. Tell us about your routine, and we will build your customized daily roadmap.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // 3 Value Pillars
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Column(
              children: [
                _buildPillarRow(
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  title: 'Dorm & Hostel Workouts',
                  subtitle: 'No equipment needed, tailored to tight spaces',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.dividerDark),
                ),
                _buildPillarRow(
                  icon: Icons.restaurant_rounded,
                  color: AppColors.primary,
                  title: 'Affordable Indian Nutrition',
                  subtitle:
                      'Mess hacks, high protein, and pocket-friendly food',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.dividerDark),
                ),
                _buildPillarRow(
                  icon: Icons.explore_rounded,
                  color: AppColors.primary,
                  title: 'Odisha Trails & Campus Quests',
                  subtitle: 'Compete, earn XP, and climb student leaderboards',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPillarRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 2),
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
      ],
    );
  }
}
