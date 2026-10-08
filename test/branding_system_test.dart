import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/branding/branding.dart';
import 'package:genfit/core/theme/app_theme.dart';

void main() {
  group('GenFit Branding System Tests', () {
    testWidgets(
      'GenfitSymbol renders with CustomPaint and scalable dimensions',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: GenfitSymbol(size: 64.0))),
          ),
        );
        await tester.pumpAndSettle();

        final symbolFinder = find.byType(GenfitSymbol);
        expect(symbolFinder, findsOneWidget);

        final customPaintFinder = find.descendant(
          of: symbolFinder,
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);

        final renderBox = tester.renderObject(symbolFinder) as RenderBox;
        expect(renderBox.size.width, 64.0);
        expect(renderBox.size.height, 64.0);
      },
    );

    testWidgets('GenfitSymbol renders in monochrome mode without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GenfitSymbol(
                size: 48.0,
                color: Colors.white,
                isMonochrome: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GenfitSymbol), findsOneWidget);
    });

    testWidgets('GenfitWordmark enforces exact "GenFit" capitalization', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: GenfitWordmark(fontSize: 28.0))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GenFit'), findsOneWidget);
      expect(find.text('GENFIT'), findsNothing);
      expect(find.text('Genfit'), findsNothing);
      expect(find.text('genfit'), findsNothing);
    });

    testWidgets('GenfitLogo renders horizontal lockup correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: GenfitLogo.horizontal())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GenfitLogo), findsOneWidget);
      expect(find.byType(GenfitSymbol), findsOneWidget);
      expect(find.text('GenFit'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('GenfitLogo renders vertical lockup with official tagline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: GenfitLogo.vertical())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GenfitLogo), findsOneWidget);
      expect(find.byType(GenfitSymbol), findsOneWidget);
      expect(find.text('GenFit'), findsOneWidget);
      expect(
        find.text('Smarter Fitness. Local Fuel. Stronger Campus.'),
        findsOneWidget,
      );
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('GenfitAppIcon renders without wordmark text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: GenfitAppIcon(size: 80.0))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GenfitAppIcon), findsOneWidget);
      expect(find.byType(GenfitSymbol), findsOneWidget);
      // App icon must NOT contain wordmark
      expect(find.text('GenFit'), findsNothing);
    });

    testWidgets('GenfitSplashView plays entrance animation and finishes', (
      WidgetTester tester,
    ) async {
      bool isFinished = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: GenfitSplashView(
            onFinished: () {
              isFinished = true;
            },
          ),
        ),
      );

      // Verify initial frame
      expect(find.byType(GenfitSplashView), findsOneWidget);
      expect(find.byType(GenfitSymbol), findsOneWidget);
      expect(find.text('GenFit'), findsOneWidget);
      expect(
        find.text('Smarter Fitness. Local Fuel. Stronger Campus.'),
        findsOneWidget,
      );

      // Advance through animation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(isFinished, isTrue);
    });
  });
}
