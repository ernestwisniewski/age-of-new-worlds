import 'dart:ui' as ui;

import '../../design_system/assets/sprite_frame_repository.dart';

abstract final class MapSpritePainter {
  static ui.Path flatTopHexPath(ui.Rect bounds) {
    final quarter = bounds.width / 4;
    return ui.Path()
      ..moveTo(bounds.right, bounds.center.dy)
      ..lineTo(bounds.right - quarter, bounds.bottom)
      ..lineTo(bounds.left + quarter, bounds.bottom)
      ..lineTo(bounds.left, bounds.center.dy)
      ..lineTo(bounds.left + quarter, bounds.top)
      ..lineTo(bounds.right - quarter, bounds.top)
      ..close();
  }

  static void paint(
    ui.Canvas canvas,
    SpriteFrame frame, {
    required ui.Rect destination,
    ui.Path? clip,
    ui.Paint? paint,
  }) {
    final geometry = frame.geometryFor(
      logicalSource: ui.Offset.zero & frame.originalSize,
      destination: destination,
    );
    if (geometry.source.isEmpty || geometry.destination.isEmpty) return;
    if (clip != null) {
      canvas
        ..save()
        ..clipPath(clip);
    }
    canvas.drawImageRect(
      frame.image,
      geometry.source,
      geometry.destination,
      paint ?? _paint,
    );
    if (clip != null) canvas.restore();
  }

  static final ui.Paint _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.medium;
}
