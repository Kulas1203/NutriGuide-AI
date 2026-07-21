import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/coach/presentation/coach_screen.dart';
import 'package:nutriguide_ai/features/logging/presentation/food_search_sheet.dart';
import 'package:nutriguide_ai/features/planner/domain/recipe.dart';

import 'harness.dart';

/// The in-memory harness resolves all repository loads on the microtask
/// queue. We use bounded pumps rather than pumpAndSettle because focused text
/// fields keep a blinking-cursor timer alive, which pumpAndSettle would wait
/// on indefinitely.
Future<void> _settleAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
  await tester.pump(const Duration(milliseconds: 60));
}

void main() {
  group('AI Coach', () {
    testWidgets('shows the AI disclaimer before the first conversation', (
      tester,
    ) async {
      await tester.pumpWidget(
        await buildTestApp(const CoachScreen(), seedProfile: testProfile()),
      );
      await _settleAsync(tester);
      // Disclaimer must appear before the first AI conversation.
      expect(find.textContaining('not a doctor'), findsWidgets);
      // Dev-stub builds must be clearly labeled.
      expect(find.textContaining('Development stub'), findsWidgets);
    });

    testWidgets('emergency input is blocked before reaching the model', (
      tester,
    ) async {
      await tester.pumpWidget(
        await buildTestApp(const CoachScreen(), seedProfile: testProfile()),
      );
      await _settleAsync(tester);

      await tester.enterText(
        find.byType(TextField),
        'I have chest pain and feel faint',
      );
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await _settleAsync(tester);

      // The safety layer replies with urgent-care guidance, not a diet answer,
      // and flags a professional referral.
      expect(find.textContaining('emergency'), findsWidgets);
      expect(find.textContaining('See a professional'), findsWidgets);
    });
  });

  group('Food logging', () {
    testWidgets('searches the bundled dataset and shows verified foods', (
      tester,
    ) async {
      await tester.pumpWidget(
        await buildTestApp(
          const Scaffold(body: FoodSearchSheet(slot: MealSlot.lunch)),
          seedProfile: testProfile(),
        ),
      );
      await _settleAsync(tester);

      expect(find.text('Add to Lunch'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'chicken');
      await _settleAsync(tester);
      // Verified USDA foods should surface.
      expect(find.textContaining('Chicken'), findsWidgets);
    });

    testWidgets('quick add and optional scan are available', (tester) async {
      await tester.pumpWidget(
        await buildTestApp(
          const Scaffold(body: FoodSearchSheet(slot: MealSlot.breakfast)),
          seedProfile: testProfile(),
        ),
      );
      await _settleAsync(tester);
      // The diary is usable without camera: manual quick add is present.
      expect(find.text('Quick add'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });
  });
}
