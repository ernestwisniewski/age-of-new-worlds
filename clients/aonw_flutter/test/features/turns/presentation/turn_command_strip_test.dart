import 'package:aonw_flutter/features/local_game/application/local_ai_turn_state.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/application/turn_action_state.dart';
import 'package:aonw_flutter/features/turns/application/turn_presentation_queue.dart';
import 'package:aonw_flutter/features/turns/presentation/turn_hud.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  for (final mode in MatchTurnModeView.values) {
    testWidgets(
      'command describes $mode and keeps aggregate progress beside it',
      (tester) async {
        var calls = 0;
        await tester.pumpWidget(_screen(mode: mode, onEnd: () => calls++));
        await tester.pumpAndSettle();
        expect(
          find.text(
            mode == MatchTurnModeView.simultaneous ? 'Submit turn' : 'End turn',
          ),
          findsOneWidget,
        );
        final action = find.byKey(const ValueKey('end-turn'));
        final progress = find.byKey(const ValueKey('turn-progress'));
        expect(tester.getCenter(progress).dy, tester.getCenter(action).dy);
        expect(tester.getCenter(progress).dy, greaterThan(500));
        await tester.tap(action);
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final ai in [false, true]) {
    testWidgets(
      'waiting ${ai ? 'AI' : 'submission'} does not pulse a pending action',
      (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          _screen(
            mode: MatchTurnModeView.simultaneous,
            onEnd: () => calls++,
            pending: const PendingResearchSelectionView(),
            inFlight: !ai,
            aiTurn: ai
                ? const LocalAiTurnState.running('two')
                : const LocalAiTurnState.idle(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        expect(tester.binding.transientCallbackCount, 0);
        await tester.tap(find.byKey(const ValueKey('end-turn')));
        expect(calls, 0);
        expect(find.text('Submitting turn'), findsOneWidget);
      },
    );
  }
}

Widget _screen({
  required MatchTurnModeView mode,
  required VoidCallback onEnd,
  PendingActionView? pending,
  bool inFlight = false,
  LocalAiTurnState aiTurn = const LocalAiTurnState.idle(),
}) => LocalizedTestApp(
  locale: const Locale('en'),
  home: Scaffold(
    body: TurnPresentationOverlays(
      turn: RecipientTurnView(
        number: 8,
        ownState: RecipientTurnStateView.active,
        ownSubmitted: false,
        requiredSubmissionCount: 3,
        submittedCount: 2,
        pendingAction: pending,
        outcome: GameOutcomeView(
          condition: GameOutcomeConditionView.ongoing,
          winnerPlayerId: null,
          scoreByPlayerId: const {},
        ),
      ),
      turnMode: mode,
      action: TurnActionState(inFlight: inFlight),
      presentations: TurnPresentationQueue.start(8),
      onEndTurn: onEnd,
      localAiTurn: aiTurn,
    ),
  ),
);
