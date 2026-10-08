import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/hostel_menu_service.dart';
import 'package:genfit/core/services/nutrition_service.dart';
import 'package:genfit/core/services/user_service.dart';
import 'package:genfit/core/theme/app_theme.dart';
import 'package:genfit/data/local_food_database.dart';
import 'package:genfit/models/nutrition/meal_category.dart';
import 'package:genfit/screens/nutrition/nutrition_screen.dart';
import 'package:genfit/screens/nutrition/widgets/hostel_food_detail_sheet.dart';
import 'package:genfit/screens/nutrition/widgets/todays_hostel_menu_card.dart';

void main() {
  late Directory tempDir;
  final nutritionService = NutritionService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hostel_menu_test_');
    nutritionService.setCustomStoragePath(tempDir.path);
    UserService.instance.setCustomStoragePath(tempDir.path);
    await nutritionService.resetToDefaults();
    await UserService.instance.resetToDefaults();
    HostelMenuService.instance.setCustomMenu(null);
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Today\'s Hostel/Mess Menu UI & Section Tests', () {
    testWidgets('renders section header and all 4 meal sections', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(const TodaysHostelMenuCard()));
      await tester.pumpAndSettle();

      // Section Header
      expect(find.text("Today's Hostel/Mess Menu"), findsOneWidget);
      expect(find.text('LIVE MESS'), findsOneWidget);

      // Filter tabs
      expect(find.text('All Meals'), findsOneWidget);

      // All 4 meal sections are organized underneath
      expect(find.text('Breakfast'), findsWidgets);
      expect(find.text('Lunch'), findsWidgets);
      expect(find.text('Evening'), findsWidgets);
      expect(find.text('Dinner'), findsWidgets);
    });

    testWidgets('food items appear as individual items in correct sections', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(const TodaysHostelMenuCard()));
      await tester.pumpAndSettle();

      // Breakfast foods
      expect(find.text('Upma'), findsOneWidget);
      expect(find.text('Poha'), findsOneWidget);
      expect(find.text('Bara'), findsOneWidget);
      expect(find.text('Chakuli Pitha'), findsOneWidget);
      expect(find.text('Chutney'), findsOneWidget);

      // Lunch individual items (No combo meal!)
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Dal'), findsWidgets); // Dal in Lunch and Dinner
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Fish Curry'), findsOneWidget);
      expect(find.text('Soya Bean'), findsOneWidget);
      expect(find.text('Mixed Vegetable'), findsOneWidget);
      expect(find.text('Raita'), findsOneWidget);

      // Evening foods
      expect(find.text('Alu Chop'), findsOneWidget);
      expect(find.text('Dahibara'), findsOneWidget);
      expect(find.text('Peanuts'), findsOneWidget);
      expect(find.text('Sattu Sharbat'), findsOneWidget);

      // Dinner foods
      expect(find.text('Roti'), findsOneWidget);
      expect(find.text('Paratha'), findsOneWidget);
      expect(find.text('Mixed Tadka'), findsOneWidget);
      expect(find.text('Paneer'), findsOneWidget);
      expect(find.text('Egg Curry'), findsOneWidget);
      expect(find.text('Egg Bhurji'), findsOneWidget);
      expect(find.text('Mushroom Curry'), findsOneWidget);
      expect(find.text('Ice Cream'), findsOneWidget);
    });

    testWidgets('tapping filter tabs isolates the selected meal section', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(const TodaysHostelMenuCard()));
      await tester.pumpAndSettle();

      // Tap 'Evening' filter tab
      final eveningTab = find.widgetWithText(InkWell, 'Evening');
      expect(eveningTab, findsOneWidget);
      await tester.tap(eveningTab);
      await tester.pumpAndSettle();

      // In Evening view, Evening items should be visible
      expect(find.text('Alu Chop'), findsOneWidget);
      expect(find.text('Dahibara'), findsOneWidget);

      // Switch back to 'All Meals'
      await tester.tap(find.text('All Meals'));
      await tester.pumpAndSettle();

      expect(find.text('Breakfast'), findsWidgets);
      expect(find.text('Lunch'), findsWidgets);
    });
  });

  group('Food Detail Modal & Nutrition Logging Tests', () {
    testWidgets('tapping food item displays accurate nutrition details sheet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final chicken = LocalFoodDatabase.getFoodById('food_chicken')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      HostelFoodDetailSheet.show(
                        context,
                        food: chicken,
                        category: MealCategory.lunch,
                      );
                    },
                    child: const Text('Open Chicken'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Chicken'));
      await tester.pumpAndSettle();

      // Verify Food details
      expect(find.text('Chicken (Desi Chicken Curry)'), findsOneWidget);
      expect(find.text('Non-Vegetarian'), findsOneWidget);
      expect(find.text('Serving Size: 1 plate / 150g'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);

      // Verify Macros (245 kcal, 31.0g P, 4.0g C, 11.5g F)
      expect(find.text('245'), findsOneWidget);
      expect(find.text('31.0'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('11.5'), findsOneWidget);

      // Verify Action Button exists
      expect(find.textContaining('Add to Lunch'), findsOneWidget);
    });

    testWidgets(
      'logging a food item from sheet updates NutritionService and UI',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final dalma = LocalFoodDatabase.getFoodById('food_dalma')!;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        HostelFoodDetailSheet.show(
                          context,
                          food: dalma,
                          category: MealCategory.lunch,
                        );
                      },
                      child: const Text('Open Dalma'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open sheet
        await tester.tap(find.text('Open Dalma'));
        await tester.pumpAndSettle();

        // Tap Add Meal button
        final addBtn = find.textContaining('Add to Lunch');
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Sheet closed
        expect(find.byType(HostelFoodDetailSheet), findsNothing);

        // Verify NutritionService has logged meal
        expect(nutritionService.todayMeals.length, 1);
        expect(nutritionService.todayMeals.first.foodId, 'food_dalma');
        expect(nutritionService.todayCalories, 175.0);
        expect(nutritionService.todayProtein, 8.5);
      },
    );

    testWidgets(
      'independent food selection without combo locking: logs Rice, Dal, Chicken, Raita separately',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const NutritionScreen()),
        );
        await tester.pumpAndSettle();

        // Verify initial state
        expect(nutritionService.todayMeals.length, 0);

        // 1. Tap Rice in Hostel Menu Card
        final riceChip = find.text('Rice');
        expect(riceChip, findsOneWidget);
        await tester.tap(riceChip);
        await tester.pumpAndSettle();

        // Add Rice to Lunch
        await tester.tap(find.textContaining('Add to Lunch'));
        await tester.pumpAndSettle();

        // 2. Tap Chicken in Hostel Menu Card
        final chickenChip = find.text('Chicken');
        expect(chickenChip, findsOneWidget);
        await tester.tap(chickenChip);
        await tester.pumpAndSettle();

        // Add Chicken to Lunch
        await tester.tap(find.textContaining('Add to Lunch'));
        await tester.pumpAndSettle();

        // 3. Tap Raita in Hostel Menu Card
        final raitaChip = find.text('Raita');
        expect(raitaChip, findsOneWidget);
        await tester.tap(raitaChip);
        await tester.pumpAndSettle();

        // Add Raita to Lunch
        await tester.tap(find.textContaining('Add to Lunch'));
        await tester.pumpAndSettle();

        // Verify all 3 logged as independent items
        expect(nutritionService.todayMeals.length, 3);
        final lunchItems = nutritionService.mealsForCategory(
          MealCategory.lunch,
        );
        expect(lunchItems.length, 3);

        final loggedNames = lunchItems.map((m) => m.name).toList();
        expect(loggedNames, contains('Rice (Cooked White Rice)'));
        expect(loggedNames, contains('Chicken (Desi Chicken Curry)'));
        expect(loggedNames, contains('Raita (Boondi / Cucumber Curd Raita)'));

        // Expected calories: 195 (Rice) + 245 (Chicken) + 85 (Raita) = 525 kcal
        expect(nutritionService.todayCalories, 525.0);
      },
    );
  });
}
