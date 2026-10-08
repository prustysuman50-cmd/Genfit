import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/pose_detection_service.dart';
import 'package:genfit/core/services/push_up_analysis_service.dart';
import 'package:genfit/core/services/squat_analysis_service.dart';
import 'package:genfit/core/services/storage_service.dart';
import 'package:genfit/main.dart';
import 'package:genfit/models/onboarding_profile.dart';
import 'package:genfit/screens/onboarding/onboarding_flow_screen.dart';
import 'package:genfit/screens/onboarding/steps/basic_info_step.dart';
import 'package:genfit/screens/workout/models/exercise.dart';
import 'package:genfit/screens/workout/widgets/ai_viewfinder_preview.dart';
import 'package:genfit/screens/workout/workout_session_screen.dart';

void main() {
  testWidgets('GENFIT app shell and bottom navigation smoke test', (
    WidgetTester tester,
  ) async {
    // Build GENFIT app with completed onboarding state
    await tester.pumpWidget(const GenfitApp(isOnboardingCompleted: true));
    await tester.pumpAndSettle();

    // Verify bottom navigation destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify Home Dashboard elements
    expect(find.textContaining('Ayush'), findsOneWidget);
    expect(find.text('Daily Progress'), findsOneWidget);
    expect(find.text("Today's Workout"), findsOneWidget);
    expect(find.text("Hostel Room High-Burn HIIT"), findsOneWidget);
    expect(find.text("Today's Challenge"), findsOneWidget);
    expect(find.text("Campus Steps Sprint"), findsOneWidget);

    // Switch to Workout tab
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    expect(find.text('Workouts & AI Coach'), findsOneWidget);

    // Switch to Nutrition tab
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition & Mess Fuel'), findsOneWidget);

    // Switch to Journey tab
    await tester.tap(find.text('Journey'));
    await tester.pumpAndSettle();
    expect(find.text('Odisha Fitness Trail'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Athlete Profile'), findsOneWidget);
  });

  testWidgets('GENFIT shows onboarding flow when onboarding is not completed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GenfitApp(isOnboardingCompleted: false));
    await tester.pumpAndSettle();

    expect(find.text('GenFit'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(
      find.text('Smarter Fitness. Local Fuel. Stronger Campus.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'BasicInfoStep initializes and updates without setState during build errors',
    (WidgetTester tester) async {
      int age = 20;
      double height = 172.0;
      double weight = 65.0;
      bool isValid = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BasicInfoStep(
                  initialAge: age,
                  initialHeightCm: height,
                  initialWeightKg: weight,
                  onChanged: (newAge, newHeight, newWeight, valid) {
                    setState(() {
                      age = newAge;
                      height = newHeight;
                      weight = newWeight;
                      isValid = valid;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A bit about your body'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.textContaining('BMI'), findsOneWidget);
      expect(isValid, isTrue);

      // Verify incrementing age updates without runtime exceptions
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      expect(age, 21);
    },
  );

  testWidgets('Get Started button advances from WelcomeStep to Step 1', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GenfitApp(isOnboardingCompleted: false));
    await tester.pumpAndSettle();

    // Verify WelcomeStep is shown
    expect(find.text('GenFit'), findsOneWidget);
    final getStartedBtn = find.widgetWithText(ElevatedButton, 'Get Started');
    expect(getStartedBtn, findsOneWidget);

    // Scroll into view if needed and tap Get Started
    await tester.ensureVisible(getStartedBtn);
    await tester.pumpAndSettle();
    await tester.tap(getStartedBtn);
    await tester.pumpAndSettle();

    // Verify navigation successfully moved to Step 1 (Fitness Goal)
    expect(find.text('What is your main fitness goal?'), findsOneWidget);
    expect(find.text('Step 1 of 10'), findsOneWidget);
  });

  test('StorageService persists profile and completion state across re-initialization', () async {
    final storage = StorageService.instance;
    await storage.resetOnboarding();
    expect(storage.isOnboardingCompleted, isFalse);

    // Save completed profile
    const profile = OnboardingProfile(
      goal: 'Build Muscle',
      workoutLocation: 'Gym',
      isCompleted: true,
    );
    await storage.saveProfile(profile);
    expect(storage.isOnboardingCompleted, isTrue);

    // Simulate app restart by re-initializing storage from disk
    await storage.init();
    expect(storage.isOnboardingCompleted, isTrue);
    expect(storage.profile?.goal, 'Build Muscle');
    expect(storage.profile?.workoutLocation, 'Gym');

    await storage.resetOnboarding();
  });

  testWidgets(
    'Completing final onboarding step navigates to MainNavigationScreen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = StorageService.instance;
      await storage.resetOnboarding();

      await tester.pumpWidget(
        const MaterialApp(home: OnboardingFlowScreen(initialPage: 11)),
      );
      await tester.pumpAndSettle();

      // Verify Enter GenFit button is present on completion step
      final enterBtn = find.widgetWithText(ElevatedButton, 'Enter GenFit');
      expect(enterBtn, findsOneWidget);

      // Tap Enter GENFIT to save and navigate to MainNavigationScreen
      await tester.tap(enterBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Check if MainNavigationScreen is displayed
      expect(find.text('Daily Progress'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(storage.isOnboardingCompleted, isTrue);

      await storage.resetOnboarding();
    },
  );

  testWidgets(
    'AI Workout screen displays all components and opens session screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(const GenfitApp(isOnboardingCompleted: true));
      await tester.pumpAndSettle();

      // Navigate to Workout tab
      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();

      // Verify AI Workout header and subtitle
      expect(find.text('AI Workout Coach'), findsOneWidget);
      expect(
        find.textContaining('The AI pose engine tracks your form'),
        findsOneWidget,
      );

      // Verify "Start AI Workout" button
      expect(
        find.widgetWithText(ElevatedButton, 'Start AI Workout'),
        findsOneWidget,
      );

      // Verify Categories FilterChips
      expect(find.widgetWithText(FilterChip, 'Strength'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Core'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Full Body'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Mobility'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Cardio'), findsOneWidget);

      // Verify Today's Workout section
      expect(find.text("TODAY'S PLAN"), findsOneWidget);
      expect(find.text('Hostel Room High-Burn HIIT'), findsOneWidget);

      // Verify Exercise cards: Squats, Push-ups, Lunges, Jumping Jacks, Plank
      expect(find.text('Squats'), findsWidgets);
      expect(find.text('Push-ups'), findsWidgets);
      expect(find.text('Lunges'), findsWidgets);
      expect(find.text('Jumping Jacks'), findsWidgets);
      expect(find.text('Plank'), findsWidgets);

      // Tap "Start AI Workout" to open session screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start AI Workout'));
      await tester.pumpAndSettle();

      // Verify WorkoutSessionScreen elements
      expect(find.byType(WorkoutSessionScreen), findsOneWidget);
      expect(find.text('AI Workout Session'), findsOneWidget);

      // Workout preview area
      expect(find.byType(AiViewfinderPreview), findsOneWidget);

      // Selected exercise
      expect(find.text('Squats'), findsWidgets);

      // Rep counter starting at 0
      expect(find.text('REP COUNTER'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Form status starting at "Ready"
      expect(find.text('FORM STATUS'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);

      // Start/Stop button
      final startButton = find.widgetWithText(
        ElevatedButton,
        'Start AI Workout',
      );
      expect(startButton, findsOneWidget);

      // Short explanation of future AI camera tracking
      expect(find.text('Future AI Camera Tracking'), findsOneWidget);
      expect(
        find.textContaining('on-device MoveNet / MediaPipe computer vision'),
        findsOneWidget,
      );

      // Test toggle start session
      await tester.ensureVisible(startButton);
      await tester.pumpAndSettle();
      await tester.tap(startButton);
      await tester.pump();

      expect(
        find.widgetWithText(ElevatedButton, 'Stop Workout'),
        findsOneWidget,
      );
      expect(find.text('Tracking • Good Form'), findsOneWidget);

      // Test toggle stop session
      final stopButton = find.widgetWithText(ElevatedButton, 'Stop Workout');
      await tester.ensureVisible(stopButton);
      await tester.pumpAndSettle();
      await tester.tap(stopButton);
      await tester.pump();
      expect(
        find.widgetWithText(ElevatedButton, 'Start AI Workout'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
    },
  );

  testWidgets(
    'WorkoutSessionScreen updates rep counter when SquatAnalysisService detects squats',
    (WidgetTester tester) async {
      final mockPoseService = PoseDetectionService();
      final squatService = SquatAnalysisService(
        standingAngleThreshold: 160.0,
        descendingAngleThreshold: 145.0,
        bottomAngleThreshold: 100.0,
        returningAngleThreshold: 115.0,
        minRepCooldown: Duration.zero,
        smoothingFactor: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutSessionScreen(
            poseDetectionService: mockPoseService,
            squatAnalysisService: squatService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial count is 0
      expect(find.text('0'), findsOneWidget);

      // Start workout
      final startBtn = find.widgetWithText(ElevatedButton, 'Start AI Workout');
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Simulate full squat: standing -> descending -> bottom -> returning -> standing
      squatService.processAngle(170.0);
      squatService.processAngle(130.0);
      squatService.processAngle(90.0);
      squatService.processAngle(120.0);
      squatService.processAngle(165.0);
      await tester.pump();

      // Rep counter should now display 1 and feedback shows Good rep!
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Good rep'), findsOneWidget);

      // Also verify "Simulate AI Counted Rep (+1)" button increments
      final simulateBtn = find.widgetWithText(
        OutlinedButton,
        'Simulate AI Counted Rep (+1)',
      );
      expect(simulateBtn, findsOneWidget);
      await tester.ensureVisible(simulateBtn);
      await tester.pumpAndSettle();
      await tester.tap(simulateBtn);
      await tester.pumpAndSettle();

      // Rep counter should now display 2!
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'WorkoutSessionScreen updates rep counter when PushUpAnalysisService detects push-ups',
    (WidgetTester tester) async {
      final mockPoseService = PoseDetectionService();
      final pushUpService = PushUpAnalysisService(
        topAngleThreshold: 160.0,
        descendingAngleThreshold: 145.0,
        bottomAngleThreshold: 95.0,
        returningAngleThreshold: 110.0,
        minRepCooldown: Duration.zero,
        smoothingFactor: 1.0,
      );

      final pushUpExercise = Exercise.sampleExercises.firstWhere(
        (e) => e.id == 'ex_pushups',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutSessionScreen(
            initialExercise: pushUpExercise,
            poseDetectionService: mockPoseService,
            pushUpAnalysisService: pushUpService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Push-ups exercise name displayed
      expect(find.text('Push-ups'), findsWidgets);
      expect(find.text('0'), findsOneWidget);

      // Start workout
      final startBtn = find.widgetWithText(ElevatedButton, 'Start AI Workout');
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Complete push-up: top -> descending -> bottom -> returning -> top
      pushUpService.processAngle(165.0);
      pushUpService.processAngle(135.0);
      pushUpService.processAngle(90.0);
      pushUpService.processAngle(120.0);
      pushUpService.processAngle(165.0);
      await tester.pump();

      // Rep counter should display 1 and feedback 'Good rep'
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Good rep'), findsOneWidget);

      // Simulate button increments push-up rep counter
      final simulateBtn = find.widgetWithText(
        OutlinedButton,
        'Simulate AI Counted Rep (+1)',
      );
      await tester.ensureVisible(simulateBtn);
      await tester.pumpAndSettle();
      await tester.tap(simulateBtn);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    },
  );
}
