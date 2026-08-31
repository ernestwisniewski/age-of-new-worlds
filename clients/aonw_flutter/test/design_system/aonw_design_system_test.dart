import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/design_system/aonw_tokens.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_panel.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('base actions keep an accessible interactive size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AonwTheme.dark,
        home: Scaffold(
          body: Row(
            children: [
              IconButton(
                key: const ValueKey('icon-action'),
                onPressed: () {},
                icon: const Icon(Icons.layers),
              ),
              FilledButton(
                key: const ValueKey('filled-action'),
                onPressed: () {},
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );

    for (final key in ['icon-action', 'filled-action']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(AonwSizes.minimumInteractive));
      expect(size.height, greaterThanOrEqualTo(AonwSizes.minimumInteractive));
    }
  });

  testWidgets('status components expose labels and their action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AonwTheme.dark,
        home: Scaffold(
          body: Column(
            children: [
              const AonwProgressIndicator(semanticLabel: 'Loading campaign'),
              AonwMessagePanel(
                semanticLabel: 'Campaign loading failed',
                title: 'Campaign unavailable',
                message: 'Try again.',
                actionLabel: 'Retry',
                onAction: () => retried = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Loading campaign'), findsOneWidget);
    expect(find.bySemanticsLabel('Campaign loading failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
    semantics.dispose();
  });

  testWidgets('compact progress uses the shared size token', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AonwProgressIndicator(
            semanticLabel: 'Applying command',
            compact: true,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(AonwProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      ),
      const Size.square(AonwSizes.compactProgress),
    );
  });
}
