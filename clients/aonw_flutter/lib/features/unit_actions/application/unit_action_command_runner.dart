import '../../map/read_model/player_map_view.dart';
import '../read_model/unit_action_view.dart';
import 'action_deck_state.dart';
import 'unit_action_session_port.dart';

typedef UnitActionDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class UnitActionCommandCompletion {
  const UnitActionCommandCompletion.completed(this.result)
    : failure = null,
      resyncedPlayer = null;

  const UnitActionCommandCompletion.failed(this.failure, {this.resyncedPlayer})
    : result = null;

  final UnitActionResultView? result;
  final UnitActionFailure? failure;
  final PlayerMapView? resyncedPlayer;
}

final class UnitActionCommandRunner {
  const UnitActionCommandRunner({
    required UnitActionSessionPort session,
    required UnitActionDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final UnitActionSessionPort _session;
  final UnitActionDiagnosticReporter _diagnosticReporter;

  Future<UnitActionCommandCompletion> execute({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) async {
    try {
      final result = await _session.executeUnitAction(
        expectedRevision: expectedRevision,
        unitId: unitId,
        action: action,
      );
      return UnitActionCommandCompletion.completed(result);
    } on UnitActionSessionException catch (error, stackTrace) {
      final cause = error.diagnosticCause;
      if (cause != null) {
        _diagnosticReporter(
          error.code,
          cause,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      return UnitActionCommandCompletion.failed(
        UnitActionFailure(_failureCode(error.code)),
        resyncedPlayer: error.resyncedPlayer,
      );
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_unit_action_failure', error, stackTrace);
      return const UnitActionCommandCompletion.failed(
        UnitActionFailure(UnitActionFailureViewCode.requestFailed),
      );
    }
  }
}

UnitActionFailureViewCode _failureCode(String code) => switch (code) {
  'session_not_open' => UnitActionFailureViewCode.sessionUnavailable,
  'invalid_session_protocol' ||
  'recipient_resynchronized' => UnitActionFailureViewCode.responseIncompatible,
  _ => UnitActionFailureViewCode.requestFailed,
};
