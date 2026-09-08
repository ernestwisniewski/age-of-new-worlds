part of 'map_coordinator.dart';

extension MapCoordinatorTargeting on MapCoordinator {
  bool get canToggleMoveTargeting {
    final current = _state;
    if (current is! GameSessionReady || !_gameplayActive()) return false;
    return !_cancellationBlocked(current) &&
        !_otherTargetingMode(current) &&
        (current.interaction.moveTargeting || _canStartMoveTargeting(current));
  }

  Future<void> _loadMovementAvailability(
    String unitId, {
    bool retainTargeting = false,
  }) async {
    final current = _state;
    if (current is! GameSessionReady ||
        current.interaction.selectedUnitId != unitId) {
      return;
    }
    final generation = _interactionGeneration;
    final result = await _movement.reachable(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
    );
    final ready = _currentInteraction(generation);
    if (ready == null ||
        ready.interaction.selectedUnitId != unitId ||
        ready.recipient.actorPlayerId != current.recipient.actorPlayerId ||
        !_sameMovementStamp(ready.recipient.stamp, current.recipient.stamp)) {
      return;
    }
    if (result.failure != null) {
      _setState(_movementFailureState(ready, result));
    } else {
      _publishMovementAvailability(
        ready,
        result.result,
        unitId,
        retainTargeting,
      );
    }
  }

  void _publishMovementAvailability(
    GameSessionReady ready,
    ReachableView? reachable,
    String unitId,
    bool retainTargeting,
  ) {
    if (reachable == null ||
        reachable.unitId != unitId ||
        !_sameMovementStamp(reachable.stamp, ready.recipient.stamp)) {
      return;
    }
    _setState(
      ready.withInteraction(
        ready.interaction.copyWith(
          reachable: reachable,
          moveTargeting:
              retainTargeting &&
              reachable.canRetainTargeting &&
              !_otherTargetingMode(ready),
        ),
      ),
    );
  }

  void toggleMoveTargeting() {
    final current = _state;
    if (current is! GameSessionReady || !_gameplayActive()) return;
    if (_cancellationBlocked(current) || _otherTargetingMode(current)) return;
    if (current.interaction.moveTargeting) {
      _cancelUnitPreview(current);
      return;
    }
    if (!_canStartMoveTargeting(current)) return;
    _interactionGeneration += 1;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          moveTargeting: true,
          clearRoute: true,
          clearMovementError: true,
        ),
      ),
    );
  }

  void moveMapCursor(MapHexCoordinate coordinate) {
    final current = _state;
    if (current is! GameSessionReady || !_gameplayActive()) return;
    if (!current.scene.map.contains(coordinate)) return;
    hover(coordinate);
    if (current.interaction.moveTargeting || _otherTargetingMode(current)) {
      return;
    }
    if (_availableSelectionState() == null) return;
    _interactionGeneration += 1;
    _selectPlainHex(current, coordinate);
  }
}

bool _otherTargetingMode(GameSessionReady current) =>
    current.interaction.city?.founderUnitId != null ||
    current.interaction.city?.managementMode != null ||
    current.interaction.worker?.actionsOpen == true ||
    current.interaction.combat != null ||
    current.recipient.pendingAction != null;

bool _canStartMoveTargeting(GameSessionReady current) {
  final interaction = current.interaction;
  final reachable = interaction.reachable;
  final unitId = interaction.selectedUnitId;
  if (reachable == null || unitId == null || !reachable.canStartTargeting) {
    return false;
  }
  final stamp = current.recipient.stamp;
  return reachable.unitId == unitId &&
      current.recipient.controlledUnitById(unitId) != null &&
      _sameMovementStamp(reachable.stamp, stamp);
}

bool _sameMovementStamp(SessionStampView left, SessionStampView right) =>
    left.revision == right.revision &&
    left.stateDigest == right.stateDigest &&
    left.mapHash == right.mapHash &&
    left.rulesetHash == right.rulesetHash;
