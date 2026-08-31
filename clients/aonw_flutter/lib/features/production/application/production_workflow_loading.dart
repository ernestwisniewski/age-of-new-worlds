part of 'production_workflow.dart';

extension ProductionWorkflowLoading on ProductionWorkflow {
  Future<void> _load({
    required String cityId,
    required ProductionStateReader readState,
    required ProductionStatePublisher publish,
    required ProductionDisposed isDisposed,
  }) async {
    final current = _selectedProduction(readState(), cityId);
    if (current == null) return;
    final revision = current.recipient.stamp.revision;
    try {
      final overview = await _session.productionOverview(
        expectedRevision: revision,
        cityId: cityId,
      );
      if (isDisposed()) return;
      final ready = _selectedProductionAtRevision(
        readState(),
        cityId,
        revision,
      );
      if (ready == null) return;
      publish(
        ready.withInteraction(
          ready.interaction.copyWith(
            production: ProductionState(
              cityId: cityId,
              options: overview.options,
              resources: overview.resources,
            ),
          ),
        ),
      );
    } on ProductionSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _selectedProduction(readState(), cityId);
      if (ready != null) publish(_productionLoadFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_production_failure', error, stackTrace);
      final ready = _selectedProduction(readState(), cityId);
      if (ready != null) publish(_unexpectedProductionLoadFailure(ready));
    }
  }
}

GameSessionReady _productionLoadFailure(
  GameSessionReady current,
  ProductionSessionException error,
) => current.withInteraction(
  current.interaction.copyWith(
    production: ProductionState(
      cityId: current.interaction.production!.cityId,
      failure: ProductionFailureView(_productionFailureCode(error.code)),
    ),
  ),
);

GameSessionReady _unexpectedProductionLoadFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        production: ProductionState(
          cityId: current.interaction.production!.cityId,
          failure: const ProductionFailureView(
            ProductionFailureCode.requestFailed,
          ),
        ),
      ),
    );
