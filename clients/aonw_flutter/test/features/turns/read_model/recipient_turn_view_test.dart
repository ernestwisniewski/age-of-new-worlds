import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('end-turn presentation gate uses only recipient-safe fields', () {
    expect(_turn().canEndTurn, isTrue);
    expect(
      _turn(ownState: RecipientTurnStateView.finished).canEndTurn,
      isFalse,
    );
    expect(_turn(ownSubmitted: true).canEndTurn, isFalse);
    expect(
      _turn(pendingAction: const PendingResearchSelectionView()).canEndTurn,
      isFalse,
    );
    expect(
      _turn(outcome: GameOutcomeConditionView.conquest).canEndTurn,
      isFalse,
    );
  });
}

RecipientTurnView _turn({
  RecipientTurnStateView? ownState = RecipientTurnStateView.active,
  bool ownSubmitted = false,
  PendingActionView? pendingAction,
  GameOutcomeConditionView outcome = GameOutcomeConditionView.ongoing,
}) => RecipientTurnView(
  number: 1,
  ownState: ownState,
  ownSubmitted: ownSubmitted,
  requiredSubmissionCount: 1,
  submittedCount: ownSubmitted ? 1 : 0,
  pendingAction: pendingAction,
  outcome: GameOutcomeView(
    condition: outcome,
    winnerPlayerId: null,
    scoreByPlayerId: const {},
  ),
);
