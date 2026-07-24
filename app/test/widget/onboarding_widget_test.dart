import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/core/design/theme.dart';
import 'package:nutriguide_ai/features/legal/consent.dart';
import 'package:nutriguide_ai/features/onboarding/presentation/onboarding_screen.dart';

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: brightness == Brightness.dark ? NGTheme.dark() : NGTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    ),
  );
}

void main() {
  group('Onboarding', () {
    testWidgets('shows the product disclaimer on the welcome step', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen()));
      await tester.pumpAndSettle();
      // The required product statement must appear during onboarding.
      expect(
        find.textContaining('does not diagnose, treat, cure'),
        findsWidgets,
      );
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets(
      'cannot continue past "About you" without name + age 18 check',
      (tester) async {
        await tester.pumpWidget(_wrap(const OnboardingScreen()));
        await tester.pumpAndSettle();
        // Step 1 (welcome) → Continue is enabled.
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        // Now on "About you"; Continue should be disabled until name + adult.
        final continueButton = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Continue'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(continueButton.onPressed, isNull);
      },
    );

    testWidgets('enables continue after name and 18+ confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Rey');
      await tester.tap(find.text(Consent.adultConfirmation));
      await tester.pumpAndSettle();

      final continueButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continue'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(continueButton.onPressed, isNotNull);
    });

    testWidgets('renders in dark mode without overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(const OnboardingScreen(), brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives large text scaling', (tester) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen(), textScale: 1.6));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
