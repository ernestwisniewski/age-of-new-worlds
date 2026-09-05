import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show Matrix4, MatrixUtils;

/// Retains conservative layer culling when Canvas cannot invert perspective.
ui.Rect mapCanvasClipBounds(ui.Canvas canvas) {
  final local = canvas.getLocalClipBounds();
  if (local != ui.Rect.largest) return local;
  final destination = canvas.getDestinationClipBounds();
  if (destination == ui.Rect.largest) return local;
  final inverse = Matrix4.fromFloat64List(canvas.getTransform());
  if (inverse.invert() == 0) return local;
  // Match Canvas's outward pixel rounding before mapping into component space.
  final rounded = ui.Rect.fromLTRB(
    destination.left.floorToDouble(),
    destination.top.floorToDouble(),
    destination.right.ceilToDouble(),
    destination.bottom.ceilToDouble(),
  );
  final bounds = MatrixUtils.transformRect(inverse, rounded);
  return bounds.isFinite ? bounds : local;
}
