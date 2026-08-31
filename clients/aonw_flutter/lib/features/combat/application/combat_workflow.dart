import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/combat_view.dart';
import 'combat_session_port.dart';
import 'combat_state.dart';

typedef CombatStateReader = GameSessionState Function();
typedef CombatStatePublisher = void Function(GameSessionReady value);
typedef CombatDisposed = bool Function();
typedef CombatDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class CombatWorkflow {
  CombatWorkflow({
    required CombatSessionPort session,
    required CombatDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final CombatSessionPort _session;
  final CombatDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void preview({
    required String attackerUnitId,
    required MapHexCoordinate defender,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    unawaited(
      _preview(
        attackerUnitId: attackerUnitId,
        defender: defender,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      ),
    );
  }

  void attack({
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    unawaited(
      _attack(readState: readState, publish: publish, isDisposed: isDisposed),
    );
  }

  void setCityConquestAction({
    required CityConquestActionView action,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
  }) {
    final ready = readState();
    if (ready is! GameSessionReady) return;
    final combat = ready.interaction.combat;
    if (combat?.preview?.target.kind != CombatTargetKindView.city ||
        combat!.commandPending) {
      return;
    }
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          combat: combat.copyWith(cityConquestAction: action),
        ),
      ),
    );
  }

  Future<void> _preview({
    required String attackerUnitId,
    required MapHexCoordinate defender,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) async {
    final current = _selected(readState(), attackerUnitId);
    if (current == null ||
        current.research.commandPending ||
        current.diplomacy.commandPending ||
        !current.scene.map.contains(defender)) {
      return;
    }
    final revision = current.recipient.stamp.revision;
    final correlationId = ++_correlationId;
    publish(_previewPending(current, attackerUnitId, defender, correlationId));
    try {
      final preview = await _session.combatPreview(
        expectedRevision: revision,
        attackerUnitId: attackerUnitId,
        defender: defender,
      );
      _handlePreview(
        preview: preview,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on CombatSessionException catch (error, stackTrace) {
      _handlePreviewFailure(
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on Object catch (error, stackTrace) {
      _handleUnexpectedPreviewFailure(
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    }
  }

  Future<void> _attack({
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) async {
    final current = readState();
    if (current is! GameSessionReady) return;
    final combat = current.interaction.combat;
    final preview = combat?.preview;
    if (current.research.commandPending ||
        current.diplomacy.commandPending ||
        combat == null ||
        preview == null ||
        combat.commandPending) {
      return;
    }
    final correlationId = ++_correlationId;
    final attack = CombatAttackView(
      preview: preview,
      cityConquestAction: combat.cityConquestAction,
    );
    publish(
      current.withInteraction(
        current.interaction.copyWith(
          combat: combat.copyWith(
            correlationId: correlationId,
            commandPending: true,
            clearFailure: true,
            clearLastExecution: true,
          ),
        ),
      ),
    );
    try {
      final result = await _session.attack(
        expectedRevision: current.recipient.stamp.revision,
        attack: attack,
      );
      _handleAttack(
        result: result,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on CombatSessionException catch (error, stackTrace) {
      _handleAttackFailure(
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on Object catch (error, stackTrace) {
      _handleUnexpectedAttackFailure(
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    }
  }

  void _handlePreview({
    required CombatPreviewView preview,
    required int correlationId,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    final ready = _correlated(readState(), correlationId);
    if (ready == null) return;
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          combat: ready.interaction.combat!.copyWith(
            loading: false,
            preview: preview,
            clearFailure: true,
          ),
        ),
      ),
    );
  }

  void _handleAttack({
    required CombatCommandResultView result,
    required int correlationId,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    final ready = _correlated(readState(), correlationId);
    if (ready == null) return;
    if (!result.accepted) {
      publish(_rejected(ready, result.rejectionCode!));
      return;
    }
    publish(_accepted(ready, result.player!, result.execution!));
  }

  void _handlePreviewFailure({
    required CombatSessionException error,
    required StackTrace stackTrace,
    required int correlationId,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _report(error, stackTrace);
    final ready = _correlated(readState(), correlationId);
    if (ready != null) publish(_previewFailure(ready, error));
  }

  void _handleUnexpectedPreviewFailure({
    required Object error,
    required StackTrace stackTrace,
    required int correlationId,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _diagnosticReporter('unexpected_combat_failure', error, stackTrace);
    final ready = _correlated(readState(), correlationId);
    if (ready != null) publish(_unexpectedPreviewFailure(ready));
  }

  void _handleAttackFailure({
    required CombatSessionException error,
    required StackTrace stackTrace,
    required int correlationId,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _report(error, stackTrace);
    final ready = _correlated(readState(), correlationId);
    if (ready != null) publish(_attackFailure(ready, error));
  }

  void _handleUnexpectedAttackFailure({
    required Object error,
    required StackTrace stackTrace,
    required int correlationId,
    required CombatStateReader readState,
    required CombatStatePublisher publish,
    required CombatDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _diagnosticReporter('unexpected_combat_failure', error, stackTrace);
    final ready = _correlated(readState(), correlationId);
    if (ready != null) publish(_unexpectedAttackFailure(ready));
  }

  void _report(CombatSessionException error, StackTrace stackTrace) {
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

GameSessionReady? _selected(GameSessionState state, String attackerUnitId) =>
    state is GameSessionReady &&
        state.interaction.selectedUnitId == attackerUnitId
    ? state
    : null;

GameSessionReady? _correlated(GameSessionState state, int correlationId) =>
    state is GameSessionReady &&
        state.interaction.combat?.correlationId == correlationId
    ? state
    : null;

GameSessionReady _previewPending(
  GameSessionReady current,
  String attackerUnitId,
  MapHexCoordinate defender,
  int correlationId,
) => current.withInteraction(
  current.interaction.copyWith(
    selected: defender,
    clearReachable: true,
    clearRoute: true,
    clearUnitLogistics: true,
    combat: CombatState.loading(
      attackerUnitId: attackerUnitId,
      defenderCoordinate: defender,
      correlationId: correlationId,
    ),
    movementPending: false,
    clearMovementError: true,
  ),
);

GameSessionReady _rejected(
  GameSessionReady current,
  CombatRejectionCodeView rejection,
) => current.withInteraction(
  current.interaction.copyWith(
    combat: current.interaction.combat!.copyWith(
      commandPending: false,
      failure: CombatFailureView.rejected(rejection),
    ),
  ),
);

GameSessionReady _accepted(
  GameSessionReady current,
  PlayerMapView player,
  CombatExecutionView execution,
) {
  final synchronized = current.withRecipient(player);
  final combat = synchronized.interaction.combat!;
  final attacker = player.controlledUnitById(combat.attackerUnitId);
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      selected: combat.defenderCoordinate,
      clearSelectedUnit: attacker == null,
      clearReachable: true,
      clearRoute: true,
      clearActionDeck: true,
      clearUnitLogistics: true,
      combat: combat.copyWith(
        loading: false,
        commandPending: false,
        lastExecution: execution,
        clearFailure: true,
      ),
    ),
  );
}

GameSessionReady _previewFailure(
  GameSessionReady current,
  CombatSessionException error,
) => current.withInteraction(
  current.interaction.copyWith(
    combat: current.interaction.combat!.copyWith(
      loading: false,
      clearPreview: true,
      failure: CombatFailureView(_previewFailureCode(error.code)),
    ),
  ),
);

GameSessionReady _unexpectedPreviewFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        combat: current.interaction.combat!.copyWith(
          loading: false,
          clearPreview: true,
          failure: const CombatFailureView(CombatFailureCode.requestFailed),
        ),
      ),
    );

GameSessionReady _attackFailure(
  GameSessionReady current,
  CombatSessionException error,
) {
  final player = error.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  final combat = synchronized.interaction.combat!;
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      clearSelectedUnit:
          player != null &&
          player.controlledUnitById(combat.attackerUnitId) == null,
      combat: combat.copyWith(
        commandPending: false,
        failure: CombatFailureView(_failureCode(error.code)),
      ),
    ),
  );
}

GameSessionReady _unexpectedAttackFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        combat: current.interaction.combat!.copyWith(
          commandPending: false,
          failure: const CombatFailureView(CombatFailureCode.requestFailed),
        ),
      ),
    );

CombatFailureCode _previewFailureCode(String code) =>
    _combatRuleCodes.contains(code)
    ? CombatFailureCode.targetUnavailable
    : _failureCode(code);

CombatFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' => CombatFailureCode.responseIncompatible,
  'session_not_open' => CombatFailureCode.sessionUnavailable,
  _ => CombatFailureCode.requestFailed,
};

const _combatRuleCodes = {
  'stale_revision',
  'match_finished',
  'attacker_not_found',
  'attacker_not_controlled',
  'attacker_unavailable',
  'attacker_exhausted',
  'attacker_out_of_bounds',
  'attacker_cannot_attack',
  'attack_target_not_visible',
  'attack_target_out_of_bounds',
  'attack_target_not_found',
  'attack_target_not_enemy',
  'attack_target_protected_by_treaty',
  'attack_target_out_of_range',
  'attack_city_has_no_health',
};
