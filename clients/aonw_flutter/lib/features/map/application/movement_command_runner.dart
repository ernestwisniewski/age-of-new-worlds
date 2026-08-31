import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';
import 'map_interaction_state.dart';
import 'movement_session_port.dart';

typedef MovementDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class MovementCommandCompletion<T> {
  const MovementCommandCompletion.completed(this.result)
    : failure = null,
      resyncedPlayer = null;

  const MovementCommandCompletion.failed(this.failure, {this.resyncedPlayer})
    : result = null;

  final T? result;
  final MapMovementFailure? failure;
  final PlayerMapView? resyncedPlayer;
}

final class MovementCommandRunner {
  const MovementCommandRunner({
    required MovementSessionPort session,
    required MovementDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final MovementSessionPort _session;
  final MovementDiagnosticReporter _diagnosticReporter;

  Future<MovementCommandCompletion<ReachableView>> reachable({
    required int expectedRevision,
    required String unitId,
  }) => _execute(
    () =>
        _session.reachable(expectedRevision: expectedRevision, unitId: unitId),
  );

  Future<MovementCommandCompletion<RoutePlanView>> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => _execute(
    () => _session.routePlan(
      expectedRevision: expectedRevision,
      unitId: unitId,
      target: target,
    ),
  );

  Future<MovementCommandCompletion<MoveUnitResultView>> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => _execute(
    () => _session.moveUnit(
      expectedRevision: expectedRevision,
      unitId: unitId,
      target: target,
    ),
  );

  Future<MovementCommandCompletion<T>> _execute<T>(
    Future<T> Function() request,
  ) async {
    try {
      return MovementCommandCompletion.completed(await request());
    } on MovementSessionException catch (error, stackTrace) {
      final cause = error.diagnosticCause;
      if (cause != null) {
        _diagnosticReporter(
          error.code,
          cause,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      return MovementCommandCompletion.failed(
        MapMovementFailure(_failureCode(error.code)),
        resyncedPlayer: error.resyncedPlayer,
      );
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_movement_failure', error, stackTrace);
      return const MovementCommandCompletion.failed(
        MapMovementFailure(MapMovementFailureViewCode.requestFailed),
      );
    }
  }
}

MapMovementFailureViewCode _failureCode(String code) => switch (code) {
  'session_not_open' => MapMovementFailureViewCode.sessionUnavailable,
  'invalid_session_protocol' ||
  'recipient_resynchronized' => MapMovementFailureViewCode.responseIncompatible,
  _ => MapMovementFailureViewCode.requestFailed,
};
