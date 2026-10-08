import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/screens/nutrition/nutrition_screen.dart';

void main() {
  late Directory tempDir;
  final service = NutritionService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('nutrition_ui_test_');
    service.setCustomStoragePath(tempDir.path);
    await service.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildNutritionApp() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const NutritionScreen(),
    );
  }

  testWidgets(
    'NutritionScreen displays targets, 4 categories, and budget hacks',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildNutritionApp());
      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Nutrition & Mess Fuel'), findsOneWidget);

      // Verify Daily Targets Header
      expect(find.text('DAILY TARGETS'), findsOneWidget);
      expect(find.text('CALORIES'), findsOneWidget);
      expect(find.text('PROTEIN'), findsOneWidget);
      expect(find.textContaining('2100 kcal'), findsWidgets);
      expect(find.textContaining('110g'), findsWidgets);

      // Verify all 4 meal categories are present on screen
      expect(find.text('Breakfast'), findsWidgets);
      expect(find.text('Lunch'), findsWidgets);
      expect(find.text('Dinner'), findsWidgets);
      expect(find.text('Snacks'), findsWidgets);

      // Verify Today's Hostel/Mess Menu section is present
      expect(find.text("Today's Hostel/Mess Menu"), findsOneWidget);
      expect(find.text('Evening'), findsWidgets);

      // Verify Add Meal buttons are present
      expect(find.text('Add Meal'), findsWidgets);

      // Verify Affordable Alternatives section
      expect(find.text('Budget Protein Hacks'), findsOneWidget);
      expect(find.textContaining('Soya Chunks'), findsWidgets);
    },
  );

  testWidgets(
    'Tapping Add Meal opens sheet, selects food, sets servings, and updates UI',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildNutritionApp());
      await tester.pumpAndSettle();

      // Open Add Meal sheet using Floating Action Button
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Step 1: Verify Sheet Title and Category Selector
      expect(find.text('Log Meal'), findsOneWidget);
      expect(find.text('Select Meal Category'), findsOneWidget);
      expect(find.text('Select Food Item'), findsOneWidget);
      expect(find.text('Select Serving Quantity'), findsOneWidget);

      // Tap Dalma in food list
      final dalmaTile = find.text('Dalma (Odia Lentil & Veggie Stew)');
      expect(dalmaTile, findsOneWidget);
      await tester.tap(dalmaTile);
      await tester.pumpAndSettle();

      // Verify Calculated Nutrition box is visible
      expect(find.textContaining('Calculated Nutrition'), findsOneWidget);

      // Select 2.0x servings multiplier
      final twoXChip = find.text('2.0x');
      expect(twoXChip, findsOneWidget);
      await tester.tap(twoXChip);
      await tester.pumpAndSettle();

      // Verify calculated values reflect 2.0 servings (Dalma 175 * 2 = 350 kcal)
      expect(find.text('350'), findsOneWidget);

      // Tap "Add to Lunch" (or whichever category is active)
      final addButton = find.textContaining('Add to');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Log Meal'), findsNothing);

      // Verify Nutrition Dashboard totals updated
      expect(find.text('350'), findsOneWidget);
      expect(find.text('17.0g'), findsOneWidget);

      // Verify meal appears in Lunch category section
      expect(find.textContaining('Dalma'), findsWidgets);
      expect(find.textContaining('2.0x'), findsWidgets);
    },
  );

  testWidgets(
    'Selecting Chicken shows affordable alternative swap to Soya Chunks',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildNutritionApp());
      await tester.pumpAndSettle();

      // Tap FAB to open Add Meal sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Filter food list by entering 'Chicken' in search
      await tester.enterText(find.byType(TextField), 'Chicken');
      await tester.pumpAndSettle();

      // Tap Chicken in food list
      final chickenTile = find.text('Chicken (Desi Chicken Curry)');
      expect(chickenTile, findsOneWidget);
      await tester.tap(chickenTile);
      await tester.pumpAndSettle();

      // Verify Affordable Alternative recommendation appears
      expect(
        find.text('Affordable Alternative Recommendation'),
        findsOneWidget,
      );
      expect(find.textContaining('Swap Chicken'), findsWidgets);
      expect(find.text('Switch to Soya'), findsOneWidget);

      // Tap "Switch to Soya"
      await tester.tap(find.text('Switch to Soya'));
      await tester.pumpAndSettle();

      // Selected food should now be Soya Chunks
      expect(find.textContaining('Soya (Soya Chunks Cooked)'), findsWidgets);

      // Add to category
      await tester.tap(find.textContaining('Add to'));
      await tester.pumpAndSettle();

      // Soya Chunks should now be logged with Budget Hack tag
      expect(find.textContaining('Soya'), findsWidgets);
      expect(find.text('Budget Hack'), findsOneWidget);
    },
  );
}
