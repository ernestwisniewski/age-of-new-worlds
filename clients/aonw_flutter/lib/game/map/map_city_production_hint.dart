import 'dart:ui' as ui;

import 'package:flutter/animation.dart';

import '../../design_system/aonw_tokens.dart';
import 'map_canvas_clip.dart';

/// One reusable particle per visible producing city.
final class MapCityProductionHint {
  MapCityProductionHint(this.position, this.ownerColorValue, double now)
    : color = ui.Color.lerp(
        ui.Color(ownerColorValue),
        AonwColorTokens.brand,
        0.7,
      )!,
      nextEmission = now + period;

  static const period = 2.0;
  static const lifespan = 1.1;
  final ui.Offset position;
  final int ownerColorValue;
  final ui.Color color;
  double nextEmission;
  double? _startedAt;

  ui.Rect get bounds => ui.Rect.fromLTRB(
    position.dx - 7,
    position.dy - 51,
    position.dx + 7,
    position.dy - 23,
  );

  void advance(double now) {
    if (now < nextEmission) return;
    final periods = ((now - nextEmission) / period).floor();
    _startedAt = nextEmission + periods * period;
    nextEmission = _startedAt! + period;
  }

  bool activeAt(double now) =>
      _startedAt != null && now - _startedAt! < lifespan;

  bool render(ui.Canvas canvas, double now, ui.Paint paint) {
    if (!activeAt(now) || !mapCanvasClipBounds(canvas).overlaps(bounds)) {
      return false;
    }
    final progress = ((now - _startedAt!) / lifespan).clamp(0.0, 1.0);
    final rise = -14 * Curves.easeOutCubic.transform(progress);
    paint.color = color.withAlpha(((1 - progress) * 220).round());
    canvas.drawCircle(
      position.translate(0, -30 + rise),
      1.7 + progress * 1.4,
      paint,
    );
    return true;
  }
}
