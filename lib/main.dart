import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'core/services/community_service.dart';
import 'core/services/daily_stats_service.dart';
import 'core/services/gamification_service.dart';
import 'core/services/nutrition_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/user_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage service, user service, daily stats service, nutrition service, gamification service, and community service
  try {
    await StorageService.instance.init();
    await UserService.instance.init();
    await DailyStatsService.instance.init();
    await NutritionService.instance.init();
    await DailyStatsService.instance.syncNutritionFromService();
    await GamificationService.instance.init();
    await CommunityService.instance.init();
  } catch (e) {
    debugPrint('Service initialization error: $e');
  }

  runApp(const GenfitApp());
}

class GenfitApp extends StatefulWidget {
  final bool? isOnboardingCompleted;

  const GenfitApp({super.key, this.isOnboardingCompleted});

  @override
  State<GenfitApp> createState() => _GenfitAppState();
}

class _GenfitAppState extends State<GenfitApp> {
  late bool _isOnboardingCompleted;

  @override
  void initState() {
    super.initState();
    _isOnboardingCompleted =
        widget.isOnboardingCompleted ??
        StorageService.instance.isOnboardingCompleted;
  }

  void _onOnboardingCompleted() {
    if (!mounted) return;
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isOnboardingCompleted = true;
          });
        }
      });
    } else {
      setState(() {
        _isOnboardingCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool completed =
        widget.isOnboardingCompleted ?? _isOnboardingCompleted;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GenFit',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: completed
          ? const MainNavigationScreen()
          : OnboardingFlowScreen(onCompleted: _onOnboardingCompleted),
    );
  }
}
