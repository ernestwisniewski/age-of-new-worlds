import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/application/map_interaction_state.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/worker_view.dart';
import 'worker_session_port.dart';
import 'worker_state.dart';

part 'worker_workflow_commands.dart';
part 'worker_workflow_guards.dart';
part 'worker_workflow_loading.dart';

typedef WorkerStateReader = GameSessionState Function();
typedef WorkerStatePublisher = void Function(GameSessionReady value);
typedef WorkerDisposed = bool Function();
typedef WorkerDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class WorkerWorkflow {
  WorkerWorkflow({
    required WorkerSessionPort session,
    required WorkerDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final WorkerSessionPort _session;
  final WorkerDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void load({
    required String unitId,
    required WorkerStateReader readState,
    required WorkerStatePublisher publish,
    required WorkerDisposed isDisposed,
  }) => unawaited(
    _load(
      unitId: unitId,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  void execute({
    required WorkerActionView action,
    required WorkerStateReader readState,
    required WorkerStatePublisher publish,
    required WorkerDisposed isDisposed,
  }) => unawaited(
    _execute(
      action: action,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  void _report(WorkerSessionException error, StackTrace stackTrace) {
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
