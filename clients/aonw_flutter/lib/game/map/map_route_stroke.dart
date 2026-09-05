part of 'map_route_layer.dart';

final class _MapRouteStroke {
  _MapRouteStroke(ui.Path path, {required this.seed})
    : bounds = path.getBounds(),
      metrics = path.computeMetrics().toList(growable: false);

  final int seed;
  final ui.Rect bounds;
  final List<ui.PathMetric> metrics;
  double? _phase;
  List<ui.Path> _dashes = const [];
  int buildCount = 0;
  double get length =>
      metrics.fold(0, (total, metric) => total + metric.length);

  List<ui.Path> dashes(double phase) {
    if (_phase == phase) return _dashes;
    _phase = phase;
    buildCount++;
    return _dashes = [
      for (final metric in metrics) ..._extractDashes(metric, phase),
    ];
  }

  Iterable<ui.Path> _extractDashes(ui.PathMetric metric, double phase) sync* {
    var distance = phase % 19 - 19;
    var index = 0;
    while (distance < metric.length) {
      final dash = _dashLength(seed, index);
      final start = math.max(0.0, distance);
      final end = math.min(metric.length, distance + dash);
      if (end > start) yield metric.extractPath(start, end);
      distance += dash + _gapLength(seed, index);
      index++;
    }
  }
}

double _dashLength(int seed, int index) {
  const adjustments = [1.0, -2.2, 2.5, -0.8];
  return 12 + adjustments[(seed + index) % adjustments.length];
}

double _gapLength(int seed, int index) {
  const adjustments = [0.0, 1.8, -1.2, 0.9];
  return 7 + adjustments[(seed * 3 + index) % adjustments.length];
}
