import 'dart:ui' as ui;

import '../../features/map/read_model/map_view.dart';
import 'static_map_layers.dart';

ui.Path buildMapCityTerritoryBoundaryPath(
  MapStaticRenderCache cache,
  Iterable<MapHexCoordinate> coordinates,
) {
  final territory = coordinates.toSet();
  final segments = <_BoundarySegment>[];
  for (final coordinate in territory) {
    final neighbors = cache.geometry.neighbors(coordinate);
    for (var side = 0; side < neighbors.length; side += 1) {
      if (territory.contains(neighbors[side])) continue;
      final indexes = _cornerIndexes[side];
      segments.add(
        _BoundarySegment(
          _topFaceCorner(cache, coordinate, indexes.$1),
          _topFaceCorner(cache, coordinate, indexes.$2),
        ),
      );
    }
  }
  if (segments.isEmpty) return ui.Path();

  final byStart = <String, List<_BoundarySegment>>{};
  for (final segment in segments) {
    (byStart[_pointKey(segment.start)] ??= []).add(segment);
  }
  final path = ui.Path();
  final remaining = segments.toSet();
  while (remaining.isNotEmpty) {
    final first = remaining.first;
    remaining.remove(first);
    final points = <ui.Offset>[first.start, first.end];
    var current = first.end;
    while (!_samePoint(current, first.start)) {
      final next = _takeNextSegment(byStart, remaining, current);
      if (next == null) break;
      points.add(next.end);
      current = next.end;
    }
    final closed = points.length > 2 && _samePoint(points.first, points.last);
    path.addPath(
      buildMapCityTerritoryBoundaryShape(points, closed: closed),
      ui.Offset.zero,
    );
  }
  return path;
}

ui.Path buildMapCityTerritoryCenterPath(
  MapStaticRenderCache cache,
  MapHexCoordinate coordinate, {
  double scale = 0.56,
}) {
  final center = cache.projection.hexTopFaceCenter(coordinate);
  final centerOffset = ui.Offset(center.x, center.y);
  final corners = [
    for (var corner = 0; corner < 6; corner += 1)
      switch (_topFaceCorner(cache, coordinate, corner)) {
        final point => centerOffset + (point - centerOffset) * scale,
      },
  ];
  final path = ui.Path()..moveTo(corners.first.dx, corners.first.dy);
  for (final corner in corners.skip(1)) {
    path.lineTo(corner.dx, corner.dy);
  }
  return path..close();
}

ui.Path buildMapCityTerritoryBoundaryShape(
  List<ui.Offset> points, {
  required bool closed,
}) {
  final path = ui.Path();
  if (points.isEmpty) return path;
  final baseLoopPoints = closed ? points.sublist(0, points.length - 1) : points;
  final loopPoints = closed
      ? _organicBoundaryPoints(baseLoopPoints)
      : baseLoopPoints;
  if (!closed || loopPoints.length < 3) {
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }
  return _curvedLoopPath(_smoothBoundaryPoints(loopPoints));
}

String mapCityTerritoryHexesSignature(Iterable<MapHexCoordinate> coordinates) {
  final sorted = coordinates.toSet().toList()
    ..sort((left, right) {
      final byRow = left.row.compareTo(right.row);
      return byRow != 0 ? byRow : left.col.compareTo(right.col);
    });
  return [for (final value in sorted) '${value.col},${value.row};'].join();
}

const _cornerIndexes = <(int, int)>[
  (5, 0),
  (0, 1),
  (1, 2),
  (2, 3),
  (3, 4),
  (4, 5),
];

ui.Offset _topFaceCorner(
  MapStaticRenderCache cache,
  MapHexCoordinate coordinate,
  int corner,
) {
  final point = cache.projection.hexCorner(coordinate, corner);
  final center = cache.projection.hexCenter(coordinate);
  final topFace = cache.projection.hexTopFaceCenter(coordinate);
  return ui.Offset(point.x, point.y + topFace.y - center.y);
}

_BoundarySegment? _takeNextSegment(
  Map<String, List<_BoundarySegment>> byStart,
  Set<_BoundarySegment> remaining,
  ui.Offset point,
) {
  final candidates = byStart[_pointKey(point)];
  if (candidates == null) return null;
  while (candidates.isNotEmpty) {
    final segment = candidates.removeAt(0);
    if (remaining.remove(segment)) return segment;
  }
  return null;
}

ui.Path _curvedLoopPath(List<ui.Offset> points) {
  final path = ui.Path();
  if (points.length < 3) return path;
  final start = _midpoint(points.last, points.first);
  path.moveTo(start.dx, start.dy);
  for (var index = 0; index < points.length; index += 1) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    final end = _midpoint(current, next);
    path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
  }
  return path..close();
}

