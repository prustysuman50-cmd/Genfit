import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'community/community_screen.dart';
import 'home/home_screen.dart';
import 'journey/journey_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'profile/profile_screen.dart';
import 'workout/workout_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onNavigateToTab: _onTabSelected),
      const WorkoutScreen(),
      const NutritionScreen(),
      const JourneyScreen(),
      const ProfileScreen(),
      const CommunityScreen(),
    ];

    final navItems = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.fitness_center_outlined, Icons.fitness_center_rounded, 'Workout'),
      (Icons.restaurant_outlined, Icons.restaurant_rounded, 'Nutrition'),
      (Icons.explore_outlined, Icons.explore_rounded, 'Journey'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
      (Icons.people_outline_rounded, Icons.people_rounded, 'Community'),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF14141D).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.cardBorderDark.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primaryGlow.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = _currentIndex == index;
              final (inactiveIcon, activeIcon, label) = navItems[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? activeIcon : inactiveIcon,
                          size: 21,
                          color: isSelected
                              ? AppColors.brightPurple
                              : AppColors.textMutedDark,
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.brightPurple
                                  : AppColors.textMutedDark,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
