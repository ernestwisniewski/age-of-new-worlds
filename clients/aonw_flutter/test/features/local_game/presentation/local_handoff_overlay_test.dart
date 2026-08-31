import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/local_game/presentation/local_handoff_overlay.dart';
import 'package:flutter/material.dart';
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
