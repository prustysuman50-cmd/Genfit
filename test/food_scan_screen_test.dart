import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/food_recognition_service.dart';
import 'package:genfit/screens/nutrition/food_scan_screen.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePicker extends ImagePicker {
  final XFile? fileToReturn;
  _FakeImagePicker(this.fileToReturn);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return fileToReturn;
  }
}

void main() {
  group('FoodScanScreen Widget Tests', () {
    testWidgets(
      'renders empty state with title, subtitle, and action buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FoodScanScreen()));
        await tester.pumpAndSettle();

        // Title & Subtitle
        expect(find.text('AI Food Scan'), findsOneWidget);
        expect(
          find.textContaining('Capture or select a meal photo'),
          findsOneWidget,
        );

        // Empty State Viewfinder & Guidance
        expect(find.text('No Meal Selected'), findsOneWidget);
        expect(
          find.textContaining('Take a picture of your plate'),
          findsOneWidget,
        );

        // Buttons
        expect(find.text('Scan with Camera'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
      },
    );

    testWidgets(
      'processes picked image and displays food detection result card',
      (WidgetTester tester) async {
        final fakePicker = _FakeImagePicker(
          XFile('/dummy/test/chicken_curry.jpg', name: 'chicken_curry.jpg'),
        );
        const instantRecognitionService = FoodRecognitionService(
          simulatedDelay: Duration.zero,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: FoodScanScreen(
              imagePicker: fakePicker,
              recognitionService: instantRecognitionService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "Scan with Camera" button
        await tester.tap(find.text('Scan with Camera'));
        await tester.pumpAndSettle();

        // "Food Detected" section should be displayed
        expect(find.text('FOOD DETECTED'), findsOneWidget);
        expect(find.text('Chicken Curry'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Confidence'), findsOneWidget);
        expect(find.text('PLATE ITEMS DETECTED'), findsOneWidget);
        expect(find.text('Rice'), findsOneWidget);
        expect(find.text('Dal'), findsOneWidget);

        // Verified baseline nutrition from LocalFoodDatabase should be visible
        expect(find.text('245 kcal'), findsOneWidget);
        expect(find.text('31.0g'), findsOneWidget);
        expect(find.text('4.0g'), findsOneWidget);
        expect(find.text('11.5g'), findsOneWidget);

        // "Review Meal" and "Retake" buttons
        expect(find.text('Review Meal'), findsOneWidget);
        expect(find.text('Retake'), findsOneWidget);

        // Tap Review Meal -> Navigates to FoodScanReviewScreen
        final reviewBtn = find.text('Review Meal');
        await tester.ensureVisible(reviewBtn);
        await tester.tap(reviewBtn);
        await tester.pumpAndSettle();

        // On FoodScanReviewScreen
        expect(find.text('Review & Customize'), findsOneWidget);
        expect(find.text('Confirm & Log Meal'), findsOneWidget);

        // Pop back to FoodScanScreen
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        // Tap Retake restores empty state
        await tester.tap(find.text('Retake'));
        await tester.pumpAndSettle();

        expect(find.text('No Meal Selected'), findsOneWidget);
        expect(find.text('Scan with Camera'), findsOneWidget);
      },
    );
  });
}
