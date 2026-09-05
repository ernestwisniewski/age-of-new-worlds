import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

/// A full-window viewport with explicit bounds for recording and layer culling.
final class MapClippedViewport extends MaxViewport {
  @override
  void clip(Canvas canvas) =>
      canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y), doAntiAlias: false);

  @override
  bool containsLocalPoint(Vector2 point) =>
      point.x >= 0 && point.y >= 0 && point.x < size.x && point.y < size.y;
}
