import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/movement_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import '../../features/workers/read_model/worker_view.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

typedef _MapRouteSegment = ({ui.Path path, bool reachable, bool followsRoad});

final class MapRouteLayerComponent extends Component with HasVisibility {
  MapRouteLayerComponent() : super(priority: 40) {
    isVisible = false;
  }

  static const _dashLength = 12.0;
  static const _gapLength = 7.0;
  static const _dashPattern = _dashLength + _gapLength;
  static final _currentGlowPaint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 7.6
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.2);
  static final _currentLinePaint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _futureLinePaint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _targetGlowPaint = ui.Paint()
    ..color = MapPalette.routeTargetGlow
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 6.4
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.4);
  static final _targetLinePaint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _boundaryHaloPaint = ui.Paint()
    ..color = MapPalette.routeBoundaryHalo
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.4);
  static final _boundaryDotPaint = ui.Paint()
    ..color = MapPalette.routeBoundaryDot;
  static final _boundaryBorderPaint = ui.Paint()
    ..color = MapPalette.routeBoundaryBorder
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;

  RoutePlanView? _route;
  String? _infrastructureSignature;
  List<_MapRouteSegment> _segments = const [];
  List<ui.Offset> _boundaries = const [];
  ui.Path? _targetPath;
  ui.Offset? _destination;
  bool _destinationReachable = false;
  var _pathBuildCount = 0;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;

  @visibleForTesting
  int get debugSegmentCount => _segments.length;

  @visibleForTesting
  int get debugCurrentTurnSegmentCount =>
      _segments.where((segment) => segment.reachable).length;

  @visibleForTesting
  int get debugFutureTurnSegmentCount =>
      _segments.where((segment) => !segment.reachable).length;

  @visibleForTesting
  int get debugBoundaryCount => _boundaries.length;

  @visibleForTesting
  bool debugSegmentFollowsRoad(int index) => _segments[index].followsRoad;

  @visibleForTesting
  ui.Rect debugSegmentBounds(int index) => _segments[index].path.getBounds();

  void applyRoute(
    MapStaticRenderCache cache,
    RoutePlanView? route,
    PlayerMapView player,
  ) {
    final signature = _roadSignature(player);
    if (identical(_route, route) && _infrastructureSignature == signature) {
      return;
    }
    _route = route;
    _infrastructureSignature = signature;
    if (route == null || route.steps.length < 2) {
      _clearGeometry();
      return;
    }
    final points = [
      for (final step in route.steps)
        mapProjectedTopFaceCenter(cache, step.coordinate),
    ];
    final roadNodes = _roadNodes(cache, player);
    final segments = <_MapRouteSegment>[];
    for (var index = 1; index < points.length; index += 1) {
      final fromCoordinate = route.steps[index - 1].coordinate;
      final toCoordinate = route.steps[index].coordinate;
      final followsRoad =
          roadNodes.contains(fromCoordinate) &&
          roadNodes.contains(toCoordinate);
      segments.add((
        path: _routeSegmentPath(points, index, followsRoad: followsRoad),
        reachable:
            route.steps[index].cumulativeCostUnits <=
            route.availableMovementUnits,
        followsRoad: followsRoad,
      ));
    }
    _segments = List.unmodifiable(segments);
    _boundaries = List.unmodifiable(_routeBoundaries(points, segments));
    _targetPath = mapProjectedTopFacePath(
      cache,
      route.destination,
      scale: 0.86,
    );
    _destination = points.last;
    _destinationReachable = segments.last.reachable;
    _pathBuildCount += 1;
    isVisible = true;
  }

  void clearLayer() {
    _route = null;
    _infrastructureSignature = null;
    _clearGeometry();
  }

  void _clearGeometry() {
    _segments = const [];
    _boundaries = const [];
    _targetPath = null;
    _destination = null;
    _destinationReachable = false;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final target = _targetPath;
    if (target != null) {
      _drawDashedPath(canvas, target, _targetGlowPaint, seed: _segments.length);
      _drawDashedPath(canvas, target, _targetLinePaint, seed: _segments.length);
    }
    for (var index = 0; index < _segments.length; index += 1) {
      final segment = _segments[index];
      if (segment.reachable) {
        _drawDashedPath(
          canvas,
          segment.path,
          _currentGlowPaint,
          seed: index + 1,
        );
        _drawDashedPath(
          canvas,
          segment.path,
          _currentLinePaint,
          seed: index + 1,
        );
      } else {
        _drawDashedPath(
          canvas,
          segment.path,
          _futureLinePaint,
          seed: index + 1,
        );
      }
    }
    for (final boundary in _boundaries) {
      _paintBoundary(canvas, boundary, emphasized: true);
    }
    final destination = _destination;
    if (destination != null) {
      _paintBoundary(canvas, destination, emphasized: _destinationReachable);
    }
  }
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

void _drawDashedPath(
  ui.Canvas canvas,
  ui.Path path,
  ui.Paint paint, {
  required int seed,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = -MapRouteLayerComponent._dashPattern;
    var dashIndex = 0;
    while (distance < metric.length) {
      final dash = _dashLength(seed, dashIndex);
      final start = math.max(0.0, distance);
      final end = math.min(metric.length, distance + dash);
      if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
      distance += dash + _gapLength(seed, dashIndex);
      dashIndex += 1;
    }
  }
}

double _dashLength(int seed, int index) {
  const adjustments = [1.0, -2.2, 2.5, -0.8];
  return MapRouteLayerComponent._dashLength +
      adjustments[(seed + index) % adjustments.length];
}

double _gapLength(int seed, int index) {
  const adjustments = [0.0, 1.8, -1.2, 0.9];
  return MapRouteLayerComponent._gapLength +
      adjustments[(seed * 3 + index) % adjustments.length];
}

void _paintBoundary(
  ui.Canvas canvas,
  ui.Offset center, {
  required bool emphasized,
}) {
  final haloRadius = emphasized ? 7.4 : 5.2;
  final radius = emphasized ? 4.4 : 2.8;
  canvas
    ..drawCircle(center, haloRadius, MapRouteLayerComponent._boundaryHaloPaint)
    ..drawCircle(center, radius, MapRouteLayerComponent._boundaryDotPaint);
  if (emphasized) {
    canvas.drawCircle(
      center,
      radius,
      MapRouteLayerComponent._boundaryBorderPaint,
    );
  }
}

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
