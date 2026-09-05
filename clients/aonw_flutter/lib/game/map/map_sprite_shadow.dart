import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Two map-owned textures retain diffuse shadows; contact stays pixel precise.
final class MapSpriteShadowCache {
  static const _density = 1;
  static const _bounds = ui.Rect.fromLTWH(-48, -24, 96, 72);
  final _images = <bool, ui.Image>{};
  final _paint = ui.Paint()..filterQuality = ui.FilterQuality.low;

  @visibleForTesting
  int get debugImageCount => _images.length;

  void paintUnit(
    ui.Canvas canvas, {
    required ui.Offset center,
    required bool compact,
  }) {
    final image = _images.putIfAbsent(compact, () => _build(compact));
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      _bounds.shift(center),
      _paint,
    );
    MapSpriteShadow._paintContact(
      canvas,
      MapSpriteShadow._rect(center, compact),
    );
  }

  void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }

  ui.Image _build(bool compact) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..scale(_density.toDouble())
      ..translate(-_bounds.left, -_bounds.top);
    MapSpriteShadow._paintDiffuse(
      canvas,
      MapSpriteShadow._rect(ui.Offset.zero, compact),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      (_bounds.width * _density).toInt(),
      (_bounds.height * _density).toInt(),
    );
    picture.dispose();
    return image;
  }
}

/// The three shared shadow passes used by unit sprites and fallbacks.
abstract final class MapSpriteShadow {
  static final _castPaint = _paint(alpha: 34, blur: 7.4);
  static final _ambientPaint = _paint(alpha: 54, blur: 4.6);
  static final _contactPaint = _paint(alpha: 94, blur: 1.68);

  static void paintUnit(
    ui.Canvas canvas, {
    required ui.Offset center,
    required bool compact,
  }) {
    final rect = _rect(center, compact);
    _paintDiffuse(canvas, rect);
    _paintContact(canvas, rect);
  }

  static ui.Rect _rect(ui.Offset center, bool compact) => ui.Rect.fromCenter(
    center: center.translate(0, compact ? 7 : 9),
    width: compact ? 18 : 24,
    height: compact ? 6 : 8,
  );
  static void _paintDiffuse(ui.Canvas canvas, ui.Rect rect) {
    canvas
      ..drawOval(
        ui.Rect.fromCenter(
          center: rect.center.translate(rect.width * 0.16, rect.height * 0.22),
          width: rect.width * 1.42,
          height: rect.height * 1.28,
        ),
        _castPaint,
      )
      ..drawOval(rect.inflate(rect.height * 0.16), _ambientPaint);
  }

  static void _paintContact(ui.Canvas canvas, ui.Rect rect) {
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: rect.center.translate(0, rect.height * 0.14),
        width: rect.width * 0.62,
        height: rect.height * 0.45,
      ),
      _contactPaint,
    );
  }

  static ui.Paint _paint({required int alpha, required double blur}) =>
      ui.Paint()
        ..color = const ui.Color(0xff000000).withAlpha(alpha)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
}
