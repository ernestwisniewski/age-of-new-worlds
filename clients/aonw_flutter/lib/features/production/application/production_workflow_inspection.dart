part of 'production_workflow.dart';

extension ProductionWorkflowInspection on ProductionWorkflow {
  void inspect({
    required ProductionTargetView? target,
    required ProductionStateReader readState,
    required ProductionStatePublisher publish,
    required ProductionDisposed isDisposed,
  }) {
    final current = readState();
    if (current is! GameSessionReady) return;
    final production = current.interaction.production;
    if (production == null || !production.catalogOpen) return;
    final correlation = ++_inspectionCorrelationId;
    if (target == null) {
      publish(_withProductionInspection(current, null));
      return;
    }
    if (production.loading || production.options?.optionFor(target) == null) {
      return;
    }
    final inspection = ProductionInspectionState(
      target: target,
      correlationId: correlation,
    );
    publish(_withProductionInspection(current, inspection));
    unawaited(_inspect(current, inspection, readState, publish, isDisposed));
  }

  void _refreshInspection(
    ProductionTargetView? target,
    ProductionStateReader readState,
    ProductionStatePublisher publish,
    ProductionDisposed isDisposed,
  ) {
    if (target == null) return;
    inspect(
      target: target,
      readState: readState,
      publish: publish,
      isDisposed: isDisposed,
    );
  }

  Future<void> _inspect(
    GameSessionReady requested,
    ProductionInspectionState inspection,
    ProductionStateReader readState,
    ProductionStatePublisher publish,
    ProductionDisposed isDisposed,
  ) async {
    final cityId = requested.interaction.production!.cityId;
    try {
      final details = await _session.productionDetails(
        expectedRevision: requested.recipient.stamp.revision,
        cityId: cityId,
        target: inspection.target,
      );
      if (isDisposed()) return;
      final current = _currentInspection(readState(), requested, inspection);
      if (current == null) return;
      publish(
        _withProductionInspection(
          current,
          ProductionInspectionState(
            target: inspection.target,
            correlationId: inspection.correlationId,
            loading: false,
            details: details,
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      final current = _currentInspection(readState(), requested, inspection);
      if (current == null) return;
      final code = error is ProductionSessionException
          ? _productionFailureCode(error.code)
          : ProductionFailureCode.requestFailed;
      if (error is ProductionSessionException) {
        _report(error, stackTrace);
      } else {
        _diagnosticReporter(
          'unexpected_production_details_failure',
          error,
          stackTrace,
        );
      }
      publish(
        _withProductionInspection(
          current,
          ProductionInspectionState(
            target: inspection.target,
            correlationId: inspection.correlationId,
            loading: false,
            failure: ProductionFailureView(code),
          ),
        ),
      );
    }
  }
}

GameSessionReady _withProductionInspection(
  GameSessionReady current,
  ProductionInspectionState? inspection,
) => current.withInteraction(
  current.interaction.copyWith(
    production: current.interaction.production!.copyWith(
      inspection: inspection,
      clearInspection: inspection == null,
    ),
  ),
);

GameSessionReady? _currentInspection(
  GameSessionState state,
  GameSessionReady requested,
  ProductionInspectionState inspection,
) {
  final current = _selectedProduction(
    state,
    requested.interaction.production!.cityId,
  );
  final production = current?.interaction.production;
  if (current == null ||
      !_sameProductionRecipient(requested, current) ||
      production?.catalogOpen != true ||
      production?.inspection?.correlationId != inspection.correlationId) {
    return null;
  }
  return current;
}

bool _sameProductionRecipient(GameSessionReady left, GameSessionReady right) =>
    (
      left.recipient.actorPlayerId,
      left.recipient.stamp.revision,
      left.recipient.stamp.stateDigest,
      left.recipient.stamp.mapHash,
      left.recipient.stamp.rulesetHash,
    ) ==
    (
      right.recipient.actorPlayerId,
      right.recipient.stamp.revision,
      right.recipient.stamp.stateDigest,
      right.recipient.stamp.mapHash,
      right.recipient.stamp.rulesetHash,
    );
