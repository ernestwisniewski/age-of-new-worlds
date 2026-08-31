import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/artifact_view.dart';
import 'artifact_session_port.dart';
import 'artifact_state.dart';

typedef ArtifactStateReader = GameSessionState Function();
typedef ArtifactStatePublisher = void Function(GameSessionReady value);
typedef ArtifactDisposed = bool Function();
typedef ArtifactSelectionRefresher = void Function();
typedef ArtifactDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class ArtifactWorkflow {
  ArtifactWorkflow({
    required ArtifactSessionPort session,
    required ArtifactDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final ArtifactSessionPort _session;
  final ArtifactDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void execute({
    required ArtifactActionView action,
    required ArtifactStateReader readState,
    required ArtifactStatePublisher publish,
    required ArtifactDisposed isDisposed,
    required ArtifactSelectionRefresher refreshSelection,
  }) => unawaited(
    _execute(
      action: action,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
      refreshSelection: refreshSelection,
    ),
  );

  Future<void> _execute({
    required ArtifactActionView action,
    required ArtifactStateReader readState,
    required ArtifactStatePublisher publish,
    required ArtifactDisposed isDisposed,
    required ArtifactSelectionRefresher refreshSelection,
  }) async {
    final current = _executable(readState(), action);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(
      current.withInteraction(
        current.interaction.copyWith(
          artifact: current.interaction.artifact!.copyWith(
            correlationId: correlationId,
            inFlightAction: action,
            clearFailure: true,
          ),
        ),
      ),
    );
    try {
      final result = await _session.executeArtifactAction(
        expectedRevision: current.recipient.stamp.revision,
        action: action,
      );
      if (isDisposed()) return;
      final ready = _correlated(readState(), correlationId);
      if (ready == null) return;
      if (!result.accepted) {
        publish(_rejected(ready, result.rejectionCode!));
        return;
      }
      publish(_accepted(ready, result.player!));
      refreshSelection();
    } on ArtifactSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _correlated(readState(), correlationId);
      if (ready != null) publish(_sessionFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_artifact_failure', error, stackTrace);
      final ready = _correlated(readState(), correlationId);
      if (ready != null) publish(_unexpectedFailure(ready));
    }
  }

  void _report(ArtifactSessionException error, StackTrace stackTrace) {
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
  ArtifactActionView action,
) {
  if (state is! GameSessionReady ||
      state.research.commandPending ||
      state.diplomacy.commandPending ||
      state.interaction.artifact == null ||
      state.interaction.artifact!.commandPending ||
      state.interaction.movementPending ||
      (state.interaction.combat?.loading ?? false) ||
      (state.interaction.combat?.commandPending ?? false) ||
      (state.interaction.city?.loading ?? false) ||
      (state.interaction.city?.commandPending ?? false) ||
      (state.interaction.unitLogistics?.commandPending ?? false) ||
      (state.interaction.worker?.loading ?? false) ||
      (state.interaction.worker?.commandPending ?? false) ||
      (state.interaction.production?.loading ?? false) ||
      (state.interaction.production?.commandPending ?? false) ||
      state.interaction.selected == null ||
      !_matchesSelection(state, action)) {
    return null;
  }
  return state;
}

bool _matchesSelection(GameSessionReady state, ArtifactActionView action) {
  final player = state.recipient;
  final selected = state.interaction.selected!;
  return switch (action) {
    StartArtifactExcavationActionView(:final unitId) =>
      state.interaction.selectedUnitId == unitId &&
          player.controlledUnitById(unitId)?.coordinate == selected &&
          player
              .artifactsAt(selected)
              .any((artifact) => artifact.location is MapArtifactLocationView),
    StoreArtifactInCityActionView(:final unitId, :final cityId) =>
      state.interaction.selectedUnitId == unitId &&
          player.controlledUnitById(unitId)?.carriedArtifactId != null &&
          (cityId == null ||
              player.controlledCityById(cityId)?.center == selected),
    TradeArtifactActionView(
      :final targetPlayerId,
      :final offeredArtifactId,
      :final offeredGold,
    ) =>
      offeredGold >= 0 &&
          player.diplomaticCounterpartPlayerIds.contains(targetPlayerId) &&
          _isControlledStoredArtifactSelected(
            player,
            offeredArtifactId,
            selected,
          ),
  };
}

bool _isControlledStoredArtifactSelected(
  PlayerMapView player,
  String artifactId,
  MapHexCoordinate selected,
) {
  final location = player.artifactById(artifactId)?.location;
  return location is StoredArtifactLocationView &&
      player.controlledCityById(location.cityId)?.center == selected;
}

GameSessionReady? _correlated(GameSessionState state, int correlationId) =>
    state is GameSessionReady &&
        state.interaction.artifact?.correlationId == correlationId
    ? state
    : null;

GameSessionReady _rejected(
  GameSessionReady current,
  ArtifactRejectionCodeView code,
) => current.withInteraction(
  current.interaction.copyWith(
    artifact: current.interaction.artifact!.copyWith(
      clearInFlightAction: true,
      failure: ArtifactFailureView.rejected(code),
    ),
  ),
);

GameSessionReady _accepted(GameSessionReady current, PlayerMapView player) {
  final synchronized = current.withRecipient(player);
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(artifact: const ArtifactState()),
  );
}

GameSessionReady _sessionFailure(
  GameSessionReady current,
  ArtifactSessionException error,
) {
  final synchronized = error.resyncedPlayer == null
      ? current
      : current.withRecipient(error.resyncedPlayer!);
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      artifact: synchronized.interaction.artifact!.copyWith(
        clearInFlightAction: true,
        failure: ArtifactFailureView(_failureCode(error.code)),
      ),
    ),
  );
}

GameSessionReady _unexpectedFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        artifact: current.interaction.artifact!.copyWith(
          clearInFlightAction: true,
          failure: const ArtifactFailureView(ArtifactFailureCode.requestFailed),
        ),
      ),
    );

ArtifactFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' => ArtifactFailureCode.responseIncompatible,
  'session_not_open' => ArtifactFailureCode.sessionUnavailable,
  _ => ArtifactFailureCode.requestFailed,
};
