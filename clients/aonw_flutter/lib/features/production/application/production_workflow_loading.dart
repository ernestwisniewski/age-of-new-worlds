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
      final ready = _selectedProductionForRequest(readState(), current);
      if (ready == null) return;
      final inspected = ready.interaction.production!.inspection?.target;
      publish(
        ready.withInteraction(
          ready.interaction.copyWith(
            production: ProductionState(
              cityId: cityId,
              catalogOpen: ready.interaction.production!.catalogOpen,
              options: overview.options,
              resources: overview.resources,
            ),
          ),
        ),
      );
      _refreshInspection(inspected, readState, publish, isDisposed);
    } on ProductionSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _selectedProductionForRequest(readState(), current);
      if (ready != null) publish(_productionLoadFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_production_failure', error, stackTrace);
      final ready = _selectedProductionForRequest(readState(), current);
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
      catalogOpen: current.interaction.production!.catalogOpen,
      failure: ProductionFailureView(_productionFailureCode(error.code)),
    ),
  ),
);

GameSessionReady _unexpectedProductionLoadFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        production: ProductionState(
          cityId: current.interaction.production!.cityId,
          catalogOpen: current.interaction.production!.catalogOpen,
          failure: const ProductionFailureView(
            ProductionFailureCode.requestFailed,
          ),
        ),
      ),
    );