List<ui.Offset> _smoothBoundaryPoints(List<ui.Offset> points) {
  var smoothed = points;
  for (var pass = 0; pass < _boundarySmoothingPasses; pass += 1) {
    final nextPoints = <ui.Offset>[];
    for (var index = 0; index < smoothed.length; index += 1) {
      final current = smoothed[index];
      final next = smoothed[(index + 1) % smoothed.length];
      final delta = next - current;
      nextPoints
        ..add(current + delta * _boundaryCornerCut)
        ..add(current + delta * (1 - _boundaryCornerCut));
    }
    smoothed = nextPoints;
  }
  return smoothed;
}

List<ui.Offset> _organicBoundaryPoints(List<ui.Offset> points) {
  if (points.length < 2) return points;
  final organic = <ui.Offset>[];
  for (var index = 0; index < points.length; index += 1) {
    final start = points[index];
    final end = points[(index + 1) % points.length];
    organic.add(start);
    final delta = end - start;
    final length = delta.distance;
    if (length <= _organicMinSegmentLength) continue;
    final canonical = _canonicalBoundaryEdge(start, end);
    final canonicalDelta = canonical.end - canonical.start;
    final canonicalLength = canonicalDelta.distance;
    if (canonicalLength == 0) continue;
    final normal = ui.Offset(
      -canonicalDelta.dy / canonicalLength,
      canonicalDelta.dx / canonicalLength,
    );
    final steps = (length / _organicPointSpacing).floor().clamp(
      _organicMinSegmentSteps,
      _organicMaxSegmentSteps,
    );
    for (var step = 1; step <= steps; step += 1) {
      final progress = step / (steps + 1);
      final base = start + delta * progress;
      final canonicalProgress = canonical.reversed ? 1 - progress : progress;
      organic.add(
        base +
            normal *
                _fractalBoundaryJitter(
                  start: canonical.start,
                  end: canonical.end,
                  progress: canonicalProgress,
                ),
      );
    }
  }
  return organic;
}

({ui.Offset start, ui.Offset end, bool reversed}) _canonicalBoundaryEdge(
  ui.Offset start,
  ui.Offset end,
) => _isPointBefore(start, end)
    ? (start: start, end: end, reversed: false)
    : (start: end, end: start, reversed: true);

double _fractalBoundaryJitter({
  required ui.Offset start,
  required ui.Offset end,
  required double progress,
}) {
  var jitter = 0.0;
  var amplitude = _organicBoundaryJitter;
  for (var octave = 0; octave < _organicBoundaryOctaves; octave += 1) {
    final frequency = 1 << octave;
    final scaled = progress * frequency;
    final sample = scaled.floor();
    final local = scaled - sample;
    final eased = local * local * (3 - 2 * local);
    final a = _boundaryNoise(start, end, octave, sample);
    final b = _boundaryNoise(start, end, octave, sample + 1);
    jitter += ui.lerpDouble(a, b, eased)! * amplitude;
    amplitude *= _organicBoundaryAmplitudeFalloff;
  }
  return jitter;
}

double _boundaryNoise(ui.Offset start, ui.Offset end, int octave, int sample) {
  var hash = 17;
  hash = _hashBoundaryValue(hash, start.dx);
  hash = _hashBoundaryValue(hash, start.dy);
  hash = _hashBoundaryValue(hash, end.dx);
  hash = _hashBoundaryValue(hash, end.dy);
  hash = 37 * hash + octave * 65537;
  hash = 37 * hash + sample * 104729;
  return (hash.abs() % 2001) / 1000.0 - 1.0;
}

int _hashBoundaryValue(int hash, double value) =>
    37 * hash + (value * 1000).round();

bool _samePoint(ui.Offset left, ui.Offset right) =>
    _pointKey(left) == _pointKey(right);

String _pointKey(ui.Offset point) =>
    '${(point.dx * 1000).round()}:${(point.dy * 1000).round()}';

bool _isPointBefore(ui.Offset left, ui.Offset right) {
  final leftX = (left.dx * 1000).round();
  final rightX = (right.dx * 1000).round();
  if (leftX != rightX) return leftX < rightX;
  return (left.dy * 1000).round() <= (right.dy * 1000).round();
}

ui.Offset _midpoint(ui.Offset left, ui.Offset right) =>
    ui.Offset((left.dx + right.dx) / 2, (left.dy + right.dy) / 2);

const _organicPointSpacing = 9.0;
const _organicMinSegmentSteps = 3;
const _organicMaxSegmentSteps = 7;
const _organicBoundaryOctaves = 4;
const _organicBoundaryJitter = 4.8;
const _organicBoundaryAmplitudeFalloff = 0.52;
const _organicMinSegmentLength = 18.0;
const _boundarySmoothingPasses = 1;
const _boundaryCornerCut = 0.16;

final class _BoundarySegment {
  const _BoundarySegment(this.start, this.end);

  final ui.Offset start;
  final ui.Offset end;
}
