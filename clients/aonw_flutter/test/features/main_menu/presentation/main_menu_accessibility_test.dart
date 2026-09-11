import 'package:aonw_flutter/features/main_menu/presentation/main_menu_screen.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 640), const Size(844, 390)]) {
      testWidgets(
        'menu retains full notice and actions at 200% $language $size',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final calls = <String>[];
          await tester.pumpWidget(
            LocalizedTestApp(
              locale: Locale(language),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: MainMenuScreen(
                  serverUpdateRequired: true,
                  onOpenSinglePlayer: () => calls.add('single-player'),
                  onOpenMultiplayer: () => calls.add('multiplayer'),
                  onOpenHotseat: () => calls.add('hotseat'),
                  onOpenLoadGame: () => calls.add('load-game'),
                  onOpenSettings: () => calls.add('menu-settings'),
                  onOpenInstructions: () => calls.add('menu-help'),
                  onOpenCredits: () => calls.add('menu-credits'),
                  onOpenFeedback: () => calls.add('menu-feedback'),
                  onExit: () async => calls.add('exit-game'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = tester.element(find.byType(MainMenuScreen)).aonwL10n;
          final notice = find.text(l10n.serverUpdateSoon);
          expect(notice, findsOneWidget);
          await tester.ensureVisible(notice);
          await tester.pumpAndSettle();
          for (final paragraph in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: notice, matching: find.byType(RichText)),
          )) {
            expect(paragraph.didExceedMaxLines, isFalse);
          }
          for (final key in [
            'single-player',
            'multiplayer',
            'hotseat',
            'load-game',
            'menu-settings',
            'exit-game',
            'menu-help',
            'menu-credits',
            'menu-feedback',
          ]) {
            final action = find.byKey(ValueKey(key));
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            for (final paragraph in tester.renderObjectList<RenderParagraph>(
              find.descendant(of: action, matching: find.byType(RichText)),
            )) {
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: '$key text must remain readable',
              );
            }
            expect(action.hitTestable(), findsOneWidget);
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(calls.last, key);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
