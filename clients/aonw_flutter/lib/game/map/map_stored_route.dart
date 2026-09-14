part of 'map_route_layer.dart';

extension _MapStoredRoute on MapRouteLayerComponent {
  void _applyStoredRoute(
    MapStaticRenderCache cache,
    PlayerMapView player,
    String? id,
  ) {
    final unit = id == null ? null : player.controlledUnitById(id);
    final route = unit?.queuedRoute ?? unit?.merchantRoute;
    if (!_validStoredRoute(cache, route, unit)) {
      clearLayer();
      return;
    }
    final currentUnit = unit!;
    final stored = route!;
    final same =
        _identity == cache.identity &&
        _actor == player.actorPlayerId &&
        _storedUnit == (currentUnit.id, currentUnit.coordinate) &&
        _sameStoredRoute(_storedRoute, stored);
    _route = null;
    _storedRoute = stored;
    _storedUnit = (currentUnit.id, currentUnit.coordinate);
    _identity = cache.identity;
    _actor = player.actorPlayerId;
    if (!same) {
      _flowPhase = 0;
      _buildStoredGeometry(cache, stored, currentUnit.coordinate);
    }
    _setGhostKind(_length > 0 ? currentUnit.kind : null);
    if (!same) _resetGhost();
    _refreshActivity();
  }

  void _buildStoredGeometry(
    MapStaticRenderCache cache,
    StoredUnitRouteView route,
    MapHexCoordinate position,
  ) {
    final points = [
      for (final step in route.steps)
        mapProjectedTopFaceCenter(cache, step.coordinate),
    ];
    final current = route.steps.indexWhere(
      (step) => step.coordinate == position,
    );
    _segments = List.unmodifiable([
      for (var index = 1; index < points.length; index++)
        (
          stroke: _MapRouteStroke(
            _routeSegmentPath(
              points,
              index,
              followsRoad: route.roadStepIndices.contains(index),
            ),
            seed: index,
          ),
          reachable: index > current && route.stepTurns[index] == 1,
          followsRoad: route.roadStepIndices.contains(index),
          traversed: index <= current,
        ),
    ]);
    _boundaries = List.unmodifiable(
      _routeBoundaries(points, route.stepTurns, originIndex: current),
    );
    _destination = points.last;
    _destinationReachable = _segments.last.reachable;
    _target = _MapRouteStroke(
      mapProjectedTopFacePath(cache, route.target, scale: 0.86),
      seed: points.length,
    );
    _length = _segments
        .where((segment) => !segment.traversed)
        .fold(0, (total, segment) => total + segment.stroke.length);
    _bounds = _segments
        .fold(
          _target!.bounds,
          (bounds, segment) => bounds.expandToInclude(segment.stroke.bounds),
        )
        .inflate(64);
    final remaining = _segments
        .where((segment) => !segment.traversed)
        .toList(growable: false);
    _motionBounds = remaining.isEmpty
        ? ui.Rect.zero
        : remaining
              .skip(1)
              .fold(
                remaining.first.stroke.bounds,
                (bounds, segment) =>
                    bounds.expandToInclude(segment.stroke.bounds),
              )
              .inflate(64);
    _pathBuildCount++;
    isVisible = true;
  }
}

bool _validStoredRoute(
  MapStaticRenderCache cache,
  StoredUnitRouteView? route,
  VisibleUnitView? unit,
) =>
    route != null &&
    unit != null &&
    route.steps.length >= 2 &&
    route.steps.last.coordinate == route.target &&
    route.steps.any((step) => step.coordinate == unit.coordinate) &&
    route.steps.every((step) => cache.tilePaths.containsKey(step.coordinate));

bool _sameStoredRoute(StoredUnitRouteView? before, StoredUnitRouteView after) {
  if (identical(before, after)) return true;
  if (before == null ||
      before.kind != after.kind ||
      before.target != after.target ||
      before.steps.length != after.steps.length ||
      !setEquals(before.roadStepIndices, after.roadStepIndices)) {
    return false;
  }
  for (var index = 0; index < before.steps.length; index++) {
    if (before.steps[index].coordinate != after.steps[index].coordinate ||
        before.stepTurns[index] != after.stepTurns[index]) {
      return false;
    }
  }
  return true;
}
