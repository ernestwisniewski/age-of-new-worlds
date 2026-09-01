import 'dart:async';

import '../../map/application/game_session_state.dart';
import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/city_view.dart';
import 'city_session_port.dart';
import 'city_state.dart';

part 'city_workflow_commands.dart';
part 'city_workflow_guards.dart';
part 'city_workflow_loading.dart';

typedef CityStateReader = GameSessionState Function();
typedef CityStatePublisher = void Function(GameSessionReady value);
typedef CityDisposed = bool Function();
typedef CityDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class CityWorkflow {
  CityWorkflow({
    required CitySessionPort session,
    required CityDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;

  final CitySessionPort _session;
  final CityDiagnosticReporter _diagnosticReporter;
  var _correlationId = 0;

  void inspect({
    required String cityId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) => unawaited(
    _inspect(
      cityId: cityId,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    ),
  );

  void openFounding({
    required String founderUnitId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    final ready = _selectedUnit(readState(), founderUnitId);
    if (ready == null) return;
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          city: CityState.loadingFounding(founderUnitId),
          clearRoute: true,
          clearCombat: true,
        ),
      ),
    );
    unawaited(
      _founding(
        founderUnitId: founderUnitId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      ),
    );
  }

  void toggleFoundingHex({
    required MapHexCoordinate coordinate,
    required CityStateReader readState,
    required CityStatePublisher publish,
  }) {
    final state = readState();
    if (state is! GameSessionReady) return;
    final city = state.interaction.city;
    final options = city?.foundingOptions;
    if (city == null ||
        options == null ||
        city.loading ||
        city.commandPending) {
      return;
    }
    final allowed = <MapHexCoordinate>{
      ...options.selectedControlledHexes,
      ...options.availableControlledHexes,
    };
    if (!allowed.contains(coordinate)) return;
    final selection = [...city.foundingSelection];
    selection.contains(coordinate)
        ? selection.remove(coordinate)
        : selection.add(coordinate);
    if (selection.length > options.requiredControlledHexes) return;
    publish(
      state.withInteraction(
        state.interaction.copyWith(
          city: city.copyWith(foundingSelection: selection, clearFailure: true),
        ),
      ),
    );
  }

  void cancelFounding({
    required CityStateReader readState,
    required CityStatePublisher publish,
  }) {
    final state = readState();
    if (state is! GameSessionReady ||
        state.interaction.city?.founderUnitId == null ||
        state.interaction.city?.commandPending == true) {
      return;
    }
    publish(state.withInteraction(state.interaction.copyWith(clearCity: true)));
  }

  void confirmFounding({
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    final state = readState();
    if (state is! GameSessionReady) return;
    final city = state.interaction.city;
    final options = city?.foundingOptions;
    if (city == null ||
        options == null ||
        city.commandPending ||
        city.foundingSelection.length != options.requiredControlledHexes) {
      return;
    }
    execute(
      action: FoundCityActionView(
        founderUnitId: options.founderUnitId,
        controlledHexes: city.foundingSelection,
      ),
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    );
  }

  void execute({
    required CityActionView action,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
    void Function(String cityId)? onSelectionRetained,
  }) => unawaited(
    _execute(
      action: action,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
      onSelectionRetained: onSelectionRetained,
    ),
  );

  void _report(CitySessionException error, StackTrace stackTrace) {
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
