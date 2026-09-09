part of 'city_planning_layer.dart';

final _planningFill = ui.Paint()
  ..color = AonwColorTokens.surface.withAlpha(180);
final _planningBorder = ui.Paint()
  ..color = AonwColorTokens.brandLight.withAlpha(245)
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = 1.5;
final _planningGlyphStroke = ui.Paint()
  ..color = AonwColorTokens.brandLight.withAlpha(245)
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = 1.8
  ..strokeCap = ui.StrokeCap.round
  ..strokeJoin = ui.StrokeJoin.round;
final _planningRoof = ui.Path()
  ..moveTo(-5, -0.8)
  ..lineTo(0, -5.4)
  ..lineTo(5, -0.8);
final _planningBase = ui.RRect.fromRectAndRadius(
  const ui.Rect.fromLTWH(-3.9, -0.7, 7.8, 5.5),
  const ui.Radius.circular(1.2),
);
final _planningArrows = _growthArrows();

void _drawPlanningMarker(
  ui.Canvas canvas,
  ui.Offset center, {
  required bool site,
}) {
  canvas
    ..drawCircle(center, 6.5, _planningFill)
    ..drawCircle(center, 6.5, _planningBorder)
    ..save()
    ..translate(center.dx, center.dy)
    ..scale(0.72);
  if (site) {
    canvas
      ..drawPath(_planningRoof, _planningGlyphStroke)
      ..drawRRect(_planningBase, _planningGlyphStroke)
      ..drawLine(
        const ui.Offset(-5, 5.2),
        const ui.Offset(5, 5.2),
        _planningGlyphStroke,
      );
  } else {
    canvas
      ..drawCircle(ui.Offset.zero, 2.2, _planningGlyphStroke)
      ..drawPath(_planningArrows, _planningGlyphStroke);
  }
  canvas.restore();
}

ui.Path _growthArrows() {
  final path = ui.Path();
  for (final x in [-1.0, 1.0]) {
    for (final y in [-1.0, 1.0]) {
      final tip = ui.Offset(x * 5.3, y * 5.3);
      final unit = ui.Offset(x / math.sqrt2, y / math.sqrt2);
      final perpendicular = ui.Offset(-unit.dy, unit.dx);
      final first = tip - unit * 2.4 + perpendicular * 1.8;
      final second = tip - unit * 2.4 - perpendicular * 1.8;
      path
        ..moveTo(x * 1.7, y * 1.7)
        ..lineTo(tip.dx, tip.dy)
        ..moveTo(first.dx, first.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(second.dx, second.dy);
    }
  }
  return path;
}
