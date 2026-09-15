import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/local_game/presentation/local_handoff_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('requires the named player to reveal a handed-off view', (
    tester,
  ) async {
    var confirmations = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: LocalHandoffOverlay(
            state: const LocalHandoffState.awaitingConfirmation(
              playerId: 'player-2',
              playerName: 'Player 2',
            ),
            onConfirm: () => confirmations += 1,
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('local-handoff-overlay')),
        matching: find.byType(ModalBarrier),
      ),
      findsOneWidget,
    );
    expect(find.text('Pass the device'), findsOneWidget);
    expect(find.text('Continue as Player 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-local-handoff')));
    expect(confirmations, 1);
  });

  testWidgets('keyboard confirmation is focused and Escape cannot reveal', (
    tester,
  ) async {
    var confirmations = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: LocalHandoffOverlay(
            state: const LocalHandoffState.awaitingConfirmation(
              playerId: 'player-2',
              playerName: 'Player 2',
            ),
            onConfirm: () => confirmations++,
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(confirmations, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(confirmations, 1);
  });

  for (final locale in ['pl', 'en', 'fr', 'de', 'es', 'nl']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('$locale handoff remains usable at 200% in $size', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var confirmations = 0;
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: Locale(locale),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: LocalHandoffOverlay(
                  state: const LocalHandoffState.awaitingConfirmation(
                    playerId: 'player-2',
                    playerName: 'Aleksandra 👩🏽‍🚀',
                  ),
                  onConfirm: () => confirmations++,
                  onRetry: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final action = find.byKey(const ValueKey('confirm-local-handoff'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        expect(confirmations, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('offers retry without revealing a failed handoff', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: LocalHandoffOverlay(
            state: const LocalHandoffState.failed(
              playerId: 'player-2',
              playerName: 'Player 2',
            ),
            onConfirm: () {},
            onRetry: () => retries += 1,
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('local-handoff-overlay')),
        matching: find.byType(ModalBarrier),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('retry-local-handoff')));
    expect(retries, 1);
  });
}
