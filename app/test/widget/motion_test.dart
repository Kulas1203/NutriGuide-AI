import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/core/design/motion.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AnimatedCount', () {
    testWidgets('animates toward the target value and appends the suffix',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const AnimatedCount(value: 100, suffix: ' kcal'),
      ));
      // Mid-animation the shown number is below the target.
      await tester.pump(const Duration(milliseconds: 100));
      // After the animation completes it reads the exact target.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('100 kcal'), findsOneWidget);
    });

    testWidgets('reduced motion still ends on the final value', (tester) async {
      await tester.pumpWidget(_wrap(
        const AnimatedCount(value: 42),
        reduceMotion: true,
      ));
      await tester.pump();
      expect(find.text('42'), findsOneWidget);
    });
  });

  group('Entrance', () {
    testWidgets('renders its child fully when reduced motion is on',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const Entrance(child: Text('hello')),
        reduceMotion: true,
      ));
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(Entrance),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('child becomes fully visible after the animation', (tester) async {
      await tester.pumpWidget(_wrap(const Entrance(child: Text('hi'))));
      // First pump fires the (zero) stagger delay and starts the controller;
      // the second advances it past its 320ms duration to completion.
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('hi'), findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(Entrance),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, closeTo(1.0, 0.001));
    });
  });

  group('PressableScale', () {
    testWidgets('passes taps through to the child', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        PressableScale(
          child: ElevatedButton(
            onPressed: () => tapped = true,
            child: const Text('tap'),
          ),
        ),
      ));
      await tester.tap(find.text('tap'));
      expect(tapped, isTrue);
    });

    testWidgets('reduced motion bypasses the scale wrapper', (tester) async {
      await tester.pumpWidget(_wrap(
        const PressableScale(child: Text('x')),
        reduceMotion: true,
      ));
      expect(find.byType(AnimatedScale), findsNothing);
      expect(find.text('x'), findsOneWidget);
    });
  });
}
