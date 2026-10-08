import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/models/user_profile.dart';
import 'package:genfit/screens/home/widgets/streak_xp_banner.dart';
import 'package:genfit/screens/main_navigation_screen.dart';

void main() {
  testWidgets('Reproduce Home screen RenderFlex overflow on narrow Android screen (360x760)', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0]) {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to layout all cards (hero workout, quick actions, daily progress, streak/xp, challenge, coach, hostel fuel, recent activity)
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('StreakXpBanner responsive on 320px and 360px with large values', (tester) async {
    for (final width in [320.0, 360.0]) {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreakXpBanner(
                user: UserProfile(
                  id: 'u1',
                  name: 'Dr. Alexander Bartholomew Montgomery III',
                  level: 99,
                  xp: 125000,
                  customLevelProgress: 0.85,
                  streakDays: 365,
                  levelTitle: 'Grandmaster Champion Legend',
                  college: 'Indian Institute of Technology Bhubaneswar',
                  campus: 'Main Academic Campus',
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
  });
}
