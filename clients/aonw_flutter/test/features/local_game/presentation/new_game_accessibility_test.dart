import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/local_game/presentation/local_game_launch_mode.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import 'local_game_visual_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLocalGameFonts);
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 640), const Size(844, 390)]) {
      for (final mode in LocalGameLaunchModeView.values) {
        testWidgets(
          'setup and review remain usable at 200% $language $size $mode',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final controller = MapPresentationController(
              capabilities: testGameSessionCapabilities(
                FakeGameSession.success(testMapScene()),
              ),
            );
            addTearDown(controller.dispose);
            await tester.pumpWidget(
              LocalizedTestApp(
                locale: Locale(language),
                theme: AonwTheme.dark,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2),
                  ),
                  child: newGameTestRoute(controller, mode),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            _expectReadable(tester, 'new-game-setup');
            final next = find.byKey(const ValueKey('continue-to-summary'));
            await tester.ensureVisible(next);
            await tester.pumpAndSettle();
            expect(next.hitTestable(), findsOneWidget);
            await tester.tap(next);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const ValueKey('new-game-review')),
              findsOneWidget,
            );
            expect(
              tester
                  .state<ScrollableState>(find.byType(Scrollable).first)
                  .position
                  .pixels,
              0,
              reason:
                  'The review starts at its heading after leaving a scrolled setup.',
            );
            _expectReadable(tester, 'new-game-review');
            final start = find.byKey(const ValueKey('start-game'));
            await tester.ensureVisible(start);
            await tester.pumpAndSettle();
            expect(start.hitTestable(), findsOneWidget);
            final back = find.byKey(const ValueKey('back-to-setup'));
            await tester.ensureVisible(back);
            await tester.pumpAndSettle();
            await tester.tap(back);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('new-game-setup')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }
  }
}

void _expectReadable(WidgetTester tester, String key) {
  final paragraphs = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(RichText),
  );
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    paragraphs,
  )) {
    final text = paragraph.text.toPlainText();
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
    // Trailing line-break spaces may extend beyond the painted text bounds.
    for (final word in RegExp(r'\S+').allMatches(text)) {
      for (final box in paragraph.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      )) {
        expect(
          box.right,
          lessThanOrEqualTo(paragraph.size.width + 0.5),
          reason: text,
        );
      }
    }
  }
}
