part of 'production_workflow.dart';

extension ProductionWorkflowCommands on ProductionWorkflow {
  Future<void> _execute({
    required ProductionActionView action,
    required ProductionStateReader readState,
    required ProductionStatePublisher publish,
    required ProductionDisposed isDisposed,
  }) async {
    final current = _executableProduction(readState(), action);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(_pendingProduction(current, action, correlationId));
    try {
      final result = await _session.executeProductionAction(
        expectedRevision: current.recipient.stamp.revision,
        action: action,
      );
      if (isDisposed()) return;
      final ready = _correlatedProduction(
        readState(),
        action.cityId,
        correlationId,
      );
      if (ready == null) return;
      if (!result.accepted) {
        publish(_rejectedProduction(ready, result.rejectionCode!));
        return;
      }
      publish(_acceptedProduction(ready, result.player!, action.cityId));
      load(
        cityId: action.cityId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on ProductionSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _correlatedProduction(
        readState(),
        action.cityId,
        correlationId,
      );
      if (ready != null) publish(_productionCommandFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_production_failure', error, stackTrace);
      final ready = _correlatedProduction(
        readState(),
        action.cityId,
        correlationId,
      );
      if (ready != null) publish(_unexpectedProductionCommandFailure(ready));
    }
  }
}

GameSessionReady _pendingProduction(
  GameSessionReady current,
  ProductionActionView action,
  int correlationId,
) => current.withInteraction(
  current.interaction.copyWith(
    production: current.interaction.production!.copyWith(
      correlationId: correlationId,
      inFlightAction: action,
      clearFailure: true,
    ),
  ),
);

GameSessionReady _rejectedProduction(
  GameSessionReady current,
  ProductionRejectionCodeView code,
) => current.withInteraction(
  current.interaction.copyWith(
    production: current.interaction.production!.copyWith(
      clearInFlightAction: true,
      failure: ProductionFailureView.rejected(code),
    ),
  ),
);

GameSessionReady _acceptedProduction(
  GameSessionReady current,
  PlayerMapView player,
  String cityId,
) {
  final synchronized = current.withRecipient(player);
  final city = synchronized.recipient.controlledCityById(cityId);
  if (city == null) {
    return synchronized.withInteraction(
      synchronized.interaction.copyWith(clearCity: true, clearProduction: true),
    );
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      selected: city.center,
      production: ProductionState.loading(cityId),
    ),
  );
}

GameSessionReady _productionCommandFailure(
  GameSessionReady current,
  ProductionSessionException error,
) {
  final player = error.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  final state = synchronized.interaction.production!;
  if (player != null &&
      synchronized.recipient.controlledCityById(state.cityId) == null) {
    return synchronized.withInteraction(
      synchronized.interaction.copyWith(clearCity: true, clearProduction: true),
    );
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      production: state.copyWith(
        clearInFlightAction: true,
        failure: ProductionFailureView(_productionFailureCode(error.code)),
      ),
    ),
  );
}

GameSessionReady _unexpectedProductionCommandFailure(
  GameSessionReady current,
) => current.withInteraction(
  current.interaction.copyWith(
    production: current.interaction.production!.copyWith(
      clearInFlightAction: true,
      failure: const ProductionFailureView(ProductionFailureCode.requestFailed),
    ),
  ),
);
