import 'dart:math' as math;

import 'package:flutter/painting.dart';

final class HexInspectionPlacement {
  const HexInspectionPlacement({
    required this.bounds,
    required this.arrowOnLeft,
    required this.arrowTop,
  });

  factory HexInspectionPlacement.inViewport(Size viewport, Offset anchor) {
    final margin = math.min(
      12.0,
      math.min(viewport.width, viewport.height) / 4,
    );
    final width = math.min(308.0, math.max(0.0, viewport.width - margin * 2));
    final rightFits = anchor.dx + 20 + width <= viewport.width - margin;
    final leftFits = anchor.dx - 20 - width >= margin;
    final onRight = rightFits || !leftFits;
    final x = (onRight ? anchor.dx + 20 : anchor.dx - 20 - width).clamp(
      margin,
      math.max(margin, viewport.width - width - margin),
    );
    final y = (anchor.dy - 72).clamp(
      margin,
      math.max(margin, viewport.height - 354),
    );
    final height = math.max(0.0, viewport.height - y - margin);
    return HexInspectionPlacement(
      bounds: Rect.fromLTWH(x.toDouble(), y.toDouble(), width, height),
      arrowOnLeft: onRight,
      arrowTop: (anchor.dy - y).clamp(0.0, math.min(238.0, height)),
    );
  }

  final Rect bounds;
  final bool arrowOnLeft;
  final double arrowTop;
}
