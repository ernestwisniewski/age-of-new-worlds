import 'dart:math' as math;
import 'dart:ui' as ui;

import 'sprite_frame_repository.dart';

/// Authored alignment and crop in the untrimmed frame's coordinate system.
final class SpriteFrameAdjustment {
  const SpriteFrameAdjustment({
    this.offset = ui.Offset.zero,
    this.crop = (left: 0, top: 0, right: 0, bottom: 0),
    this.scale = const ui.Size(1, 1),
  });

  factory SpriteFrameAdjustment.fromJson(Map<String, dynamic> json) =>
      SpriteFrameAdjustment(
        offset: ui.Offset(_number(json, 'offsetX'), _number(json, 'offsetY')),
        crop: (
          left: _number(json, 'cropLeft'),
          top: _number(json, 'cropTop'),
          right: _number(json, 'cropRight'),
          bottom: _number(json, 'cropBottom'),
        ),
        scale: ui.Size(
          _number(json, 'scaleX', fallback: 1).clamp(0.25, 3),
          _number(json, 'scaleY', fallback: 1).clamp(0.25, 3),
        ),
      );

  final ui.Offset offset;
  final ({double left, double top, double right, double bottom}) crop;
  final ui.Size scale;

  ui.Offset scaledOffset(ui.Size baseSize, ui.Size targetSize) => ui.Offset(
    offset.dx * targetSize.width / math.max(1, baseSize.width),
    offset.dy * targetSize.height / math.max(1, baseSize.height),
  );

  SpriteFrameGeometry geometryFor(
    SpriteFrame frame, {
    required ui.Size baseSize,
    required ui.Rect destination,
  }) {
    final original = frame.originalSize;
    final left = math.min(crop.left, math.max(0.0, original.width - 1));
    final top = math.min(crop.top, math.max(0.0, original.height - 1));
    final right = math.min(
      crop.right,
      math.max(0.0, original.width - 1) - left,
    );
    final bottom = math.min(
      crop.bottom,
      math.max(0.0, original.height - 1) - top,
    );
    final logical = ui.Rect.fromLTRB(
      left,
      top,
      original.width - right,
      original.height - bottom,
    );
    final sx = destination.width / math.max(1, original.width);
    final sy = destination.height / math.max(1, original.height);
    final cropped = ui.Rect.fromLTRB(
      destination.left + left * sx,
      destination.top + top * sy,
      destination.right - right * sx,
      destination.bottom - bottom * sy,
    );
    final adjusted = scale == const ui.Size(1, 1)
        ? cropped
        : ui.Rect.fromCenter(
            center: cropped.center,
            width: math.max(1, cropped.width * scale.width),
            height: math.max(1, cropped.height * scale.height),
          );
    return frame.geometryFor(
      logicalSource: logical,
      destination: adjusted.shift(scaledOffset(baseSize, destination.size)),
    );
  }

  static double _number(
    Map<String, dynamic> json,
    String key, {
    double fallback = 0,
  }) {
    final value = json[key];
    return value is num && value.isFinite ? value.toDouble() : fallback;
  }
}
