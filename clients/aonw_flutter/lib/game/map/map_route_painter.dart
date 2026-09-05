part of 'map_route_layer.dart';

abstract final class _MapRoutePaints {
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
  static final _ghostPaint = ui.Paint()
    ..color = const ui.Color.fromARGB(220, 255, 255, 255)
    ..filterQuality = ui.FilterQuality.medium;
  static final _ghostGlowPaint = ui.Paint()
    ..color = MapPalette.route.withAlpha(90)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
  static final _dotPaint = ui.Paint()..color = MapPalette.route;
  static final _destinationGlowPaint = ui.Paint()
    ..color = MapPalette.route.withAlpha(30)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
}

extension _MapRoutePainter on MapRouteLayerComponent {
  void _paintRoute(ui.Canvas canvas) {
    final clip = mapCanvasClipBounds(canvas);
    if (!_bounds.overlaps(clip)) return;
    final target = _target;
    if (target != null && target.bounds.inflate(20).overlaps(clip)) {
      _paintDashes(canvas, target.dashes(0), _MapRoutePaints._targetGlowPaint);
      _paintDashes(canvas, target.dashes(0), _MapRoutePaints._targetLinePaint);
    }
    for (var index = 0; index < _segments.length; index++) {
      final segment = _segments[index];
      if (!segment.stroke.bounds.inflate(20).overlaps(clip)) continue;
      final phase = (_flowPhase + (index + 1) * 3.5) % 19;
      final dashes = segment.stroke.dashes(phase);
      if (segment.reachable) {
        _paintDashes(canvas, dashes, _MapRoutePaints._currentGlowPaint);
      }
      _paintDashes(canvas, dashes, _MapRoutePaints._currentLinePaint);
    }
    for (final boundary in _boundaries) {
      _paintBoundary(canvas, boundary);
    }
    _paintGhost(canvas, clip);
    _paintDestination(canvas);
  }

  void _paintGhost(ui.Canvas canvas, ui.Rect clip) {
    final center = _routeSample()?.position;
    if (center == null) return;
    final ghost = _ghost;
    final kind = _ghostKind;
    if (ghost?.frame == null || kind == null) {
      canvas
        ..drawCircle(center, 9, _MapRoutePaints._ghostGlowPaint)
        ..drawCircle(center, 5, _MapRoutePaints._dotPaint);
      return;
    }
    final metrics = MapSpriteCatalog.unitMetrics(kind, onCity: true);
    final size = ui.Size(metrics.width * 0.78, metrics.height * 0.78);
    final destination = ui.Rect.fromCenter(
      center: center - ui.Offset(0, size.height * 0.30),
      width: size.width,
      height: size.height,
    );
    if (destination.overlaps(clip)) {
      ghost!.paint(canvas, destination, paint: _MapRoutePaints._ghostPaint);
    }
  }

  void _paintDestination(ui.Canvas canvas) {
    final destination = _destination;
    if (destination == null) return;
    if (_destinationReachable) {
      _paintBoundary(canvas, destination);
    } else {
      canvas
        ..drawCircle(destination, 7, _MapRoutePaints._destinationGlowPaint)
        ..drawCircle(destination, 3.2, _MapRoutePaints._dotPaint);
    }
  }
}

void _paintDashes(ui.Canvas canvas, List<ui.Path> dashes, ui.Paint paint) {
  for (final dash in dashes) {
    canvas.drawPath(dash, paint);
  }
}

void _paintBoundary(ui.Canvas canvas, ui.Offset center) {
  canvas
    ..drawCircle(center, 7.4, _MapRoutePaints._boundaryHaloPaint)
    ..drawCircle(center, 4.4, _MapRoutePaints._boundaryDotPaint)
    ..drawCircle(center, 4.4, _MapRoutePaints._boundaryBorderPaint);
}
