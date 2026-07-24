import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/core/design/components.dart';
import 'package:nutriguide_ai/core/design/theme.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? NGTheme.dark() : NGTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('EmptyState renders title, message and optional action', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: Icons.info,
          title: 'Nothing here',
          message: 'Add something',
          actionLabel: 'Add',
          onAction: () => tapped = true,
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add something'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('ErrorState offers retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(ErrorState(message: 'Boom', onRetry: () => retried = true)),
    );
    expect(find.textContaining('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('NoticeBanner shows severity content and dismiss', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      _wrap(
        NoticeBanner(
          severity: NoticeSeverity.danger,
          title: 'Careful',
          message: 'Danger here',
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    expect(find.text('Careful'), findsOneWidget);
    expect(find.text('Danger here'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss'));
    expect(dismissed, isTrue);
  });

  testWidgets('MacroBar exposes an accessible semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        const MacroBar(
          label: 'Protein',
          consumed: 80,
          target: 120,
          unit: 'g',
          color: Colors.blue,
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Protein 80 of 120 g')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('ConfidenceChip renders each evidence level', (tester) async {
    for (final level in ['established', 'general', 'individual', 'uncertain']) {
      await tester.pumpWidget(_wrap(ConfidenceChip(level: level)));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('components render in dark mode', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const NoticeBanner(message: 'Dark test'),
        brightness: Brightness.dark,
      ),
    );
    expect(find.text('Dark test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
