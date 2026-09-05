part of 'map_route_layer.dart';

extension _MapRouteGeometry on MapRouteLayerComponent {
  void _buildGeometry(
    MapStaticRenderCache cache,
    RoutePlanView route,
    PlayerMapView player,
  ) {
    final points = [
      for (final step in route.steps)
        mapProjectedTopFaceCenter(cache, step.coordinate),
    ];
    final roads = _roadNodes(cache, player);
    _segments = List.unmodifiable([
      for (var index = 1; index < points.length; index++)
        _buildSegment(points, route, roads, index),
    ]);
    _boundaries = List.unmodifiable(_routeBoundaries(points, _segments));
    _target = _MapRouteStroke(
      mapProjectedTopFacePath(cache, route.destination, scale: 0.86),
      seed: points.length,
    );
    _destination = points.last;
    _destinationReachable = _segments.last.reachable;
    _length = _segments.fold(
      0,
      (total, segment) => total + segment.stroke.length,
    );
    _bounds = _segments
        .fold(
          _target!.bounds,
          (bounds, segment) => bounds.expandToInclude(segment.stroke.bounds),
        )
        .inflate(64);
    _pathBuildCount++;
    isVisible = true;
  }
}

_MapRouteSegment _buildSegment(
  List<ui.Offset> points,
  RoutePlanView route,
  Set<MapHexCoordinate> roads,
  int index,
) {
  final followsRoad =
      roads.contains(route.steps[index - 1].coordinate) &&
      roads.contains(route.steps[index].coordinate);
  return (
    stroke: _MapRouteStroke(
      _routeSegmentPath(points, index, followsRoad: followsRoad),
      seed: index,
    ),
    reachable:
        route.steps[index].cumulativeCostUnits <= route.availableMovementUnits,
    followsRoad: followsRoad,
  );
}

bool _sameRoute(RoutePlanView? previous, RoutePlanView? next) {
  if (identical(previous, next)) return true;
  if (previous == null || next == null) return false;
  if (previous.unitId != next.unitId ||
      previous.destination != next.destination ||
      previous.availableMovementUnits != next.availableMovementUnits ||
      previous.steps.length != next.steps.length) {
    return false;
  }
  for (var index = 0; index < previous.steps.length; index++) {
    final before = previous.steps[index];
    final after = next.steps[index];
    if (before.coordinate != after.coordinate ||
        before.cumulativeCostUnits != after.cumulativeCostUnits) {
      return false;
    }
  }
  return true;
}

ui.Path _routeSegmentPath(
  List<ui.Offset> points,
  int index, {
  required bool followsRoad,
}) {
  final from = points[index - 1];
  final to = points[index];
  final path = ui.Path()..moveTo(from.dx, from.dy);
  final distance = (to - from).distance;
  if (distance <= 0.001 || followsRoad) {
    return path..lineTo(to.dx, to.dy);
  }
  final fromTangent = _routeTangent(points, index - 1);
  final toTangent = _routeTangent(points, index);
  final handle = distance * 0.34;
  return path..cubicTo(
    from.dx + fromTangent.dx * handle,
    from.dy + fromTangent.dy * handle,
    to.dx - toTangent.dx * handle,
    to.dy - toTangent.dy * handle,
    to.dx,
    to.dy,
  );
}

ui.Offset _routeTangent(List<ui.Offset> points, int index) {
  final previous = points[math.max(0, index - 1)];
  final next = points[math.min(points.length - 1, index + 1)];
  final delta = next - previous;
  if (delta.distance <= 0.001) return const ui.Offset(1, 0);
  final angle =
      math.atan2(delta.dy, delta.dx) +
      (_routePointNoise(points[index], index) - 0.5) * 0.42;
  return ui.Offset(math.cos(angle), math.sin(angle));
}

double _routePointNoise(ui.Offset point, int index) {
  var value =
      (point.dx * 10).round() * 73856093 ^
      (point.dy * 10).round() * 19349663 ^
      index * 83492791;
  value = (value ^ (value >> 16)) * 0x45d9f3b;
  value = (value ^ (value >> 16)) * 0x45d9f3b;
  value ^= value >> 16;
  return (value & 0x7fffffff) / 0x7fffffff;
}

List<ui.Offset> _routeBoundaries(
  List<ui.Offset> points,
  List<_MapRouteSegment> segments,
) => [
  for (var index = 0; index < segments.length - 1; index += 1)
    if (segments[index].reachable != segments[index + 1].reachable)
      points[index + 1],
];

Set<MapHexCoordinate> _roadNodes(
  MapStaticRenderCache cache,
  PlayerMapView player,
) {
  final roads = {
    for (final road in player.roads)
      if (road.condition == TransportConditionView.operational) road.coordinate,
  };
  final nodes = <MapHexCoordinate>{...roads};
  for (final city in player.cities) {
    if (cache.geometry.neighbors(city.center).any(roads.contains)) {
      nodes.add(city.center);
    }
  }
  return nodes;
}

String _roadSignature(PlayerMapView player) {
  final buffer = StringBuffer();
  for (final road in player.roads) {
    buffer
      ..write(road.coordinate.col)
      ..write(',')
      ..write(road.coordinate.row)
      ..write(':')
      ..write(road.condition.name)
      ..write(';');
  }
  buffer.write('|');
  for (final city in player.cities) {
    buffer
      ..write(city.center.col)
      ..write(',')
      ..write(city.center.row)
      ..write(';');
  }
  return buffer.toString();
}
