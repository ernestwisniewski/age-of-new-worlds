import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/read_model/pending_action_view.dart';
import '../read_model/research_view.dart';
import 'research_session_port.dart';
import 'research_state.dart';

typedef ResearchStateReader = GameSessionState Function();
typedef ResearchStatePublisher = void Function(GameSessionReady value);
typedef ResearchDisposed = bool Function();
typedef ResearchDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class ResearchWorkflow {
  ResearchWorkflow({
    required ResearchSessionPort session,
    required ResearchDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final ResearchSessionPort _session;
  final ResearchDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void load({
    required ResearchStateReader readState,
    required ResearchStatePublisher publish,
    required ResearchDisposed isDisposed,
  }) => unawaited(
    _load(readState: readState, publish: publish, isDisposed: isDisposed),
  );

  void select({
    required TechnologyIdView technology,
    required ResearchStateReader readState,
    required ResearchStatePublisher publish,
    required ResearchDisposed isDisposed,
  }) => unawaited(
    _command(
      technology: technology,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  void cancelSelection({
    required ResearchStateReader readState,
    required ResearchStatePublisher publish,
    required ResearchDisposed isDisposed,
  }) => unawaited(
    _command(
      technology: null,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  Future<void> _load({
    required ResearchStateReader readState,
    required ResearchStatePublisher publish,
    required ResearchDisposed isDisposed,
  }) async {
    final current = readState();
    if (current is! GameSessionReady || !_canLoadResearch(current)) {
      return;
    }
    final revision = current.recipient.stamp.revision;
    try {
      final options = await _session.researchOptions(
        expectedRevision: revision,
      );
      if (isDisposed()) return;
      final ready = readState();
      if (ready is! GameSessionReady ||
          !ready.research.loading ||
          ready.research.requestedRevision != revision ||
          ready.recipient.stamp.revision != revision) {
        return;
      }
      publish(
        ready.withResearch(
          ResearchState(requestedRevision: revision, options: options),
        ),
      );
    } on ResearchSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = readState();
      if (ready is GameSessionReady &&
          ready.research.loading &&
          ready.research.requestedRevision == revision) {
        publish(_sessionFailure(ready, error));
      }
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_research_failure', error, stackTrace);
      final ready = readState();
      if (ready is GameSessionReady &&
          ready.research.loading &&
          ready.research.requestedRevision == revision) {
        publish(
          ready.withResearch(
            ResearchState(
              requestedRevision: revision,
              failure: const ResearchFailureView(
                ResearchFailureCode.requestFailed,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _command({
    required TechnologyIdView? technology,
    required ResearchStateReader readState,
    required ResearchStatePublisher publish,
    required ResearchDisposed isDisposed,
  }) async {
    final current = _commandState(readState(), technology);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(
      current.withResearch(
        current.research.copyWith(
          loading: false,
          correlationId: correlationId,
          cancellingSelection: technology == null,
          inFlightTechnology: technology,
          clearFailure: true,
        ),
      ),
    );
    try {
      final revision = current.recipient.stamp.revision;
      final result = await _dispatch(revision, technology);
      if (isDisposed()) return;
      final ready = _correlated(readState(), correlationId);
      if (ready == null) return;
      publish(_afterCommand(ready, result, cancelled: technology == null));
    } on ResearchSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _correlated(readState(), correlationId);
      if (ready != null) publish(_sessionFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_research_failure', error, stackTrace);
      final ready = _correlated(readState(), correlationId);
      if (ready != null) {
        publish(
          ready.withResearch(
            ready.research.copyWith(
              clearInFlightTechnology: true,
              cancellingSelection: false,
              failure: const ResearchFailureView(
                ResearchFailureCode.requestFailed,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<ResearchCommandResultView> _dispatch(
    int revision,
    TechnologyIdView? technology,
  ) => technology == null
      ? _session.cancelResearchSelection(expectedRevision: revision)
      : _session.selectTechnology(
          expectedRevision: revision,
          technology: technology,
        );

  void _report(ResearchSessionException error, StackTrace stackTrace) {
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

bool _canLoadResearch(GameSessionReady current) =>
    !current.localAiTurn.inFlight &&
    current.research.loading &&
    current.research.requestedRevision == current.recipient.stamp.revision;

GameSessionReady? _cancellable(GameSessionState state) =>
    state is GameSessionReady &&
        state.recipient.pendingAction is PendingResearchSelectionView &&
        !state.research.commandPending &&
        !state.diplomacy.commandPending &&
        !state.turnAction.inFlight &&
        !_interactionCommandPending(state)
    ? state
    : null;

GameSessionReady? _selectable(
  GameSessionState state,
  TechnologyIdView technology,
) {
  if (state is! GameSessionReady ||
      state.research.loading ||
      state.research.commandPending ||
      state.diplomacy.commandPending ||
      state.turnAction.inFlight ||
      _interactionCommandPending(state)) {
    return null;
  }
  final options = state.research.options;
  if (options == null ||
      options.stamp.revision != state.recipient.stamp.revision ||
      !options.options.any(
        (option) =>
            option.technology == technology &&
            option.availability == TechnologyAvailabilityView.available,
      )) {
    return null;
  }
  return state;
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
        state.research.correlationId == correlationId &&
        state.research.commandPending
    ? state
    : null;

GameSessionReady _sessionFailure(
  GameSessionReady current,
  ResearchSessionException error,
) {
  final synchronized = error.resyncedPlayer == null
      ? current
      : current.withRecipient(error.resyncedPlayer!);
  return synchronized.withResearch(
    ResearchState(
      requestedRevision: synchronized.recipient.stamp.revision,
      failure: ResearchFailureView(_failureCode(error.code)),
    ),
  );
}

ResearchFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' => ResearchFailureCode.responseIncompatible,
  'session_not_open' => ResearchFailureCode.sessionUnavailable,
  _ => ResearchFailureCode.requestFailed,
};

GameSessionReady _afterCommand(
  GameSessionReady ready,
  ResearchCommandResultView result, {
  required bool cancelled,
}) {
  final finished = ready.withResearch(
    ready.research.copyWith(
      clearInFlightTechnology: true,
      cancellingSelection: false,
      failure: result.accepted
          ? null
          : ResearchFailureView.rejected(result.rejectionCode!),
    ),
  );
  if (!result.accepted) return finished;
  final updated = finished.withRecipient(result.player!);
  return cancelled
      ? updated.withInteraction(
          updated.interaction.copyWith(researchFocused: false),
        )
      : updated;
}

GameSessionReady? _commandState(
  GameSessionState state,
  TechnologyIdView? technology,
) => technology == null ? _cancellable(state) : _selectable(state, technology);
