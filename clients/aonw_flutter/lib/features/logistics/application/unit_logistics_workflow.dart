import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/application/map_interaction_state.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/unit_logistics_view.dart';
import 'unit_logistics_session_port.dart';
import 'unit_logistics_state.dart';

typedef LogisticsStateReader = GameSessionState Function();
typedef LogisticsStatePublisher = void Function(GameSessionReady value);
typedef LogisticsDisposed = bool Function();
typedef LogisticsDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class UnitLogisticsWorkflow {
  UnitLogisticsWorkflow({
    required UnitLogisticsSessionPort session,
    required LogisticsDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final UnitLogisticsSessionPort _session;
  final LogisticsDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void load({
    required String unitId,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) {
    unawaited(
      _load(
        unitId: unitId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      ),
    );
  }

  void execute({
    required UnitLogisticsActionView action,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) {
    unawaited(
      _execute(
        action: action,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      ),
    );
  }

  Future<void> _load({
    required String unitId,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) async {
    final current = _selected(readState(), unitId);
    if (current == null) return;
    final expectedRevision = current.recipient.stamp.revision;
    try {
      final options = await _session.unitLogisticsOptions(
        expectedRevision: expectedRevision,
        unitId: unitId,
      );
      if (isDisposed()) return;
      final ready = _selectedAtRevision(readState(), unitId, expectedRevision);
      if (ready == null) return;
      publish(
        ready.withInteraction(
          ready.interaction.copyWith(
            unitLogistics: UnitLogisticsState(unitId: unitId, options: options),
          ),
        ),
      );
    } on UnitLogisticsSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _selected(readState(), unitId);
      if (ready != null) publish(_loadFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter(
        'unexpected_unit_logistics_failure',
        error,
        stackTrace,
      );
      final ready = _selected(readState(), unitId);
      if (ready != null) publish(_unexpectedLoadFailure(ready));
    }
  }

  Future<void> _execute({
    required UnitLogisticsActionView action,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) async {
    final current = _executable(readState(), action);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(_pending(current, action, correlationId));
    try {
      final result = await _session.executeUnitLogistics(
        expectedRevision: current.recipient.stamp.revision,
        action: action,
      );
      _handleResult(
        result: result,
        action: action,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on UnitLogisticsSessionException catch (error, stackTrace) {
      _handleSessionFailure(
        error: error,
        stackTrace: stackTrace,
        unitId: action.unitId,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on Object catch (error, stackTrace) {
      _handleUnexpectedFailure(
        error: error,
        stackTrace: stackTrace,
        unitId: action.unitId,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    }
  }

  void _handleResult({
    required UnitLogisticsCommandResultView result,
    required UnitLogisticsActionView action,
    required int correlationId,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    final ready = _correlated(readState(), action.unitId, correlationId);
    if (ready == null) return;
    if (!result.accepted) {
      publish(_rejected(ready, result.rejectionCode!));
      return;
    }
    publish(_accepted(ready, result.player!, action.unitId));
    load(
      unitId: action.unitId,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    );
  }

  void _handleSessionFailure({
    required UnitLogisticsSessionException error,
    required StackTrace stackTrace,
    required String unitId,
    required int correlationId,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _report(error, stackTrace);
    final ready = _correlated(readState(), unitId, correlationId);
    if (ready != null) publish(_commandFailure(ready, error));
  }

  void _handleUnexpectedFailure({
    required Object error,
    required StackTrace stackTrace,
    required String unitId,
    required int correlationId,
    required LogisticsStateReader readState,
    required LogisticsStatePublisher publish,
    required LogisticsDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _diagnosticReporter('unexpected_unit_logistics_failure', error, stackTrace);
    final ready = _correlated(readState(), unitId, correlationId);
    if (ready != null) publish(_unexpectedCommandFailure(ready));
  }

  void _report(UnitLogisticsSessionException error, StackTrace stackTrace) {
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

GameSessionReady? _selected(GameSessionState state, String unitId) =>
    state is GameSessionReady && state.interaction.selectedUnitId == unitId
    ? state
    : null;

GameSessionReady? _selectedAtRevision(
  GameSessionState state,
  String unitId,
  int revision,
) {
  final ready = _selected(state, unitId);
  return ready?.recipient.stamp.revision == revision ? ready : null;
}

GameSessionReady? _executable(
  GameSessionState state,
  UnitLogisticsActionView action,
) {
  final current = _selected(state, action.unitId);
  final logistics = current?.interaction.unitLogistics;
  if (current == null ||
      current.research.commandPending ||
      current.diplomacy.commandPending ||
      logistics == null ||
      logistics.commandPending ||
      !_containsAction(logistics.options, action)) {
    return null;
  }
  return current;
}

GameSessionReady? _correlated(
  GameSessionState state,
  String unitId,
  int correlationId,
) {
  final ready = _selected(state, unitId);
  return ready?.interaction.unitLogistics?.correlationId == correlationId
      ? ready
      : null;
}

GameSessionReady _pending(
  GameSessionReady current,
  UnitLogisticsActionView action,
  int correlationId,
) => current.withInteraction(
  current.interaction.copyWith(
    clearReachable: true,
    clearRoute: true,
    unitLogistics: current.interaction.unitLogistics!.copyWith(
      correlationId: correlationId,
      inFlightAction: action,
      clearFailure: true,
    ),
  ),
);

GameSessionReady _rejected(
  GameSessionReady current,
  UnitLogisticsRejectionCodeView code,
) => current.withInteraction(
  current.interaction.copyWith(
    unitLogistics: current.interaction.unitLogistics!.copyWith(
      clearInFlightAction: true,
      failure: UnitLogisticsFailureView.rejected(code),
    ),
  ),
);

GameSessionReady _accepted(
  GameSessionReady current,
  PlayerMapView player,
  String unitId,
) {
  final synchronized = current.withRecipient(player);
  final unit = synchronized.recipient.controlledUnitById(unitId);
  if (unit == null) {
    return synchronized.withInteraction(_clearUnitSelection(synchronized));
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      selected: unit.coordinate,
      unitLogistics: UnitLogisticsState.loading(unitId),
      actionDeck: synchronized.interaction.actionDeck?.copyWith(
        clearFailure: true,
      ),
    ),
  );
}

GameSessionReady _loadFailure(
  GameSessionReady current,
  UnitLogisticsSessionException error,
) => current.withInteraction(
  current.interaction.copyWith(
    unitLogistics: UnitLogisticsState(
      unitId: current.interaction.selectedUnitId!,
      failure: UnitLogisticsFailureView(_failureCode(error.code)),
    ),
  ),
);

GameSessionReady _unexpectedLoadFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        unitLogistics: UnitLogisticsState(
          unitId: current.interaction.selectedUnitId!,
          failure: const UnitLogisticsFailureView(
            UnitLogisticsFailureCode.requestFailed,
          ),
        ),
      ),
    );

GameSessionReady _commandFailure(
  GameSessionReady current,
  UnitLogisticsSessionException error,
) {
  final player = error.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  final logistics = synchronized.interaction.unitLogistics!;
  if (player != null &&
      synchronized.recipient.controlledUnitById(logistics.unitId) == null) {
    return synchronized.withInteraction(_clearUnitSelection(synchronized));
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      unitLogistics: logistics.copyWith(
        clearInFlightAction: true,
        failure: UnitLogisticsFailureView(_failureCode(error.code)),
      ),
    ),
  );
}

GameSessionReady _unexpectedCommandFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        unitLogistics: current.interaction.unitLogistics!.copyWith(
          clearInFlightAction: true,
          failure: const UnitLogisticsFailureView(
            UnitLogisticsFailureCode.requestFailed,
          ),
        ),
      ),
    );

MapInteractionState _clearUnitSelection(GameSessionReady current) =>
    current.interaction.copyWith(
      clearSelected: true,
      clearSelectedUnit: true,
      clearReachable: true,
      clearRoute: true,
      clearActionDeck: true,
      clearUnitLogistics: true,
      clearProduction: true,
    );

bool _containsAction(
  UnitLogisticsOptionsView? options,
  UnitLogisticsActionView action,
) {
  if (options == null || options.unitId != action.unitId) return false;
  return switch (action) {
    AutoExploreActionView() => options.autoExplore != null,
    AssignMerchantRouteActionView(:final destinationCityId) =>
      options.merchantRouteDestinations.any(
        (option) => option.cityId == destinationCityId,
      ),
    MoveMerchantToCityActionView(:final destinationCityId) =>
      options.merchantTravelDestinations.any(
        (option) => option.cityId == destinationCityId,
      ),
    DetachTroopActionView(:final troopKind) => options.detachments.any(
      (option) => option.troopKind == troopKind,
    ),
  };
}

UnitLogisticsFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' => UnitLogisticsFailureCode.responseIncompatible,
  'session_not_open' => UnitLogisticsFailureCode.sessionUnavailable,
  _ => UnitLogisticsFailureCode.requestFailed,
};
