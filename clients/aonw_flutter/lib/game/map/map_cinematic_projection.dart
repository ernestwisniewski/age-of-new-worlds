import 'dart:typed_data';

import 'dart:ui' show Offset, Rect;

import 'package:flutter/rendering.dart' show Matrix4, MatrixUtils;

import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';

/// Screen-space perspective with a fixed bottom edge and a receding top edge.
final class MapCinematicProjection {
  static const strength = 0.26;
  double _width = 0;
  double _height = 0;
  Rect _clipBounds = Rect.zero;
  Rect get clipBounds => _clipBounds;

  Matrix4 _forward = Matrix4.identity();
  Matrix4 _inverse = Matrix4.identity();

  Float64List get matrix => _forward.storage;

  void resize(double width, double height) {
    if (width <= 0 || height <= 0 || !width.isFinite || !height.isFinite) {
      return;
    }
    if (_width == width && _height == height) return;
    _width = width;
    _height = height;
    _clipBounds = Rect.fromLTRB(
      0,
      height * strength / (1 + strength),
      width,
      height,
    );
    final centerX = width / 2;
    _forward = Matrix4(
      1,
      0,
      0,
      0,
      -centerX * strength / height,
      1 - strength,
      0,
      -strength / height,
      0,
      0,
      1,
      0,
      centerX * strength,
      height * strength,
      0,
      1 + strength,
    );
    _inverse = Matrix4.inverted(_forward);
  }

  AonwPoint project(AonwPoint point) => _transform(_forward, point);

  AonwPoint unproject(AonwPoint point) => _transform(_inverse, point);

  AonwPoint _transform(Matrix4 matrix, AonwPoint point) {
    final result = MatrixUtils.transformPoint(matrix, Offset(point.x, point.y));
    return (x: result.dx, y: result.dy);
  }
}
