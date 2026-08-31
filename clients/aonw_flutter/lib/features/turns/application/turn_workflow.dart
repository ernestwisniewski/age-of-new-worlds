import 'dart:async';

import '../../map/application/game_session_state.dart';
import 'turn_action_state.dart';
import 'turn_command_runner.dart';
import 'turn_session_port.dart';

typedef GameSessionStateReader = GameSessionState Function();
typedef GameSessionReadyPublisher = void Function(GameSessionReady state);
typedef TurnWorkflowDisposed = bool Function();
typedef TurnAcceptedCallback = Future<void> Function(GameSessionReady state);

final class TurnWorkflow {
  TurnWorkflow({
    required TurnSessionPort session,
    required TurnDiagnosticReporter diagnosticReporter,
  }) : _runner = TurnCommandRunner(
         session: session,
         diagnosticReporter: diagnosticReporter,
       );

  final TurnCommandRunner _runner;
  var _correlationId = 0;

  void endTurn({
    required GameSessionStateReader readState,
    required GameSessionReadyPublisher publish,
    required TurnWorkflowDisposed isDisposed,
    TurnAcceptedCallback? onAccepted,
  }) {
    unawaited(
      _execute(
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
        onAccepted: onAccepted,
      ),
    );
  }

  Future<void> _execute({
    required GameSessionStateReader readState,
    required GameSessionReadyPublisher publish,
    required TurnWorkflowDisposed isDisposed,
    required TurnAcceptedCallback? onAccepted,
  }) async {
    final current = readState();
    if (current is! GameSessionReady ||
        current.research.commandPending ||
        current.diplomacy.commandPending ||
        current.turnAction.inFlight ||
        (current.interaction.combat?.commandPending ?? false) ||
        (current.interaction.combat?.loading ?? false) ||
        !current.recipient.turnView.canEndTurn) {
      return;
    }
    final correlationId = ++_correlationId;
    publish(_pending(current, correlationId));
    final completion = await _runner.endTurn(
      expectedRevision: current.recipient.stamp.revision,
    );
    if (isDisposed()) return;
    final ready = readState();
    if (ready is! GameSessionReady ||
        ready.turnAction.correlationId != correlationId) {
      return;
    }
    final reduced = _reduceCompletion(ready, completion);
    publish(reduced);
    if (completion.failure == null &&
        completion.result?.accepted == true &&
        onAccepted != null) {
      await onAccepted(reduced);
    }
  }
}

GameSessionReady _pending(GameSessionReady current, int correlationId) =>
    current.withTurnAction(
      current.turnAction.copyWith(
        correlationId: correlationId,
        inFlight: true,
        clearFailure: true,
      ),
    );

GameSessionReady _reduceCompletion(
  GameSessionReady current,
  TurnCommandCompletion completion,
) {
  final resynced = completion.resyncedPlayer;
  final synchronized = resynced == null
      ? current
      : current.withRecipient(resynced);
  final failure = completion.failure;
  if (failure != null) return _failed(synchronized, failure);
  final result = completion.result!;
  if (!result.accepted) {
    return _failed(
      synchronized,
      TurnActionFailureView.rejected(result.rejectionCode!),
    );
  }
  final updated = synchronized.withRecipient(result.player!);
  return updated
      .withTurnPresentations(
        updated.turnPresentations.observeActivities(result.activities),
      )
      .withTurnAction(
        updated.turnAction.copyWith(inFlight: false, clearFailure: true),
      );
}

GameSessionReady _failed(
  GameSessionReady current,
  TurnActionFailureView failure,
) => current.withTurnAction(
  current.turnAction.copyWith(inFlight: false, failure: failure),
);
