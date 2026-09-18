part of 'map_coordinator.dart';

extension MapCoordinatorProductionInspection on MapCoordinator {
  void inspectProduction(ProductionTargetView? target) {
    if (_availableSelectionState() == null) return;
    _production.inspect(
      target: target,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void _refreshProductionInspection(
    GameSessionState previous,
    GameSessionState next,
  ) {
    if (previous is! GameSessionReady ||
        next is! GameSessionReady ||
        _productionRecipientIdentity(previous) ==
            _productionRecipientIdentity(next) ||
        next.interaction.production?.inspection == null) {
      return;
    }
    scheduleMicrotask(() {
      if (_disposed) return;
      final current = _state;
      if (current is! GameSessionReady) return;
      final target = current.interaction.production?.inspection?.target;
      if (target != null) inspectProduction(target);
    });
  }
}

(String, int, String, String, String) _productionRecipientIdentity(
  GameSessionReady state,
) => (
  state.recipient.actorPlayerId,
  state.recipient.stamp.revision,
  state.recipient.stamp.stateDigest,
  state.recipient.stamp.mapHash,
  state.recipient.stamp.rulesetHash,
);
