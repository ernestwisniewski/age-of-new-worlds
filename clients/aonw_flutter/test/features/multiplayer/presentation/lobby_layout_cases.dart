part of 'multiplayer_screen_test.dart';

void lobbyLayoutCases() {
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 640), const Size(844, 390)]) {
      testWidgets('waiting room at 200% $language $size', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final coordinator = MultiplayerCoordinator(
          session: _Session(),
          documents: _Documents(),
        );
        final controller = MultiplayerController(coordinator);
        addTearDown(controller.dispose);
        await controller.initialize();
        await coordinator.createMatch();
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: Locale(language),
            theme: AonwTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: MultiplayerScreen(controller: controller),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final key in [
          'multiplayer-ready',
          'multiplayer-start-match',
          'multiplayer-leave-lobby',
          'multiplayer-refresh-lobby',
          'multiplayer-close-waiting-room',
        ]) {
          final action = find.byKey(ValueKey(key));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        _expectLobbyTextReadable(tester);
        final ready = find.byKey(const ValueKey('multiplayer-ready'));
        await tester.ensureVisible(ready);
        await tester.pumpAndSettle();
        await tester.tap(ready);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final start = find.byKey(const ValueKey('multiplayer-start-match'));
        expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}

void _expectLobbyTextReadable(WidgetTester tester) {
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.descendant(
      of: find.byType(SafeArea).last,
      matching: find.byType(RichText),
    ),
  )) {
    final text = paragraph.text.toPlainText();
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
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

void onlineSetupLayoutCases() {
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 640), const Size(844, 390)]) {
      testWidgets('online setup at 200% $language $size', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final coordinator = MultiplayerCoordinator(
          session: _Session(),
          documents: _Documents(),
        );
        final controller = MultiplayerController(coordinator);
        addTearDown(controller.dispose);
        await controller.initialize();
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: Locale(language),
            theme: AonwTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: MultiplayerScreen(controller: controller),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final key in [
          'multiplayer-fog-of-war',
          'multiplayer-create-match',
          'multiplayer-match-id',
          'multiplayer-join-match',
        ]) {
          final action = find.byKey(ValueKey(key));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}
