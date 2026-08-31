import '../../map/read_model/player_map_view.dart';
import '../read_model/turn_command_view.dart';
import 'turn_action_state.dart';
import 'turn_session_port.dart';

typedef TurnDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class TurnCommandCompletion {
  const TurnCommandCompletion.completed(this.result)
    : failure = null,
      resyncedPlayer = null;

  const TurnCommandCompletion.failed(this.failure, {this.resyncedPlayer})
    : result = null;

  final TurnCommandResultView? result;
  final TurnActionFailureView? failure;
  final PlayerMapView? resyncedPlayer;
}

final class TurnCommandRunner {
  const TurnCommandRunner({
    required TurnSessionPort session,
    required TurnDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final TurnSessionPort _session;
  final TurnDiagnosticReporter _diagnosticReporter;

  Future<TurnCommandCompletion> endTurn({required int expectedRevision}) async {
    try {
      return TurnCommandCompletion.completed(
        await _session.endTurn(expectedRevision: expectedRevision),
      );
    } on TurnSessionException catch (error, stackTrace) {
      final cause = error.diagnosticCause;
      if (cause != null) {
        _diagnosticReporter(
          error.code,
          cause,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      return TurnCommandCompletion.failed(
        TurnActionFailureView.transport(_failureCode(error.code)),
        resyncedPlayer: error.resyncedPlayer,
      );
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_turn_failure', error, stackTrace);
      return const TurnCommandCompletion.failed(
        TurnActionFailureView.transport(TurnFailureViewCode.requestFailed),
      );
    }
  }
}

TurnFailureViewCode _failureCode(String code) => switch (code) {
  'session_not_open' => TurnFailureViewCode.sessionUnavailable,
  'invalid_session_protocol' ||
  'recipient_resynchronized' => TurnFailureViewCode.responseIncompatible,
  _ => TurnFailureViewCode.requestFailed,
};
