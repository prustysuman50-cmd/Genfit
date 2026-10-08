import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/services/storage_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_profile.dart';
import '../main_navigation_screen.dart';
import 'steps/basic_info_step.dart';
import 'steps/completion_step.dart';
import 'steps/multi_choice_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/single_choice_step.dart';
import 'steps/welcome_step.dart';
import 'widgets/onboarding_progress_bar.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final int initialPage;

  const OnboardingFlowScreen({
    super.key,
    this.onCompleted,
    this.initialPage = 0,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final PageController _pageController;
  late int _currentPage;
  final int _totalQuestionSteps = 10; // Pages 1 to 10

  OnboardingProfile _profile = const OnboardingProfile();
  bool _isBasicInfoValid = true;
  bool _isPersonalInfoValid = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    _isPersonalInfoValid =
        _profile.name.trim().isNotEmpty && _profile.college.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 11 && _pageController.hasClients) {
      final next = _currentPage + 1;
      setState(() {
        _currentPage = next;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          if (next == 1 || next == 11) {
            _pageController.jumpToPage(next);
          } else {
            _pageController.animateToPage(
              next,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0 && _pageController.hasClients) {
      final prev = _currentPage - 1;
      setState(() {
        _currentPage = prev;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          if (prev == 0 || prev == 10) {
            _pageController.jumpToPage(prev);
          } else {
            _pageController.animateToPage(
              prev,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      });
    }
  }

  bool _isNavigatingToDashboard = false;

  Future<void> _handleFinishOnboarding() async {
    if (_isNavigatingToDashboard) return;
    _isNavigatingToDashboard = true;

    bool saveSucceeded = false;
    try {
      final completedProfile = _profile.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      // 1. Save profile to persistent storage
      await StorageService.instance.saveProfile(completedProfile);
      // 2. Mark onboarding as completed in storage
      await StorageService.instance.setOnboardingCompleted(true);
      // 3. Sync into centralized UserProfile
      await UserService.instance.syncFromOnboarding(completedProfile);

      saveSucceeded = StorageService.instance.isOnboardingCompleted;
    } catch (e) {
      debugPrint('Error saving completed onboarding profile: $e');
      saveSucceeded = false;
    }

    // 3. Ensure navigation happens only after the save operation succeeds
    if (!saveSucceeded) {
      _isNavigatingToDashboard = false;
      return;
    }

    if (!mounted) return;

    // 4. Notify parent app state
    widget.onCompleted?.call();

    // 5. Navigate to MainNavigationScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  bool _isCurrentStepValid() {
    switch (_currentPage) {
      case 0: // Welcome
        return true;
      case 1: // Goal
        return _profile.goal.isNotEmpty;
      case 2: // Location
        return _profile.workoutLocation.isNotEmpty;
      case 3: // Equipment
        return _profile.equipment.isNotEmpty;
      case 4: // Basic Info (Vitals)
        return _isBasicInfoValid;
      case 5: // Personal Info (Student Identity)
        return _isPersonalInfoValid;
      case 6: // Level
        return _profile.fitnessLevel.isNotEmpty;
      case 7: // Diet
        return _profile.dietaryPreference.isNotEmpty;
      case 8: // Budget
        return _profile.foodBudget.isNotEmpty;
      case 9: // Motivation
        return _profile.motivations.isNotEmpty;
      case 10: // Journey
        return _profile.journeyPreference.isNotEmpty;
      case 11: // Completion
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStepValid = _isCurrentStepValid();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar (Shown during Steps 1 to 10)
            if (_currentPage > 0 && _currentPage < 11)
              OnboardingProgressBar(
                currentStep: _currentPage,
                totalSteps: _totalQuestionSteps,
                onBack: _previousPage,
              ),

            // Page View Container
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  if (_currentPage != page) {
                    setState(() {
                      _currentPage = page;
                    });
                  }
                },
                children: [
                  // 1. Welcome
                  WelcomeStep(onContinue: _nextPage),

                  // 2. Fitness Goal (Step 1 of 10)
                  SingleChoiceStep(
                    title: 'What is your main fitness goal?',
                    subtitle: 'We will tailor your daily workout circuits and target calorie burns.',
                    selectedValue: _profile.goal,
                    options: const [
                      SingleChoiceOption(
                        value: 'Lose Fat',
                        title: 'Lose Fat',
                        description: 'Torch body fat and lean down with high-energy HIIT & cardio.',
                        icon: Icons.local_fire_department_rounded,
                        badgeText: 'High Demand',
                      ),
                      SingleChoiceOption(
                        value: 'Build Muscle',
                        title: 'Build Muscle',
                        description:
                            'Increase strength and pack on lean muscle mass.',
                        icon: Icons.fitness_center_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Stay Fit',
                        title: 'Stay Fit',
                        description: 'Maintain healthy energy levels and stay active alongside classes.',
                        icon: Icons.favorite_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Improve Stamina',
                        title: 'Improve Stamina',
                        description: 'Supercharge aerobic capacity, endurance, and everyday vitality.',
                        icon: Icons.directions_run_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Overall Health',
                        title: 'Overall Health',
                        description: 'Harmonious blend of mobility, posture correction, and mental wellness.',
                        icon: Icons.spa_rounded,
                      ),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _profile = _profile.copyWith(goal: val);
                      });
                    },
                  ),

                  // 3. Workout Location (Step 2 of 10)
                  SingleChoiceStep(
                    title: 'Where do you prefer to train?',
                    subtitle: 'Pick your primary workout environment so exercises fit your space.',
                    selectedValue: _profile.workoutLocation,
                    options: const [
                      SingleChoiceOption(
                        value: 'Home',
                        title: 'Home / Hostel Room',
                        description: 'Quiet dorm friendly workouts requiring minimal floor space.',
                        icon: Icons.home_rounded,
                        badgeText: 'Campus Favorite',
                      ),
                      SingleChoiceOption(
                        value: 'Gym',
                        title: 'College / Local Gym',
                        description: 'Access to barbells, machines, cables, and heavy iron.',
                        icon: Icons.fitness_center_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Outdoor',
                        title: 'Outdoor & Campus Track',
                        description: 'Running fields, stadium stairs, and open air bodyweight areas.',
                        icon: Icons.park_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Combination',
                        title: 'Combination',
                        description: 'Flexible blend of dorm room sessions, track runs, and gym visits.',
                        icon: Icons.sync_alt_rounded,
                      ),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _profile = _profile.copyWith(workoutLocation: val);
                      });
                    },
                  ),

                  // 4. Equipment (Step 3 of 10, Multi-select)
                  MultiChoiceStep(
                    title: 'What equipment do you have?',
                    subtitle: 'Select all gear available to you. Zero equipment works completely fine!',
                    selectedValues: _profile.equipment,
                    options: const [
                      MultiChoiceOption(
                        value: 'Bodyweight',
                        title: 'Bodyweight',
                        description:
                            'Zero gear required. Pure natural movement.',
                        icon: Icons.accessibility_new_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Exercise Mat',
                        title: 'Exercise Mat / Yoga Mat',
                        description: 'Comfortable padding for floor exercises and core work.',
                        icon: Icons.crop_landscape_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Dumbbells',
                        title: 'Dumbbells',
                        description:
                            'Pair of free weights or adjustable dumbbells.',
                        icon: Icons.fitness_center_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Resistance Bands',
                        title: 'Resistance Bands',
                        description: 'Compact, hostel-friendly bands for tension workouts.',
                        icon: Icons.all_inclusive_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Pull-up Bar',
                        title: 'Pull-up Bar',
                        description:
                            'Doorway bar or campus calisthenics station.',
                        icon: Icons.horizontal_rule_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Full Gym',
                        title: 'Full Gym Equipment',
                        description: 'Benches, squat racks, cable machines, and leg press.',
                        icon: Icons.domain_rounded,
                      ),
                    ],
                    onSelectionChanged: (vals) {
                      setState(() {
                        _profile = _profile.copyWith(equipment: vals);
                      });
                    },
                  ),

                  // 5. Basic Information (Step 4 of 10)
                  BasicInfoStep(
                    initialAge: _profile.age,
                    initialHeightCm: _profile.heightCm,
                    initialWeightKg: _profile.weightKg,
                    onChanged: (age, height, weight, isValid) {
                      void updateState() {
                        if (!mounted) return;
                        setState(() {
                          _profile = _profile.copyWith(
                            age: age,
                            heightCm: height,
                            weightKg: weight,
                          );
                          _isBasicInfoValid = isValid;
                        });
                      }

                      if (WidgetsBinding.instance.schedulerPhase ==
                          SchedulerPhase.persistentCallbacks) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => updateState(),
                        );
                      } else {
                        updateState();
                      }
                    },
                  ),

                  // 6. Personal Information (Step 5 of 10)
                  PersonalInfoStep(
                    initialName: _profile.name,
                    initialCollege: _profile.college,
                    initialCampus: _profile.campus,
                    onChanged: (name, college, campus, isValid) {
                      void updateState() {
                        if (!mounted) return;
                        setState(() {
                          _profile = _profile.copyWith(
                            name: name,
                            college: college,
                            campus: campus,
                          );
                          _isPersonalInfoValid = isValid;
                        });
                      }

                      if (WidgetsBinding.instance.schedulerPhase ==
                          SchedulerPhase.persistentCallbacks) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => updateState(),
                        );
                      } else {
                        updateState();
                      }
                    },
                  ),

                  // 7. Fitness Level (Step 6 of 10)
                  SingleChoiceStep(
                    title: 'What is your fitness level?',
                    subtitle: 'We calibrate starting rep volumes and progression ramps to avoid burnout.',
                    selectedValue: _profile.fitnessLevel,
                    options: const [
                      SingleChoiceOption(
                        value: 'Beginner',
                        title: 'Beginner',
                        description: 'Starting fresh or resuming after a long break. 0–1 workouts/week.',
                        icon: Icons.eco_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Intermediate',
                        title: 'Intermediate',
                        description: 'Active 2–3 days per week with familiar exercise mechanics.',
                        icon: Icons.trending_up_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Advanced',
                        title: 'Advanced',
                        description: 'Consistent athlete training 4+ days/week seeking peak performance.',
                        icon: Icons.bolt_rounded,
                      ),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _profile = _profile.copyWith(fitnessLevel: val);
                      });
                    },
                  ),

                  // 7. Dietary Preference (Step 6 of 10)
                  SingleChoiceStep(
                    title: 'What is your dietary preference?',
                    subtitle: 'We highlight protein-rich foods that match your lifestyle and mess menu.',
                    selectedValue: _profile.dietaryPreference,
                    options: const [
                      SingleChoiceOption(
                        value: 'Vegetarian',
                        title: 'Vegetarian',
                        description: 'Sattu, lentils, paneer, sprouts, milk, curd, and legumes.',
                        icon: Icons.grass_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Eggetarian',
                        title: 'Eggetarian',
                        description: 'Vegetarian diet augmented with whole eggs & egg whites.',
                        icon: Icons.egg_outlined,
                        badgeText: 'Popular Student Choice',
                      ),
                      SingleChoiceOption(
                        value: 'Non-vegetarian',
                        title: 'Non-vegetarian',
                        description: 'Chicken, fish, eggs, along with traditional vegetarian staples.',
                        icon: Icons.set_meal_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Vegan',
                        title: 'Vegan',
                        description: '100% plant-based foods, legumes, seeds, nuts, and tofu.',
                        icon: Icons.spa_rounded,
                      ),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _profile = _profile.copyWith(dietaryPreference: val);
                      });
                    },
                  ),

                  // 8. Food Budget (Step 7 of 10)
                  SingleChoiceStep(
                    title: 'What is your food budget?',
                    subtitle: 'Healthy fitness nutrition should never strain a college student budget.',
                    selectedValue: _profile.foodBudget,
                    options: const [
                      SingleChoiceOption(
                        value: 'Budget Friendly',
                        title: 'Budget Friendly (Hostel Focus)',
                        description: 'Smart mess food upgrades, roasted chana, sattu drinks under ₹50/meal.',
                        icon: Icons.savings_rounded,
                        badgeText: 'Pocket Saver',
                      ),
                      SingleChoiceOption(
                        value: 'Moderate',
                        title: 'Moderate',
                        description: 'Mess food plus daily eggs, fruits, paneer, and peanut butter (₹50–₹120/meal).',
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Flexible',
                        title: 'Flexible',
                        description: 'Custom groceries, chicken meals, whey protein, and dining variety.',
                        icon: Icons.credit_card_rounded,
                      ),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _profile = _profile.copyWith(foodBudget: val);
                      });
                    },
                  ),

                  // 9. Motivation (Step 8 of 10, Multi-select)
                  MultiChoiceStep(
                    title: 'What keeps you motivated?',
                    subtitle: 'Select all triggers that inspire you to stay disciplined and show up.',
                    selectedValues: _profile.motivations,
                    options: const [
                      MultiChoiceOption(
                        value: 'Streaks',
                        title: 'Daily Streaks',
                        description: 'Keeping an unbroken chain of daily activity alive.',
                        icon: Icons.local_fire_department_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Competition',
                        title: 'Campus Competition',
                        description: 'Beating college friends on weekly step & fitness leaderboards.',
                        icon: Icons.leaderboard_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Progress',
                        title: 'Measurable Progress',
                        description: 'Seeing strength numbers climb and body transformation tracking.',
                        icon: Icons.show_chart_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Friends',
                        title: 'Friends & Peer Support',
                        description: 'Training together with hostel and batch companions.',
                        icon: Icons.group_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Achievements',
                        title: 'Badges & XP Quests',
                        description: 'Collecting unlockable badges and leveling up your fitness rank.',
                        icon: Icons.military_tech_rounded,
                      ),
                      MultiChoiceOption(
                        value: 'Transformation',
                        title: 'Personal Transformation',
                        description: 'Building unshakeable mental clarity, posture, and confidence.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ],
                    onSelectionChanged: (vals) {
                      setState(() {
                        _profile = _profile.copyWith(motivations: vals);
                      });
                    },
                  ),

                  // 10. Journey Preference (Step 9 of 10)
                  SingleChoiceStep(
                    title: 'Choose your journey style',
                    subtitle: 'Select the primary theme that makes your daily fitness journey exciting.',
                    selectedValue: _profile.journeyPreference,
                    options: const [
                      SingleChoiceOption(
                        value: 'Personal Journey',
                        title: 'Personal Journey',
                        description: 'Private self-improvement focused on personal metrics and records.',
                        icon: Icons.person_rounded,
                      ),
                      SingleChoiceOption(
                        value: 'Campus Champion',
                        title: 'Campus Champion',
                        description: 'Compete against peers from your university and hostel block.',
                        icon: Icons.school_rounded,
                        badgeText: 'Hackathon Theme',
                      ),
                      SingleChoiceOption(
                        value: 'Explore Odisha',
                        title: 'Explore Odisha Heritage',
                        description: 'Convert your steps into virtual treks across Konark, Puri, and Chilika.',
                        icon: Icons.explore_rounded,
                      ),
                    ],
                    onSelected: (val) {
                      setState(() {
                        _profile = _profile.copyWith(journeyPreference: val);
                      });
                    },
                  ),

                  // 11. Completion (Step 10 of 10)
                  CompletionStep(
                    profile: _profile,
                    onEnterApp: _handleFinishOnboarding,
                  ),
                ],
              ),
            ),

            // Bottom Navigation CTA (Steps 1 to 10)
            if (_currentPage > 0 && _currentPage < 11)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: const Border(
                    top: BorderSide(color: AppColors.cardBorderDark, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isStepValid ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceElevatedDark,
                      foregroundColor: Colors.black,
                      disabledForegroundColor: AppColors.textMutedDark,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == 10 ? 'Complete Profile' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
