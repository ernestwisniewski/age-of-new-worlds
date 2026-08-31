import '../../map/read_model/pending_action_view.dart';

enum RecipientTurnStateView { active, finished }

enum GameOutcomeConditionView {
  ongoing,
  conquest,
  domination,
  cultural,
  score,
  resignation,
  draw,
}

final class GameOutcomeView {
  GameOutcomeView({
    required this.condition,
    required this.winnerPlayerId,
    required Map<String, int> scoreByPlayerId,
  }) : scoreByPlayerId = Map.unmodifiable(scoreByPlayerId);

  final GameOutcomeConditionView condition;
  final String? winnerPlayerId;
  final Map<String, int> scoreByPlayerId;

  bool get isTerminal => condition != GameOutcomeConditionView.ongoing;
}

final class RecipientTurnView {
  const RecipientTurnView({
    required this.number,
    required this.ownState,
    required this.ownSubmitted,
    required this.requiredSubmissionCount,
    required this.submittedCount,
    required this.pendingAction,
    required this.outcome,
  });

  final int number;
  final RecipientTurnStateView? ownState;
  final bool ownSubmitted;
  final int requiredSubmissionCount;
  final int submittedCount;
  final PendingActionView? pendingAction;
  final GameOutcomeView outcome;

  bool get canEndTurn =>
      !outcome.isTerminal &&
      pendingAction == null &&
      ownState == RecipientTurnStateView.active &&
      !ownSubmitted;
}
