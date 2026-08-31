import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/design_system/aonw_tokens.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_hud_surface.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_panel.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HUD tokens preserve the flame_4x visual contract', () {
    expect(AonwColorTokens.background, const Color(0xFF0A0A0E));
    expect(AonwColorTokens.surface, const Color(0xFF101620));
    expect(AonwColorTokens.brand, const Color(0xFFD2A856));
    expect(AonwColorTokens.brandLight, const Color(0xFFF0DCAE));
    expect(AonwTypography.headingFamily, 'Cinzel');
    expect(AonwTypography.bodyFamily, 'Lato');
    expect(AonwRadii.frame, 2);
    expect(AonwRadii.panel, 10);
    expect(AonwRadii.button, 12);
    expect(AonwRadii.pill, 999);
    expect(AonwMotion.snap, const Duration(milliseconds: 120));
    expect(AonwMotion.fade, const Duration(milliseconds: 200));
    expect(AonwMotion.slide, const Duration(milliseconds: 240));
    expect(AonwMotion.scene, const Duration(milliseconds: 350));
  });

  testWidgets('flat HUD surfaces retain exact fill border and shadow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AonwHudSurface(
            elevation: AonwHudElevation.flat,
            child: Text('HUD'),
          ),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(AonwHudSurface),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decorated.decoration as BoxDecoration;
    final border = decoration.border! as Border;
    final shadow = decoration.boxShadow!.single;
    expect(decoration.color, AonwColorTokens.surface.withAlpha(210));
    expect(border.top.color, AonwColorTokens.brand.withAlpha(60));
    expect(decoration.borderRadius, BorderRadius.circular(AonwRadii.panel));
    expect(shadow.color, Colors.black.withAlpha(80));
    expect(shadow.blurRadius, 12);
    expect(shadow.offset, const Offset(0, 4));
  });

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
