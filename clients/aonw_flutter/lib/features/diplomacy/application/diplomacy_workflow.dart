import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../read_model/diplomacy_view.dart';
import 'diplomacy_session_port.dart';
import 'diplomacy_state.dart';

typedef DiplomacyStateReader = GameSessionState Function();
typedef DiplomacyStatePublisher = void Function(GameSessionReady value);
typedef DiplomacyDisposed = bool Function();
typedef DiplomacyDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class DiplomacyWorkflow {
  DiplomacyWorkflow({
    required DiplomacySessionPort session,
    required DiplomacyDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final DiplomacySessionPort _session;
  final DiplomacyDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void execute({
    required DiplomacyActionView action,
    required DiplomacyStateReader readState,
    required DiplomacyStatePublisher publish,
    required DiplomacyDisposed isDisposed,
  }) => unawaited(
    _execute(
      action: action,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  Future<void> _execute({
    required DiplomacyActionView action,
    required DiplomacyStateReader readState,
    required DiplomacyStatePublisher publish,
    required DiplomacyDisposed isDisposed,
  }) async {
    final current = _executable(readState(), action);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(
      current.withDiplomacy(
        current.diplomacy.copyWith(
          correlationId: correlationId,
          inFlightAction: action,
          clearFailure: true,
        ),
      ),
    );
    try {
      final result = await _session.executeDiplomacyAction(
        expectedRevision: current.recipient.stamp.revision,
        action: action,
      );
      if (isDisposed()) return;
      final ready = _correlated(readState(), correlationId);
      if (ready == null) return;
      if (!result.accepted) {
        publish(
          ready.withDiplomacy(
            ready.diplomacy.copyWith(
              clearInFlightAction: true,
              failure: DiplomacyFailureView.rejected(result.rejectionCode!),
            ),
          ),
        );
        return;
      }
      publish(ready.withRecipient(result.player!));
    } on DiplomacySessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _correlated(readState(), correlationId);
      if (ready != null) publish(_sessionFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_diplomacy_failure', error, stackTrace);
      final ready = _correlated(readState(), correlationId);
      if (ready != null) {
        publish(
          ready.withDiplomacy(
            ready.diplomacy.copyWith(
              clearInFlightAction: true,
              failure: const DiplomacyFailureView(
                DiplomacyFailureCode.requestFailed,
              ),
            ),
          ),
        );
      }
    }
  }

  void _report(DiplomacySessionException error, StackTrace stackTrace) {
    final cause = error.diagnosticCause;
    if (cause != null) {
      _diagnosticReporter(
        error.code,
        cause,
        error.diagnosticStackTrace ?? stackTrace,
      );
    }
  }
}

GameSessionReady? _executable(
  GameSessionState state,
  DiplomacyActionView action,
) {
  if (state is! GameSessionReady ||
      state.diplomacy.commandPending ||
      state.research.commandPending ||
      state.turnAction.inFlight ||
      _interactionCommandPending(state)) {
    return null;
  }
  final view = state.recipient.diplomacy;
  final actor = state.recipient.actorPlayerId;
  final valid = switch (action) {
    DeclareWarActionView(:final targetPlayerId) ||
    SendGoldGiftActionView(:final targetPlayerId) ||
    OpenResourceTradeActionView(:final targetPlayerId) ||
    OpenResourceExchangeActionView(:final targetPlayerId) ||
    SendDiplomaticProposalActionView(:final targetPlayerId) ||
    SendDiplomaticMessageActionView(
      :final targetPlayerId,
    ) => view.relationWith(targetPlayerId) != null,
    RespondDiplomaticProposalActionView(:final proposalId) =>
      view.proposals.any(
        (proposal) => proposal.id == proposalId && proposal.toPlayerId == actor,
      ),
    RespondDiplomaticMessageActionView(:final messageId) => view.messages.any(
      (message) =>
          message.id == messageId &&
          message.toPlayerId == actor &&
          message.response == null,
    ),
  };
  return valid ? state : null;
}

bool _interactionCommandPending(GameSessionReady state) {
  final interaction = state.interaction;
  return interaction.movementPending ||
      (interaction.combat?.loading ?? false) ||
      (interaction.combat?.commandPending ?? false) ||
      (interaction.city?.loading ?? false) ||
      (interaction.city?.commandPending ?? false) ||
      (interaction.actionDeck?.commandPending ?? false) ||
      (interaction.unitLogistics?.commandPending ?? false) ||
      (interaction.worker?.loading ?? false) ||
      (interaction.worker?.commandPending ?? false) ||
      (interaction.production?.loading ?? false) ||
      (interaction.production?.commandPending ?? false) ||
      (interaction.artifact?.commandPending ?? false);
}

GameSessionReady? _correlated(GameSessionState state, int correlationId) =>
    state is GameSessionReady &&
        state.diplomacy.correlationId == correlationId &&
        state.diplomacy.commandPending
    ? state
    : null;

GameSessionReady _sessionFailure(
  GameSessionReady current,
  DiplomacySessionException error,
) {
  final synchronized = error.resyncedPlayer == null
      ? current
      : current.withRecipient(error.resyncedPlayer!);
  return synchronized.withDiplomacy(
    DiplomacyState(failure: DiplomacyFailureView(_failureCode(error.code))),
  );
}

DiplomacyFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' ||
  'recipient_resynchronized' => DiplomacyFailureCode.responseIncompatible,
  'engine_adapter_unavailable' ||
  'engine_unavailable' ||
  'session_closed' => DiplomacyFailureCode.sessionUnavailable,
  _ => DiplomacyFailureCode.requestFailed,
};
