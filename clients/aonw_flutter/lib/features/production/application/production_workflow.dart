import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/production_view.dart';
import 'production_session_port.dart';
import 'production_state.dart';

part 'production_workflow_commands.dart';
part 'production_workflow_guards.dart';
part 'production_workflow_loading.dart';

typedef ProductionStateReader = GameSessionState Function();
typedef ProductionStatePublisher = void Function(GameSessionReady value);
typedef ProductionDisposed = bool Function();
typedef ProductionDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class ProductionWorkflow {
  ProductionWorkflow({
    required ProductionSessionPort session,
    required ProductionDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final ProductionSessionPort _session;
  final ProductionDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void load({
    required String cityId,
    required ProductionStateReader readState,
    required ProductionStatePublisher publish,
    required ProductionDisposed isDisposed,
  }) => unawaited(
    _load(
      cityId: cityId,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  void execute({
    required ProductionActionView action,
    required ProductionStateReader readState,
    required ProductionStatePublisher publish,
    required ProductionDisposed isDisposed,
  }) => unawaited(
    _execute(
      action: action,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  void _report(ProductionSessionException error, StackTrace stackTrace) {
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
